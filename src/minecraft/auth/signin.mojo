"""The complete sign-in: Microsoft token in, Minecraft credentials out.

Runs the same requests in the same order as `interop/auth/main.go` does
through gophertunnel, go-xsapi and go-playfab:

1. XASD device token, signed with a fresh P-256 proof key;
2. Microsoft token refresh, when the stored access token has expired;
3. NSAL default title data, for SISU's signature policy;
4. SISU authorization (title, user and `http://xboxlive.com` tokens);
5. Minecraft services discovery;
6. NSAL current title data, to resolve the PlayFab relying party;
7. XSTS token for that relying party, then PlayFab `LoginWithXbox`;
8. session start (`MCToken`) and multiplayer session start (token whose
   `cpk` is the client's P-384 key);
9. XSTS token for `multiplayer.minecraft.net`'s relying party, then the
   Xbox Live-signed login chain.

`SignIn` is generic over the `Transport`, so tests replay recorded
exchanges. Nothing here prints a token.
"""

from nethernet.crypto.p256 import p256_private_key_from_bytes
from nethernet.os.random import random_bytes
from nethernet.os.time import unix_time_s
from nethernet.wire import hex_encode

from ..protocol.info import CURRENT_VERSION
from .json import go_quote
from .live import OAuthToken, parse_refresh_response, refresh_request
from .minecraft import (
    MINECRAFT_AUTH_URL,
    minecraft_chain_request,
    parse_minecraft_chain_response,
)
from .nsal import (
    EndpointMatch,
    TitleData,
    default_title_request,
    parse_title_response,
    title_request,
)
from .playfab import (
    login_with_xbox_request,
    login_with_xbox_url,
    parse_login_response,
)
from .service import (
    APPLICATION_TYPE_MINECRAFT_PE,
    AuthorizationEnvironment,
    discovery_request,
    multiplayer_token_request,
    parse_discovery_response,
    parse_multiplayer_token_response,
    parse_session_start_response,
    session_start_request,
)
from .timestamp import NANOS_PER_SECOND, ServerClock
from .transport import Request, Response, Transport
from .xbox import (
    SISU_AUTHORIZE_URL,
    XBL_RELYING_PARTY,
    SisuAuthorization,
    XalConfig,
    XASToken,
    android_config,
    device_token_request,
    parse_sisu_response,
    parse_token_response,
    sisu_authorize_request,
    uuid_v4,
    xsts_request,
)


@fieldwise_init
struct SignInResult(Copyable, Movable):
    """What the flow produces. Every field but the names is a secret."""

    var chain: String
    """The login chain JSON, `{"chain":[…]}`."""
    var multiplayer_token: String
    """The multiplayer token JWT."""
    var domain: String
    """The token issuer as `interop/auth` writes it."""
    var gamertag: String
    """The gamertag claimed by the `http://xboxlive.com` token."""
    var xuid: String
    """The XUID claimed by the `http://xboxlive.com` token."""


