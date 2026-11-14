"""Minecraft services: discovery, session token and multiplayer token.

Port of gophertunnel `minecraft/service/discovery.go` (`Discover`,
`Discovery.Environment`) and `token.go` (`AuthorizationEnvironment.Token`,
`MultiplayerToken`, `VerifierContext`, the default device and user
configuration and the `pmid` claim check). The session token (`MCToken …`)
is obtained with the PlayFab session ticket; the multiplayer token is an
OpenID JWT whose `cpk` claim is the client's P-384 public key, which servers
verify against the issuer with `verifier`.
"""

from jose.json import array_values, decode_object, string_value
from jose.json import lookup as jose_lookup
from jose.json import opt_string as jose_opt_string
from jose.oidc import Config, IDTokenVerifier
from nethernet.crypto.base64 import base64url_decode
from nethernet.json import json_parse_string

from ..protocol.info import CURRENT_VERSION
from ..protocol.login.request import MULTIPLAYER_AUDIENCE, marshal_public_key
from .jwks import DEFAULT_KEY_REFRESH_INTERVAL, RefreshingKeySet
from .json import (
    get_raw,
    get_string,
    go_quote,
    lookup,
    opt_int,
    opt_string,
    parse_object,
)
from .timestamp import NANOS_PER_SECOND, parse_rfc3339
from .transport import (
    Request,
    Response,
    Transport,
    join_path,
    status_error,
)

comptime DISCOVERY_URL = "https://client.discovery.minecraft-services.net"
"""The discovery service."""
comptime APPLICATION_TYPE_MINECRAFT_PE = "MinecraftPE"
"""The application type of Bedrock Edition clients."""
comptime USER_AGENT = "libhttpclient/1.0.0.0"
"""The user agent of libHttpClient, sent to Minecraft services."""

comptime _EXPIRATION_DELTA_NS = 60 * NANOS_PER_SECOND
comptime _LEEWAY_NS = 60 * NANOS_PER_SECOND
"""go-jose's `jwt.DefaultLeeway`."""


def discovery_request(app_type: String, version: String) -> Request:
    """Builds the discovery request (`Discover`)."""
    var headers = List[Tuple[String, String]]()
    headers.append(("Content-Type", "application/json"))
    headers.append(("User-Agent", USER_AGENT))
    return Request(
        "GET",
        join_path(
            DISCOVERY_URL, "/api/v1.0/discovery", app_type, "builds", version
        ),
        headers^,
        List[UInt8](),
    )


struct AuthorizationEnvironment(Copyable, Movable):
    """The `auth` service environment from discovery."""

    var service_uri: String
    """Base URL of the authorization service."""
    var issuer: String
    """The OpenID issuer of multiplayer tokens."""
    var playfab_title_id: String
    """The PlayFab title ID, `20CA2` for retail."""
    var edu_playfab_title_id: String
    """The Education Edition PlayFab title ID."""

    def __init__(
        out self,
        var service_uri: String,
        var issuer: String,
        var playfab_title_id: String,
        var edu_playfab_title_id: String,
    ):
        """Creates an environment."""
        self.service_uri = service_uri^
        self.issuer = issuer^
        self.playfab_title_id = playfab_title_id^
        self.edu_playfab_title_id = edu_playfab_title_id^

    def issuer_domain(self) raises -> String:
        """Returns the issuer as Go's `Issuer.JoinPath().String()` prints it."""
        var s = self.issuer.copy()
        var scheme_end = s.find("://")
        if scheme_end >= 0 and s.find("/", scheme_end + 3) < 0:
            s += "/"
        return s^


def _service_error(request: Request, response: Response) -> Error:
    """Go's `internal.Err`: the service's error JSON, else the status."""
    try:
        var obj = parse_object(Span(response.body))
        return Error(
            String(
                "minecraft/service: ",
                opt_string(obj, "code"),
                ": ",
                go_quote(opt_string(obj, "message")),
                " (",
                opt_string(obj, "namespace"),
                ")",
            )
        )
    except:
        return status_error(request, response)


