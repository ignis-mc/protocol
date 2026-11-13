"""Xbox Live authentication: device token, SISU authorization and XSTS.

Port of gophertunnel `minecraft/auth/xbox.go` (`AndroidConfig`) and the
go-xsapi pieces it drives: `xal/xasd` (device token with a proof key),
`xal/sisu/session.go` (`authorize`: MSA token + device token → title, user
and `http://xboxlive.com` tokens), `xal/xsts` (tokens for other relying
parties) and `xal/internal/token.go`. Each step is a request builder and a
response parser; `signin.mojo` runs them in order.
"""

from nethernet.json import json_parse_string

from .json import (
    get_raw,
    go_quote,
    lookup,
    opt_string,
    parse_array,
    parse_object,
)
from .signature import SignaturePolicy, auth_policy, proof_key_jwk
from .timestamp import NANOS_PER_SECOND, parse_rfc3339
from .transport import Request, Response, status_error

comptime XBL_RELYING_PARTY = "http://xboxlive.com"
"""The relying party of the token SISU returns."""

comptime DEVICE_AUTH_URL = (
    "https://device.auth.xboxlive.com/device/authenticate"
)
"""XASD."""
comptime SISU_AUTHORIZE_URL = "https://sisu.xboxlive.com/authorize"
"""SISU authorization."""
comptime XSTS_AUTHORIZE_URL = "https://xsts.auth.xboxlive.com/xsts/authorize"
"""XSTS."""

comptime _EXPIRATION_DELTA_NS = 60 * NANOS_PER_SECOND
"""Tokens stop being reused this long before `NotAfter`."""


struct XalConfig(Copyable, Movable):
    """A title's SISU configuration (`auth.Config` / `sisu.Config`)."""

    var device_type: String
    """The XASD device type, e.g. `Android`."""
    var device_version: String
    """The OS version reported to XASD."""
    var user_agent: String
    """The XAL user agent."""
    var title_id: Int
    """The Xbox Live title ID."""
    var sandbox: String
    """The sandbox, `RETAIL`."""
    var client_id: String
    """The MSA OAuth2 client ID."""
    var redirect_uri: String
    """The OAuth2 redirect URI (unused by the refresh flow)."""

    def __init__(
        out self,
        var device_type: String,
        var device_version: String,
        var user_agent: String,
        title_id: Int,
        var sandbox: String,
        var client_id: String,
        var redirect_uri: String,
    ):
        """Creates a configuration.

        Args:
            device_type: The XASD device type.
            device_version: The OS version.
            user_agent: The XAL user agent.
            title_id: The title ID.
            sandbox: The sandbox.
            client_id: The OAuth2 client ID.
            redirect_uri: The OAuth2 redirect URI.
        """
        self.device_type = device_type^
        self.device_version = device_version^
        self.user_agent = user_agent^
        self.title_id = title_id
        self.sandbox = sandbox^
        self.client_id = client_id^
        self.redirect_uri = redirect_uri^


def android_config() -> XalConfig:
    """Returns Minecraft: Bedrock Edition for Android's configuration.

    Returns:
        The values of gophertunnel's `auth.AndroidConfig`.
    """
    return XalConfig(
        "Android",
        "13",
        "XAL Android 2025.04.20250326.000",
        1739947436,
        "RETAIL",
        "0000000048183522",
        "ms-xal-0000000048183522://auth",
    )