struct SignIn[T: Transport](Movable):
    """Signs in to Xbox Live, PlayFab and Minecraft services."""

    var transport: Self.T
    """The transport."""
    var config: XalConfig
    """The title configuration, `android_config()` by default."""
    var verbose: Bool
    """Print each step (never a token) to stdout."""
    var fixed_now_ns: Int
    """For tests: the local clock reads this instead of the wall clock."""
    var fixed_random: List[UInt8]
    """For tests: random bytes handed out in order instead of getrandom."""
    var _clock: ServerClock
    var _proof_key: List[UInt8]
    var _device: XASToken
    var _sisu: Optional[SisuAuthorization]
    var _xsts: List[Tuple[String, XASToken]]
    var _titles: List[TitleData]
    var _default_title: Optional[TitleData]

    def __init__(out self, var transport: Self.T):
        """Creates a sign-in over a transport with the Android configuration."""
        self.transport = transport^
        self.config = android_config()
        self.verbose = False
        self.fixed_now_ns = 0
        self.fixed_random = List[UInt8]()
        self._clock = ServerClock()
        self._proof_key = List[UInt8]()
        self._device = XASToken()
        self._sisu = None
        self._xsts = List[Tuple[String, XASToken]]()
        self._titles = List[TitleData]()
        self._default_title = None

    def _local_now(self) -> Int:
        if self.fixed_now_ns != 0:
            return self.fixed_now_ns
        return unix_time_s() * NANOS_PER_SECOND

    def _server_now(self) -> Int:
        return self._clock.now(self._local_now())

    def _random(mut self, n: Int) raises -> List[UInt8]:
        if len(self.fixed_random) == 0:
            return random_bytes(n)
        if len(self.fixed_random) < n:
            raise Error("signin: fixed random bytes exhausted")
        var out = List[UInt8](Span(self.fixed_random)[0:n])
        self.fixed_random = List[UInt8](Span(self.fixed_random)[n:])
        return out^

    def _log(self, msg: String):
        if self.verbose:
            print("auth:", msg)

    def _send(mut self, request: Request) raises -> Response:
        self._log(String(request.method, " ", request.url))
        return self.transport.round_trip(request)

    def _send_xbox(mut self, request: Request) raises -> Response:
        """Sends a request whose `Date` header refines the server clock."""
        var response = self._send(request)
        self._clock.update(response.header("date"), self._local_now())
        return response^

    def set_proof_key(mut self, key: Span[UInt8, _]) raises:
        """Uses a given P-256 proof key instead of a fresh one (for tests)."""
        if len(key) != 32:
            raise Error("signin: proof key must be 32 bytes")
        self._proof_key = List[UInt8](key)

    def _ensure_proof_key(mut self) raises:
        if len(self._proof_key) == 0:
            var key = p256_private_key_from_bytes(Span(self._random(48)))
            self._proof_key = List[UInt8](Span(key))

    def device_token(mut self) raises -> XASToken:
        """Returns the XASD device token, requesting it when needed."""
        if self._device.valid(self._local_now()):
            return self._device.copy()
        self._ensure_proof_key()
        var uuid = uuid_v4(Span(self._random(16)))
        var req = device_token_request(
            self.config, Span(self._proof_key), uuid, self._server_now()
        )
        var resp = self._send_xbox(req)
        try:
            self._device = parse_token_response(req, resp, self._local_now())
        except e:
            raise Error(String("xal/xasd: authenticate: ", e))
        return self._device.copy()

    def _default_title_data(mut self) raises -> TitleData:
        if case .Some(t) = self._default_title:
            return t.copy()
        var req = default_title_request()
        var resp = self._send(req)
        var title = parse_title_response(req, resp)
        self._default_title = title.copy()
        return title^

    def authorize(mut self, mut msa: OAuthToken) raises -> SisuAuthorization:
        """Runs SISU authorization, refreshing the Microsoft token if needed."""
        if case .Some(s) = self._sisu:
            var now = self._local_now()
            if (
                s.title_token.valid(now)
                and s.user_token.valid(now)
                and s.authorization_token.valid_xsts(now)
            ):
                return s.copy()
        var device = self.device_token()
        if not msa.valid(self._local_now()):
            if msa.refresh_token.byte_length() == 0:
                raise Error(
                    "xal/sisu: token expired and refresh token is not set"
                )
            var req = refresh_request(
                self.config.client_id,
                self.config.user_agent,
                msa.refresh_token,
            )
            var resp = self._send(req)
            var fresh = parse_refresh_response(resp, self._local_now())
            if fresh.refresh_token.byte_length() == 0:
                fresh.refresh_token = msa.refresh_token.copy()
            msa = fresh^
        var nsal = self._default_title_data()
        var policy = nsal.match(SISU_AUTHORIZE_URL)
        if not policy:
            raise Error("xal/sisu: NSAL title endpoint not found for SISU")
        var req = sisu_authorize_request(
            self.config,
            msa.access_token,
            device.token,
            Span(self._proof_key),
            policy.value().policy,
            self._server_now(),
        )
        var resp = self._send_xbox(req)
        var auth = parse_sisu_response(req, resp, self._local_now())
        self._sisu = auth.copy()
        return auth^

    def xsts_token(
        mut self, mut msa: OAuthToken, relying_party: String
    ) raises -> XASToken:
        """Returns an XSTS token for a relying party (`Session.XSTSToken`)."""
        var now = self._local_now()
        for entry in self._xsts:
            if entry[0] == relying_party and entry[1].valid_xsts(now):
                return entry[1].copy()
        var auth = self.authorize(msa)
        var token: XASToken
        if relying_party == XBL_RELYING_PARTY:
            token = auth.authorization_token.copy()
        else:
            var device = self.device_token()
            var req = xsts_request(
                self.config,
                Span(self._proof_key),
                relying_party,
                device.token,
                auth.title_token.token,
                auth.user_token.token,
                self._server_now(),
            )
            var resp = self._send_xbox(req)
            try:
                token = parse_token_response(req, resp, self._local_now())
            except e:
                raise Error(String("xal/xsts: authorize: ", e))
        if not token.valid_xsts(self._local_now()):
            raise Error("xal/sisu: invalid XSTS token data")
        self._xsts.append((relying_party, token.copy()))
        return token^

    def resolve(
        mut self, mut msa: OAuthToken, url: String
    ) raises -> EndpointMatch:
        """Resolves a URL's relying party and policy (`nsal.Resolver`).

        The current title's data is consulted first, then the default.
        """
        if len(self._titles) == 0:
            var xbl = self.xsts_token(msa, XBL_RELYING_PARTY)
            var req = title_request(
                "current",
                xbl.authorization(),
                Span(self._proof_key),
                self._server_now(),
            )
            var resp = self._send_xbox(req)
            self._titles.append(parse_title_response(req, resp))
        if case .Some(m) = self._titles[0].match(url):
            self._log(String("resolved ", url, " -> ", m.relying_party))
            return m.copy()
        var default = self._default_title_data()
        if case .Some(m) = default.match(url):
            self._log(String("resolved ", url, " -> ", m.relying_party))
            return m.copy()
        raise Error(String("no endpoint was found for ", url))

    def run(
        mut self, var msa: OAuthToken, private_key: Span[UInt8, _]
    ) raises -> SignInResult:
        """Runs the whole flow for a client key."""
        var xbl: XASToken
        try:
            xbl = self.xsts_token(msa, XBL_RELYING_PARTY)
        except e:
            raise Error(String("xbox live login: ", e))
        if xbl.xuid.byte_length() == 0:
            raise Error("xsapi: authorization token does not claim XUID")

        var env: AuthorizationEnvironment
        try:
            var req = discovery_request(
                APPLICATION_TYPE_MINECRAFT_PE, CURRENT_VERSION
            )
            env = parse_discovery_response(req, self._send(req))
        except e:
            raise Error(String("discover: ", e))

        var ticket: String
        try:
            var url = login_with_xbox_url(env.playfab_title_id)
            var rp = self.resolve(msa, url).relying_party
            var token = self.xsts_token(msa, rp)
            var req = login_with_xbox_request(
                env.playfab_title_id, token.authorization(), True
            )
            ticket = parse_login_response(req, self._send(req)).session_ticket
        except e:
            raise Error(String("playfab login: ", e))

        var multiplayer: String
        try:
            var device_id = uuid_v4(Span(self._random(16)))
            var req = session_start_request(env, ticket, device_id)
            var service = parse_session_start_response(
                req, self._send(req), self._local_now()
            )
            var mreq = multiplayer_token_request(env, service, private_key)
            multiplayer = parse_multiplayer_token_response(
                mreq, self._send(mreq)
            )
        except e:
            raise Error(String("multiplayer token: ", e))

        var chain: String
        try:
            var rp = self.resolve(msa, MINECRAFT_AUTH_URL).relying_party
            var token = self.xsts_token(msa, rp)
            var req = minecraft_chain_request(
                private_key, token.authorization()
            )
            chain = parse_minecraft_chain_response(req, self._send(req))
        except e:
            raise Error(String("minecraft chain: ", e))

        return SignInResult(
            chain^,
            multiplayer^,
            env.issuer_domain(),
            xbl.gamertag.copy(),
            xbl.xuid.copy(),
        )


def credentials_json(
    private_key: Span[UInt8, _],
    result: SignInResult,
    gamertag: String,
    xuid: String,
    expires_at: Int,
) -> String:
    """Formats the credentials file `interop/auth` writes."""
    return String(
        '{"private_key":',
        go_quote(hex_encode(private_key)),
        ',"chain":',
        go_quote(result.chain),
        ',"token":',
        go_quote(result.multiplayer_token),
        ',"domain":',
        go_quote(result.domain),
        ',"gamertag":',
        go_quote(gamertag),
        ',"xuid":',
        go_quote(xuid),
        ',"expires_at":',
        expires_at,
        "}",
    )
