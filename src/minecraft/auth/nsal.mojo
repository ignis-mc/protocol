"""NSAL (Network Security Allow List) title data.

Port of `go-xsapi/v2/xal/nsal/title.go` and the matching half of
`resolver.go`. NSAL maps a request URL to the relying party whose XSTS token
it needs and the signature policy it is signed with. The default title data
(public) covers `*.xboxlive.com`, including SISU; the current title's data
(fetched with the `http://xboxlive.com` token) covers Minecraft's own
services such as `multiplayer.minecraft.net` and `*.playfabapi.com`.

CIDR host patterns only match IP-literal hosts in Go; this port never asks
for an IP URL and treats them as non-matching.
"""

from nethernet.json import json_parse_int

from .json import (
    lookup,
    opt_int,
    opt_string,
    parse_array,
    parse_object,
    parse_string_array,
)
from .signature import SignaturePolicy, auth_policy
from .transport import Request, Response, URL, parse_url, status_error

comptime NSAL_DEFAULT_URL = (
    "https://title.mgt.xboxlive.com/titles/default/endpoints?type=1"
)
"""The public default title data."""

comptime HOST_TYPE_FQDN = "fqdn"
"""`Endpoint.host` is an exact host name."""
comptime HOST_TYPE_WILDCARD = "wildcard"
"""`Endpoint.host` starts with `*`."""
comptime HOST_TYPE_CIDR = "cidr"
"""`Endpoint.host` is an IP prefix."""


struct Endpoint(Copyable, Defaultable, Movable):
    """One endpoint a title may call."""

    var protocol: String
    """The required URL scheme."""
    var host: String
    """Host name or pattern, interpreted per `host_type`."""
    var port: Int
    """The required port, 0 for any."""
    var host_type: String
    """`fqdn`, `wildcard` or `cidr`."""
    var path: String
    """The required path, empty for any."""
    var relying_party: String
    """The relying party of the XSTS token this endpoint needs."""
    var sub_relying_party: String
    """An alias of the relying party."""
    var token_type: String
    """Always `JWT`."""
    var signature_policy_index: Int
    """Index into `TitleData.signature_policies`, -1 when absent."""

    def __init__(out self):
        """Creates an empty endpoint that matches nothing."""
        self.protocol = String()
        self.host = String()
        self.port = 0
        self.host_type = String()
        self.path = String()
        self.relying_party = String()
        self.sub_relying_party = String()
        self.token_type = String()
        self.signature_policy_index = -1

    def matches(self, u: URL) -> Bool:
        """Reports whether a URL falls under this endpoint.

        Args:
            u: The parsed request URL.

        Returns:
            True on a match; never for an empty relying party.
        """
        if self.relying_party.byte_length() == 0:
            return False
        if self.protocol != u.scheme:
            return False
        var host_ok = False
        if self.host_type == HOST_TYPE_FQDN:
            host_ok = self.host == u.host
        elif self.host_type == HOST_TYPE_WILDCARD:
            host_ok = self.host.startswith("*") and _glob(
                self.host.as_bytes(), u.host.as_bytes()
            )
        if not host_ok:
            return False
        if self.port != 0 and String(self.port) != _effective_port(u):
            return False
        return self.path.byte_length() == 0 or self.path == u.path


def _effective_port(u: URL) -> String:
    if u.port.byte_length() > 0:
        return u.port.copy()
    if u.scheme == "https":
        return "443"
    if u.scheme == "http":
        return "80"
    return String()


def _glob(pattern: Span[UInt8, _], text: Span[UInt8, _]) -> Bool:
    """Matches `text` against `pattern`, where `*` stands for any run of bytes.

    Equivalent to Go's `^` + QuoteMeta(host) with `\\*` turned into `.*` +
    `$` regular expression.
    """
    var p = 0
    var t = 0
    var star = -1
    var mark = 0
    while t < len(text):
        if p < len(pattern) and pattern[p] == 0x2A:
            star = p
            mark = t
            p += 1
        elif p < len(pattern) and pattern[p] == text[t]:
            p += 1
            t += 1
        elif star >= 0:
            p = star + 1
            mark += 1
            t = mark
        else:
            return False
    while p < len(pattern) and pattern[p] == 0x2A:
        p += 1
    return p == len(pattern)


@fieldwise_init
struct EndpointMatch(Copyable, Movable):
    """The result of resolving a URL against title data."""

    var relying_party: String
    """The relying party to request an XSTS token for."""
    var policy: SignaturePolicy
    """The policy to sign the request with."""