struct XASToken(Copyable, Defaultable, Movable):
    """A token from XASD, XAST, XASU or XSTS with the claims the flow uses.

    The token string is a secret; this type has no `write_to`.
    """

    var issue_instant_ns: Int
    """When the token was issued, Unix nanoseconds."""
    var not_after_ns: Int
    """When the token expires, Unix nanoseconds."""
    var token: String
    """The token itself."""
    var device_id: String
    """`xdi.did` (device tokens)."""
    var title_id: String
    """`xti.tid` (title tokens)."""
    var has_user_info: Bool
    """Whether `xui` had at least one entry."""
    var user_hash: String
    """`xui[0].uhs` (user and XSTS tokens)."""
    var gamertag: String
    """`xui[0].gtg` (`http://xboxlive.com` tokens)."""
    var xuid: String
    """`xui[0].xid` (`http://xboxlive.com` tokens)."""

    def __init__(out self):
        """Creates an empty (invalid) token."""
        self.issue_instant_ns = 0
        self.not_after_ns = 0
        self.token = String()
        self.device_id = String()
        self.title_id = String()
        self.has_user_info = False
        self.user_hash = String()
        self.gamertag = String()
        self.xuid = String()

    def valid(self, now_ns: Int) -> Bool:
        """Reports whether the token is usable (Go `Token.Valid`).

        Args:
            now_ns: The current Unix time in nanoseconds.

        Returns:
            True if there is a token that does not expire within a minute.
        """
        return (
            self.token.byte_length() > 0
            and now_ns < self.not_after_ns - _EXPIRATION_DELTA_NS
        )

    def valid_xsts(self, now_ns: Int) -> Bool:
        """Reports whether this is a usable XSTS token (`xsts.Token.Valid`).

        Args:
            now_ns: The current Unix time in nanoseconds.

        Returns:
            `valid(now_ns)` and at least one `xui` entry.
        """
        return self.valid(now_ns) and self.has_user_info

    def authorization(self) -> String:
        """Formats the token as an `Authorization` header value.

        Returns:
            `XBL3.0 x=<user hash>;<token>`.
        """
        return String("XBL3.0 x=", self.user_hash, ";", self.token)


def parse_xas_token(raw: StringSpan) raises -> XASToken:
    """Decodes a token object (`IssueInstant`, `NotAfter`, `Token`, claims).

    Args:
        raw: The token JSON object.

    Returns:
        The token.

    Raises:
        Error: If the JSON or a timestamp is malformed.
    """
    var obj = parse_object(raw.as_bytes())
    var t = XASToken()
    if case .Some(v) = lookup(obj, "IssueInstant"):
        t.issue_instant_ns = parse_rfc3339(json_parse_string(v))
    if case .Some(v) = lookup(obj, "NotAfter"):
        t.not_after_ns = parse_rfc3339(json_parse_string(v))
    t.token = opt_string(obj, "Token")
    if case .Some(claims_raw) = lookup(obj, "DisplayClaims"):
        var claims = parse_object(claims_raw.as_bytes())
        if case .Some(xdi) = lookup(claims, "xdi"):
            t.device_id = opt_string(parse_object(xdi.as_bytes()), "did")
        if case .Some(xti) = lookup(claims, "xti"):
            t.title_id = opt_string(parse_object(xti.as_bytes()), "tid")
        if case .Some(xui) = lookup(claims, "xui"):
            var users = parse_array(xui)
            if len(users) > 0:
                var u = parse_object(users[0].as_bytes())
                t.has_user_info = True
                t.user_hash = opt_string(u, "uhs")
                t.gamertag = opt_string(u, "gtg")
                t.xuid = opt_string(u, "xid")
    return t^


def uuid_v4(random: Span[UInt8, _]) raises -> String:
    """Formats 16 random bytes as a version 4 UUID (`uuid.NewString`).

    Args:
        random: 16 random bytes.

    Returns:
        The lowercase `8-4-4-4-12` form with version and variant bits set.

    Raises:
        Error: If `random` is not 16 bytes.
    """
    if len(random) != 16:
        raise Error("uuid: need 16 random bytes")
    var b = List[UInt8](random)
    b[6] = (b[6] & 0x0F) | 0x40
    b[8] = (b[8] & 0x3F) | 0x80
    var hex = "0123456789abcdef".as_bytes()
    var out = List[UInt8]()
    for i in range(16):
        if i == 4 or i == 6 or i == 8 or i == 10:
            out.append(0x2D)
        out.append(hex[Int(b[i] >> 4)])
        out.append(hex[Int(b[i] & 0xF)])
    return String(unsafe_from_utf8=Span(out))


