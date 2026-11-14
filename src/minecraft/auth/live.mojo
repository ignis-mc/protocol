"""Microsoft account (Windows Live) OAuth2 tokens.

Port of the refresh half of `go-xsapi/v2/xal/sisu/oauth2.go`
(`tokenRefresher.Token`) and the parts of `golang.org/x/oauth2.Token` it
relies on. gophertunnel's `auth.AndroidConfig.TokenSource` hands out the
stored token while it is valid and otherwise refreshes it at
`login.live.com/oauth20_token.srf` with the Android client ID. Device-code
sign-in (`RequestLiveToken`) is not ported: the flow starts from a token in
Lunar's account store.
"""

from nethernet.json import json_parse_string

from .json import lookup, opt_int, opt_string, parse_object
from .timestamp import NANOS_PER_SECOND, parse_rfc3339
from .transport import Request, Response, form_encode

comptime LIVE_TOKEN_URL = "https://login.live.com/oauth20_token.srf"
"""`microsoft.LiveConnectEndpoint.TokenURL`."""

comptime LIVE_SCOPE = "service::user.auth.xboxlive.com::MBI_SSL"
"""The scope SISU titles request, for an XASU-capable access token."""

comptime _EXPIRY_DELTA_NS = 10 * NANOS_PER_SECOND
"""`oauth2` treats a token as expired this long before its expiry."""


struct OAuthToken(Copyable, Defaultable, Movable):
    """A Microsoft account token (`oauth2.Token`). Treat it as a secret."""

    var access_token: String
    """The access token sent to SISU as `t=<token>`."""
    var token_type: String
    """Usually `bearer`."""
    var refresh_token: String
    """The refresh token."""
    var expiry_ns: Int
    """Expiry as Unix nanoseconds, 0 for none."""

    def __init__(out self):
        """Creates an empty (invalid) token."""
        self.access_token = String()
        self.token_type = String()
        self.refresh_token = String()
        self.expiry_ns = 0

    def __init__(
        out self,
        var access_token: String,
        var token_type: String,
        var refresh_token: String,
        expiry_ns: Int,
    ):
        """Creates a token."""
        self.access_token = access_token^
        self.token_type = token_type^
        self.refresh_token = refresh_token^
        self.expiry_ns = expiry_ns

    def valid(self, now_ns: Int) -> Bool:
        """Reports whether the access token can still be used (`Token.Valid`).
        """
        if self.access_token.byte_length() == 0:
            return False
        return self.expiry_ns == 0 or now_ns < self.expiry_ns - _EXPIRY_DELTA_NS


def parse_oauth_token(raw: StringSpan, now_ns: Int) raises -> OAuthToken:
    """Decodes the JSON form of an `oauth2.Token`.

    Reads `access_token`, `token_type`, `refresh_token` and `expiry`
    (RFC 3339); without an `expiry`, `expires_in` seconds from `now_ns`
    is used as `tokenRefresher` does.
    """
    var obj = parse_object(raw.as_bytes())
    var expiry = 0
    if case .Some(value) = lookup(obj, "expiry"):
        var text = json_parse_string(value)
        if not text.startswith("0001-01-01"):
            expiry = parse_rfc3339(text)
    if expiry == 0:
        var expires_in = opt_int(obj, "expires_in")
        if expires_in != 0:
            expiry = now_ns + expires_in * NANOS_PER_SECOND
    return OAuthToken(
        opt_string(obj, "access_token"),
        opt_string(obj, "token_type"),
        opt_string(obj, "refresh_token"),
        expiry,
    )


def refresh_request(
    client_id: String, user_agent: String, refresh_token: String
) -> Request:
    """Builds the refresh-token grant request."""
    var form = List[Tuple[String, String]]()
    form.append(("grant_type", "refresh_token"))
    form.append(("refresh_token", refresh_token))
    form.append(("scope", LIVE_SCOPE))
    form.append(("client_id", client_id))
    var headers = List[Tuple[String, String]]()
    headers.append(("Content-Type", "application/x-www-form-urlencoded"))
    headers.append(("User-Agent", user_agent))
    return Request(
        "POST",
        LIVE_TOKEN_URL,
        headers^,
        List[UInt8](form_encode(form^).as_bytes()),
    )


def parse_refresh_response(
    response: Response, now_ns: Int
) raises -> OAuthToken:
    """Decodes a refresh response."""
    if response.status != 200:
        var detail = String()
        try:
            var obj = parse_object(Span(response.body))
            detail = String(
                ": ",
                opt_string(obj, "error"),
                ": ",
                opt_string(obj, "error_description"),
            )
        except:
            pass
        raise Error(
            String("POST ", LIVE_TOKEN_URL, ": ", response.status, detail)
        )
    var token = parse_oauth_token(String(from_utf8=Span(response.body)), now_ns)
    if not token.valid(now_ns):
        raise Error("xal/sisu: invalid oauth2 token")
    return token^
