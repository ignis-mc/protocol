"""Minecraft services: discovery, session token and multiplayer token.

Port of gophertunnel `minecraft/service/discovery.go` (`Discover`,
`Discovery.Environment`) and `token.go` (`AuthorizationEnvironment.Token`,
`MultiplayerToken`, the default device and user configuration and the
`pmid` claim check). The session token (`MCToken …`) is obtained with the
PlayFab session ticket; the multiplayer token is an OpenID JWT whose `cpk`
claim is the client's P-384 public key, which servers verify against the
issuer.
"""

from nethernet.crypto.base64 import base64url_decode
from nethernet.json import json_parse_string

from ..protocol.info import CURRENT_VERSION
from ..protocol.login.request import marshal_public_key
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
from .transport import Request, Response, join_path, status_error

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
    """Builds the discovery request (`Discover`).

    Args:
        app_type: The application type, `MinecraftPE`.
        version: The game version, e.g. `1.26.60`.

    Returns:
        `GET …/api/v1.0/discovery/<app_type>/builds/<version>`.
    """
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
        """Creates an environment.

        Args:
            service_uri: Base URL of the authorization service.
            issuer: The OpenID issuer.
            playfab_title_id: The PlayFab title ID.
            edu_playfab_title_id: The Education Edition title ID.
        """
        self.service_uri = service_uri^
        self.issuer = issuer^
        self.playfab_title_id = playfab_title_id^
        self.edu_playfab_title_id = edu_playfab_title_id^

    def issuer_domain(self) raises -> String:
        """Returns the issuer as Go's `Issuer.JoinPath().String()` prints it.

        Returns:
            The issuer with a `/` path when it has none.

        Raises:
            Error: Never in practice; kept for URL parsing.
        """
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
    """Decodes discovery and extracts the `auth` `prod` environment.

    Args:
        request: The request that was sent.
        response: Its response.

    Returns:
        The authorization environment.

    Raises:
        Error: On a non-200 status, a missing `auth`/`prod` entry or an
            empty `serviceUri` or `issuer`.
    """
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

    Args:
        env: The authorization environment.
        session_ticket: The PlayFab session ticket.
        device_id: A fresh UUID for the device.

    Returns:
        The `POST …/api/v1.0/session/start` request.
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
        """Reports whether the token is usable (`Token.Valid`).

        Args:
            now_ns: The current Unix time in nanoseconds.

        Returns:
            True if it is set and does not expire within a minute.
        """
        return (
            self.authorization_header.byte_length() > 0
            and now_ns < self.valid_until_ns - _EXPIRATION_DELTA_NS
        )


def check_token_claims(authorization_header: String, now_ns: Int) raises:
    """Checks the claims of an `MCToken` JWT like gophertunnel's `decodeClaims`.

    The signature is not verified (neither does Go). The payload must have
    a non-nil `pmid` UUID, and `nbf`, `exp` and `iat`, when present, must
    hold at `now_ns` with go-jose's one-minute leeway.

    Args:
        authorization_header: `MCToken <jwt>`.
        now_ns: The current Unix time in nanoseconds.

    Raises:
        Error: If the JWT is malformed or a claim check fails.
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
    """Decodes a session start response.

    Args:
        request: The request that was sent.
        response: Its response.
        now_ns: The current Unix time in nanoseconds.

    Returns:
        The service token.

    Raises:
        Error: On a non-200 status, an invalid token or bad claims.
    """
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
    """Builds the multiplayer session start request (`MultiplayerToken`).

    Args:
        env: The authorization environment.
        token: The service token.
        private_key: The client's 48-byte P-384 private scalar; its public
            key becomes the token's `cpk` claim.

    Returns:
        The `POST …/api/v1.0/multiplayer/session/start` request.

    Raises:
        Error: If the private key is invalid.
    """
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
    """Decodes a multiplayer session start response.

    Args:
        request: The request that was sent.
        response: Its response.

    Returns:
        The signed multiplayer token (a JWT).

    Raises:
        Error: On a non-200 status or an empty token.
    """
    if response.status != 200:
        raise _service_error(request, response)
    var root = parse_object(Span(response.body))
    var signed = String()
    if case .Some(raw) = lookup(root, "result"):
        signed = opt_string(parse_object(raw.as_bytes()), "signedToken")
    if signed.byte_length() == 0:
        raise Error("minecraft/service: invalid multiplayer token result")
    return signed^