def device_id(device_type: StringSpan, uuid: String) raises -> String:
    """Formats the XASD device `Id` for a device type (Go `deviceID`).

    Args:
        device_type: The XASD device type.
        uuid: A fresh UUID.

    Returns:
        `{uuid}` for Android and Nintendo, upper case for iOS, braces and
        upper case for Win32 and Xbox, plain for PlayStation.

    Raises:
        Error: For an unknown device type.
    """
    if device_type == "Android" or device_type == "Nintendo":
        return String("{", uuid, "}")
    if device_type == "iOS":
        return uuid.upper()
    if device_type == "PlayStation":
        return uuid
    if device_type == "Win32" or device_type == "Xbox":
        return String("{", uuid.upper(), "}")
    raise Error(String("unknown device type: ", device_type))


def _xal_headers(user_agent: String) -> List[Tuple[String, String]]:
    var headers = List[Tuple[String, String]]()
    headers.append(("User-Agent", user_agent))
    headers.append(("Content-Type", "application/json"))
    headers.append(("X-Xbl-Contract-Version", "1"))
    return headers^


def device_token_request(
    config: XalConfig,
    proof_key: Span[UInt8, _],
    uuid: String,
    timestamp_ns: Int,
) raises -> Request:
    """Builds the XASD device authentication request (`xasd.Authenticate`).

    Args:
        config: The title configuration.
        proof_key: The 32-byte P-256 proof key.
        uuid: A fresh UUID for the device `Id`.
        timestamp_ns: Server-adjusted Unix time in nanoseconds.

    Returns:
        The signed request.

    Raises:
        Error: For an unknown device type or an invalid key.
    """
    var id = device_id(config.device_type, uuid)
    var serial = String()
    if config.device_type == "Win32" or config.device_type == "Xbox":
        serial = id.copy()
    var body = String(
        '{"RelyingParty":"http://auth.xboxlive.com","TokenType":"JWT",',
        '"Properties":{"AuthMethod":"ProofOfPossession","Id":',
        go_quote(id),
    )
    if serial.byte_length() > 0:
        body += String(',"SerialNumber":', go_quote(serial))
    body += String(
        ',"DeviceType":',
        go_quote(config.device_type),
        ',"Version":',
        go_quote(config.device_version),
        ',"ProofKey":',
        proof_key_jwk(proof_key),
        "}}\n",
    )
    var req = Request(
        "POST",
        DEVICE_AUTH_URL,
        _xal_headers(config.user_agent),
        List[UInt8](body.as_bytes()),
    )
    auth_policy().sign(req, proof_key, timestamp_ns)
    return req^


def parse_token_response(
    request: Request, response: Response, now_ns: Int
) raises -> XASToken:
    """Decodes an XASD or XSTS response and checks the token.

    Args:
        request: The request that was sent.
        response: Its response.
        now_ns: The current Unix time in nanoseconds.

    Returns:
        The token.

    Raises:
        Error: On a non-200 status or an invalid token.
    """
    if response.status != 200:
        raise status_error(request, response)
    var token = parse_xas_token(String(from_utf8=Span(response.body)))
    if not token.valid(now_ns):
        raise Error(String("invalid token response from ", request.url))
    return token^


def sisu_authorize_request(
    config: XalConfig,
    access_token: String,
    device_token: String,
    proof_key: Span[UInt8, _],
    policy: SignaturePolicy,
    timestamp_ns: Int,
) raises -> Request:
    """Builds the SISU authorization request (`Session.authorize`).

    Args:
        config: The title configuration.
        access_token: The MSA access token (sent as `t=<token>`).
        device_token: The XASD token.
        proof_key: The 32-byte P-256 proof key.
        policy: The policy NSAL default data gives `sisu.xboxlive.com`.
        timestamp_ns: Server-adjusted Unix time in nanoseconds.

    Returns:
        The signed request. Like Go it has no `Content-Type` header.

    Raises:
        Error: If signing fails.
    """
    var body = String(
        '{"AccessToken":',
        go_quote(String("t=", access_token)),
        ',"AppId":',
        go_quote(config.client_id),
        ',"DeviceToken":',
        go_quote(device_token),
        ',"ProofKey":',
        proof_key_jwk(proof_key),
        ',"RelyingParty":',
        go_quote(XBL_RELYING_PARTY),
        ',"Sandbox":',
        go_quote(config.sandbox),
        ',"SiteName":"user.auth.xboxlive.com","UseModernGamertag":true}\n',
    )
    var headers = List[Tuple[String, String]]()
    headers.append(("User-Agent", config.user_agent))
    var req = Request(
        "POST", SISU_AUTHORIZE_URL, headers^, List[UInt8](body.as_bytes())
    )
    policy.sign(req, proof_key, timestamp_ns)
    return req^