def parse_discovery_response(
    request: Request, response: Response
) raises -> AuthorizationEnvironment:
    """Decodes discovery and extracts the `auth` `prod` environment."""
    if response.status != 200:
        raise _service_error(request, response)
    var result = parse_object(
        get_raw(parse_object(Span(response.body)), "result").as_bytes()
    )
    var envs = parse_object(get_raw(result, "serviceEnvironments").as_bytes())
    if not lookup(envs, "auth"):
        raise Error(
            'minecraft/service: "auth" is not present in ServiceEnvironments'
        )
    var auth = parse_object(get_raw(envs, "auth").as_bytes())
    if not lookup(auth, "prod"):
        raise Error(
            'minecraft/service: "prod" is not present on "auth" in'
            " ServiceEnvironments"
        )
    var prod = parse_object(get_raw(auth, "prod").as_bytes())
    var env = AuthorizationEnvironment(
        opt_string(prod, "serviceUri"),
        opt_string(prod, "issuer"),
        opt_string(prod, "playFabTitleId"),
        opt_string(prod, "eduPlayFabTitleId"),
    )
    if env.service_uri.byte_length() == 0:
        raise Error(
            "service: AuthorizationEnvironment.ServiceURI cannot be empty"
            " string"
        )
    if env.issuer.byte_length() == 0:
        raise Error(
            "service: AuthorizationEnvironment.Issuer cannot be empty string"
        )
    return env^


def session_start_request(
    env: AuthorizationEnvironment, session_ticket: String, device_id: String
) -> Request:
    """Builds the session start request (`AuthorizationEnvironment.Token`).

    Uses gophertunnel's defaults: a Windows 10 UWP device with 16 GiB of
    memory, game version `CURRENT_VERSION`, language `en-US`.
    """
    var body = String(
        '{"device":{"applicationType":',
        go_quote(APPLICATION_TYPE_MINECRAFT_PE),
        ',"capabilities":null,"gameVersion":',
        go_quote(CURRENT_VERSION),
        ',"id":',
        go_quote(device_id),
        ',"memory":"17179869184","platform":"Windows10","playFabTitleId":',
        go_quote(env.playfab_title_id),
        ',"storePlatform":"uwp.store","type":"Windows10"},',
        '"user":{"language":"en","languageCode":"en-US","regionCode":"US",',
        '"token":',
        go_quote(session_ticket),
        ',"tokenType":"PlayFab"}}\n',
    )
    var headers = List[Tuple[String, String]]()
    headers.append(("Content-Type", "application/json"))
    headers.append(("Accept", "application/json"))
    headers.append(("User-Agent", USER_AGENT))
    return Request(
        "POST",
        join_path(env.service_uri, "/api/v1.0/session/start"),
        headers^,
        List[UInt8](body.as_bytes()),
    )


@fieldwise_init
struct ServiceToken(Copyable, Movable):
    """A Minecraft services token (`service.Token`). A secret."""

    var authorization_header: String
    """`MCToken <jwt>`, sent as the `Authorization` header."""
    var valid_until_ns: Int
    """Expiry as Unix nanoseconds."""

    def valid(self, now_ns: Int) -> Bool:
        """Reports whether the token is usable (`Token.Valid`)."""
        return (
            self.authorization_header.byte_length() > 0
            and now_ns < self.valid_until_ns - _EXPIRATION_DELTA_NS
        )


def check_token_claims(authorization_header: String, now_ns: Int) raises:
    """Checks the claims of an `MCToken` JWT like gophertunnel's `decodeClaims`.

    The signature is not verified (neither does Go). The payload must have
    a non-nil `pmid` UUID, and `nbf`, `exp` and `iat`, when present, must
    hold at `now_ns` with go-jose's one-minute leeway.
    """
    var jwt = authorization_header.copy()
    if jwt.startswith("MCToken "):
        var bare = String(jwt[byte=8:])
        jwt = bare^
    var parts = jwt.split(".")
    if len(parts) != 3:
        raise Error("minecraft/service: malformed JWT")
    var payload = base64url_decode(parts[1])
    var claims = parse_object(Span(payload))
    var pmid = opt_string(claims, "pmid")
    if (
        pmid.byte_length() == 0
        or pmid == "00000000-0000-0000-0000-000000000000"
    ):
        raise Error("service: Token.Claims.PlayerMessagingID is uuid.Nil")
    var now_s = now_ns // NANOS_PER_SECOND
    var leeway_s = _LEEWAY_NS // NANOS_PER_SECOND
    if lookup(claims, "nbf") and now_s + leeway_s < opt_int(claims, "nbf"):
        raise Error("validate JWT claims: token not valid yet (nbf)")
    if lookup(claims, "exp") and now_s - leeway_s > opt_int(claims, "exp"):
        raise Error("validate JWT claims: token is expired (exp)")
    if lookup(claims, "iat") and now_s + leeway_s < opt_int(claims, "iat"):
        raise Error("validate JWT claims: token issued in the future (iat)")