struct TitleData(Copyable, Defaultable, Movable):
    """The endpoints and signature policies of one title."""

    var endpoints: List[Endpoint]
    """Endpoints in document order."""
    var signature_policies: List[SignaturePolicy]
    """Policies referenced by index from the endpoints."""

    def __init__(out self):
        """Creates empty title data."""
        self.endpoints = List[Endpoint]()
        self.signature_policies = List[SignaturePolicy]()

    def match(self, url: StringSpan) raises -> Optional[EndpointMatch]:
        """Resolves a URL like Go's `TitleData.Match`.

        The last matching endpoint wins, except that an `fqdn` match stops
        the search immediately.

        Args:
            url: The request URL.

        Returns:
            The relying party and policy, or `None` if nothing matches. An
            out-of-range policy index selects `auth_policy()`.

        Raises:
            Error: If the URL cannot be parsed.
        """
        var u = parse_url(url)
        var found = Optional[EndpointMatch](None)
        for e in self.endpoints:
            if not e.matches(u):
                continue
            var i = e.signature_policy_index
            var policy: SignaturePolicy
            if i >= 0 and i < len(self.signature_policies):
                policy = self.signature_policies[i].copy()
            else:
                policy = auth_policy()
            found = EndpointMatch(e.relying_party.copy(), policy^)
            if e.host_type == HOST_TYPE_FQDN:
                break
        return found^


def parse_title_data(body: Span[UInt8, _]) raises -> TitleData:
    """Decodes an NSAL title data document.

    Args:
        body: The response body.

    Returns:
        The title data.

    Raises:
        Error: If the body is not a title data object.
    """
    var obj = parse_object(body)
    var out = TitleData()
    if case .Some(raw) = lookup(obj, "EndPoints"):
        for item in parse_array(raw):
            var m = parse_object(item.as_bytes())
            var e = Endpoint()
            e.protocol = opt_string(m, "Protocol")
            e.host = opt_string(m, "Host")
            e.port = opt_int(m, "Port")
            e.host_type = opt_string(m, "HostType")
            e.path = opt_string(m, "Path")
            e.relying_party = opt_string(m, "RelyingParty")
            e.sub_relying_party = opt_string(m, "SubRelyingParty")
            e.token_type = opt_string(m, "TokenType")
            if case .Some(index) = lookup(m, "SignaturePolicyIndex"):
                e.signature_policy_index = json_parse_int(index)
            out.endpoints.append(e^)
    if case .Some(raw) = lookup(obj, "SignaturePolicies"):
        for item in parse_array(raw):
            var m = parse_object(item.as_bytes())
            var algorithms = List[String]()
            if case .Some(list) = lookup(m, "SupportedAlgorithms"):
                algorithms = parse_string_array(list)
            var extra = List[String]()
            if case .Some(list) = lookup(m, "ExtraHeaders"):
                extra = parse_string_array(list)
            out.signature_policies.append(
                SignaturePolicy(
                    UInt32(opt_int(m, "Version")),
                    algorithms^,
                    opt_int(m, "MaxBodyBytes"),
                    extra^,
                )
            )
    return out^


def default_title_request() -> Request:
    """Builds the request for the public default title data (Go `Default`).

    Returns:
        `GET https://title.mgt.xboxlive.com/titles/default/endpoints?type=1`.
    """
    var headers = List[Tuple[String, String]]()
    headers.append(("X-Xbl-Contract-Version", "1"))
    return Request("GET", NSAL_DEFAULT_URL, headers^, List[UInt8]())


def title_request(
    title_id: String,
    authorization: String,
    proof_key: Span[UInt8, _],
    timestamp_ns: Int,
) raises -> Request:
    """Builds the signed request for one title's data (Go `Title`).

    Args:
        title_id: A title ID, or `current` for the token's own title.
        authorization: The `XBL3.0 x=…` header of the `http://xboxlive.com`
            XSTS token.
        proof_key: The 32-byte P-256 proof key.
        timestamp_ns: Server-adjusted Unix time in nanoseconds.

    Returns:
        The signed `GET …/titles/<id>/endpoints` request.

    Raises:
        Error: If signing fails.
    """
    var headers = List[Tuple[String, String]]()
    headers.append(("X-Xbl-Contract-Version", "1"))
    headers.append(("Authorization", authorization))
    var req = Request(
        "GET",
        String(
            "https://title.mgt.xboxlive.com/titles/", title_id, "/endpoints"
        ),
        headers^,
        List[UInt8](),
    )
    auth_policy().sign(req, proof_key, timestamp_ns)
    return req^


def parse_title_response(
    request: Request, response: Response
) raises -> TitleData:
    """Checks the status of a title data response and decodes it.

    Args:
        request: The request that was sent.
        response: Its response.

    Returns:
        The title data.

    Raises:
        Error: On a non-200 status or a malformed body.
    """
    if response.status != 200:
        raise status_error(request, response)
    return parse_title_data(Span(response.body))