@fieldwise_init
struct SisuAuthorization(Copyable, Movable):
    """The tokens a SISU authorization returns."""

    var title_token: XASToken
    """The XAST token."""
    var user_token: XASToken
    """The XASU token."""
    var authorization_token: XASToken
    """The XSTS token for `http://xboxlive.com`."""


def sisu_error_message(code: UInt32) -> String:
    """Describes a SISU `X-Err` code (`sisu.ErrorCode.String`), shortened.

    Args:
        code: The numeric code.

    Returns:
        A human-readable reason.
    """
    if code == 0x8015DC03:
        return "account suspended from Xbox Live"
    if code == 0x8015DC05:
        return "online features restricted by a guardian"
    if code == 0x8015DC0A:
        return "Microsoft Terms of Use not accepted"
    if code == 0x8015DC0B:
        return "Xbox Live is not available in this country"
    if code == 0x8015DC0C:
        return "age verification required"
    if code == 0x8015DC0D:
        return "screen time limit reached"
    if code == 0x8015DC0E:
        return "child account not in a family group"
    if code == 0x8015DC09:
        return "no Xbox Live account linked to this Microsoft account"
    if code == 0x8015DC13:
        return "gamertag change required"
    if code == 0x8015DC16:
        return "signed in on too many devices of this type"
    if code == 0x8015DC1E:
        return "already signed in to this title on another device"
    return "unknown error code"


def parse_sisu_response(
    request: Request, response: Response, now_ns: Int
) raises -> SisuAuthorization:
    """Decodes a SISU authorization response.

    Args:
        request: The request that was sent.
        response: Its response.
        now_ns: The current Unix time in nanoseconds.

    Returns:
        The title, user and authorization tokens.

    Raises:
        Error: On a non-200 status (with the `X-Err` reason) or when any of
            the three tokens is invalid.
    """
    if response.status != 200:
        var reason = String()
        if case .Some(code) = response.header("x-err"):
            try:
                reason = String(": ", sisu_error_message(UInt32(Int(code))))
            except:
                pass
        raise Error(String(status_error(request, response), reason))
    var obj = parse_object(Span(response.body))
    var auth = SisuAuthorization(
        parse_xas_token(get_raw(obj, "TitleToken")),
        parse_xas_token(get_raw(obj, "UserToken")),
        parse_xas_token(get_raw(obj, "AuthorizationToken")),
    )
    if not (
        auth.title_token.valid(now_ns)
        and auth.user_token.valid(now_ns)
        and auth.authorization_token.valid_xsts(now_ns)
    ):
        raise Error("xal/sisu: invalid authorization response")
    return auth^


def xsts_request(
    config: XalConfig,
    proof_key: Span[UInt8, _],
    relying_party: String,
    device_token: String,
    title_token: String,
    user_token: String,
    timestamp_ns: Int,
) raises -> Request:
    """Builds an XSTS authorization request (`xsts.Authorize`).

    Args:
        config: The title configuration.
        proof_key: The 32-byte P-256 proof key.
        relying_party: The relying party to authorize for.
        device_token: The XASD token.
        title_token: The XAST token.
        user_token: The XASU token.
        timestamp_ns: Server-adjusted Unix time in nanoseconds.

    Returns:
        The signed request.

    Raises:
        Error: If signing fails.
    """
    var body = String(
        '{"RelyingParty":',
        go_quote(relying_party),
        ',"TokenType":"JWT","Properties":{"SandboxId":',
        go_quote(config.sandbox),
        ',"DeviceToken":',
        go_quote(device_token),
        ',"TitleToken":',
        go_quote(title_token),
        ',"UserTokens":[',
        go_quote(user_token),
        "]}}\n",
    )
    var req = Request(
        "POST",
        XSTS_AUTHORIZE_URL,
        _xal_headers(config.user_agent),
        List[UInt8](body.as_bytes()),
    )
    auth_policy().sign(req, proof_key, timestamp_ns)
    return req^