def parse_session_start_response(
    request: Request, response: Response, now_ns: Int
) raises -> ServiceToken:
    """Decodes a session start response."""
    if response.status != 200:
        raise _service_error(request, response)
    var root = parse_object(Span(response.body))
    if not lookup(root, "result"):
        raise Error(
            "minecraft/service: AuthorizationEnvironment: invalid token result"
        )
    var result = parse_object(get_raw(root, "result").as_bytes())
    var valid_until = 0
    if case .Some(v) = lookup(result, "validUntil"):
        valid_until = parse_rfc3339(json_parse_string(v))
    var token = ServiceToken(
        opt_string(result, "authorizationHeader"), valid_until
    )
    if not token.valid(now_ns):
        raise Error(
            "minecraft/service: AuthorizationEnvironment: invalid token result"
        )
    check_token_claims(token.authorization_header, now_ns)
    return token^


def multiplayer_token_request(
    env: AuthorizationEnvironment,
    token: ServiceToken,
    private_key: Span[UInt8, _],
) raises -> Request:
    """Builds the multiplayer session start request (`MultiplayerToken`)."""
    var body = String(
        '{"publicKey":', go_quote(marshal_public_key(private_key)), "}\n"
    )
    var headers = List[Tuple[String, String]]()
    headers.append(("Content-Type", "application/json"))
    headers.append(("Accept", "application/json"))
    headers.append(("Authorization", token.authorization_header))
    return Request(
        "POST",
        join_path(env.service_uri, "/api/v1.0/multiplayer/session/start"),
        headers^,
        List[UInt8](body.as_bytes()),
    )


def parse_multiplayer_token_response(
    request: Request, response: Response
) raises -> String:
    """Decodes a multiplayer session start response."""
    if response.status != 200:
        raise _service_error(request, response)
    var root = parse_object(Span(response.body))
    var signed = String()
    if case .Some(raw) = lookup(root, "result"):
        signed = opt_string(parse_object(raw.as_bytes()), "signedToken")
    if signed.byte_length() == 0:
        raise Error("minecraft/service: invalid multiplayer token result")
    return signed^


def openid_configuration_request(env: AuthorizationEnvironment) -> Request:
    """Builds the OpenID configuration request
    (`AuthorizationEnvironment.configuration`)."""
    var headers = List[Tuple[String, String]]()
    headers.append(("Accept", "application/json"))
    headers.append(("Content-Type", "application/json"))
    headers.append(("User-Agent", USER_AGENT))
    return Request(
        "GET",
        join_path(env.issuer, "/.well-known/openid-configuration"),
        headers^,
        List[UInt8](),
    )


@fieldwise_init
struct ProviderConfig(Copyable, Movable):
    """The parts of an OpenID configuration a verifier needs (go-oidc
    `ProviderConfig`)."""

    var issuer: String
    """`issuer`, informational: the verifier uses the environment's."""
    var jwks_url: String
    """`jwks_uri`."""
    var algorithms: List[String]
    """`id_token_signing_alg_values_supported`."""


def parse_openid_configuration(
    request: Request, response: Response
) raises -> ProviderConfig:
    """Decodes the OpenID configuration."""
    if response.status != 200:
        raise _service_error(request, response)
    var obj = decode_object(Span(response.body))
    var algs = List[String]()
    if case .Some(raw) = jose_lookup(
        obj, "id_token_signing_alg_values_supported"
    ):
        for item in array_values(raw):
            algs.append(string_value(item))
    return ProviderConfig(
        jose_opt_string(obj, "issuer"), jose_opt_string(obj, "jwks_uri"), algs^
    )


def verifier[
    T: Transport
](
    env: AuthorizationEnvironment,
    var transport: T,
    refresh_interval: Int = DEFAULT_KEY_REFRESH_INTERVAL,
) raises -> IDTokenVerifier[RefreshingKeySet[T]]:
    """Creates the multiplayer token verifier a server checks logins with
    (`AuthorizationEnvironment.VerifierContext`).

    Fetches the OpenID configuration now; the JWKS is fetched on the first
    verification. The required issuer is the environment's, with a `/`
    path added, and the audience is the multiplayer audience.
    """
    var request = openid_configuration_request(env)
    var config: ProviderConfig
    try:
        config = parse_openid_configuration(
            request, transport.round_trip(request)
        )
    except e:
        raise Error(t"obtain OpenID configuration: {e}")
    var key_set = RefreshingKeySet(
        transport^,
        config.jwks_url.copy(),
        refresh_interval,
        config.algorithms.copy(),
    )
    var oidc_config = Config()
    oidc_config.client_id = String(MULTIPLAYER_AUDIENCE)
    oidc_config.supported_signing_algs = config.algorithms.copy()
    return IDTokenVerifier(env.issuer_domain(), key_set^, oidc_config^)
