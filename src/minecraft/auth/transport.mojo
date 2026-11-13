"""The HTTP seam of the sign-in flow.

Every request the flow makes is first built as a `Request` value and every
response is parsed from a `Response` value, so all of it is testable without
a network. A `Transport` performs the exchange: `HttpsTransport` (in
`https.mojo`) uses the pure-Mojo TLS client, and tests use recorded
responses. This plays the part of Go's `net/http.Client`.
"""


@fieldwise_init
struct Request(Copyable, Movable, Writable):
    """An HTTP request built by the sign-in flow."""

    var method: String
    """The method, `GET` or `POST`."""
    var url: String
    """The absolute `https://` URL."""
    var headers: List[Tuple[String, String]]
    """Header names and values, in the order they are sent."""
    var body: List[UInt8]
    """The request body, empty for `GET`."""

    def header(self, name: StringSpan) -> Optional[String]:
        """Returns the first header with this name, compared case-insensitively.

        Args:
            name: The header name.

        Returns:
            The value, or `None`.
        """
        var want = String(name).lower()
        for h in self.headers:
            if h[0].lower() == want:
                return h[1]
        return None

    def body_text(self) -> String:
        """Returns the body as text, for tests and comparisons.

        Returns:
            The body bytes as a string (bodies the flow builds are UTF-8).
        """
        return String(from_utf8_lossy=Span(self.body))

    def write_to(self, mut writer: Some[Writer]):
        """Writes the method and URL only; headers and body hold secrets.

        Args:
            writer: The destination.
        """
        writer.write(self.method, " ", self.url)


@fieldwise_init
struct Response(Copyable, Movable):
    """An HTTP response handed back by a `Transport`."""

    var status: Int
    """The status code."""
    var headers: List[Tuple[String, String]]
    """Header names (lowercased) and values."""
    var body: List[UInt8]
    """The decoded body (chunked encoding already removed)."""

    def header(self, name: StringSpan) -> Optional[String]:
        """Returns the first header with this name, compared case-insensitively.

        Args:
            name: The header name.

        Returns:
            The value, or `None`.
        """
        var want = String(name).lower()
        for h in self.headers:
            if h[0].lower() == want:
                return h[1]
        return None


trait Transport(Deinitable, Movable):
    """Performs HTTP exchanges for the sign-in flow."""

    def round_trip(mut self, request: Request) raises -> Response:
        """Sends a request and returns the response.

        Non-2xx statuses are returned, not raised; callers check `status`.

        Args:
            request: The request.

        Returns:
            The response.

        Raises:
            Error: On connection, TLS or framing failures.
        """
        ...


@fieldwise_init
struct URL(Copyable, Movable):
    """The parts of an absolute URL the flow needs."""

    var scheme: String
    """`https` or `http`."""
    var host: String
    """The host name without port."""
    var port: String
    """The explicit port, or empty."""
    var path: String
    """The path, `/` when the URL has none."""
    var raw_query: String
    """The query without `?`, or empty."""


def parse_url(url: StringSpan) raises -> URL:
    """Splits an absolute URL into scheme, host, port, path and query.

    Args:
        url: A URL such as `https://host:443/path?q=1`.

    Returns:
        The parts.

    Raises:
        Error: If there is no `scheme://` prefix or no host.
    """
    var s = String(url)
    var sep = s.find("://")
    if sep <= 0:
        raise Error("url: missing scheme")
    var scheme = String(s[byte=0:sep]).lower()
    var rest = String(s[byte = sep + 3 :])
    var fragment = rest.find("#")
    if fragment >= 0:
        var cut = String(rest[byte=0:fragment])
        rest = cut^
    var authority_end = rest.byte_length()
    for i in range(rest.byte_length()):
        var c = rest.as_bytes()[i]
        if c == 0x2F or c == 0x3F:
            authority_end = i
            break
    var authority = String(rest[byte=0:authority_end])
    var tail = String(rest[byte=authority_end:])
    var host = authority
    var port = String()
    var colon = authority.rfind(":")
    if colon >= 0:
        host = String(authority[byte=0:colon])
        port = String(authority[byte = colon + 1 :])
    if host.byte_length() == 0:
        raise Error("url: missing host")
    var path = tail
    var query = String()
    var q = tail.find("?")
    if q >= 0:
        path = String(tail[byte=0:q])
        query = String(tail[byte = q + 1 :])
    if path.byte_length() == 0:
        path = "/"
    return URL(scheme^, host^, port^, path^, query^)


def join_path(base: StringSpan, *elems: String) -> String:
    """Appends path elements to a URL, like Go's `url.URL.JoinPath`.

    Slashes between elements are collapsed to one; a trailing slash on the
    last element is kept.

    Args:
        base: The base URL.
        elems: Path elements to append.

    Returns:
        The joined URL.
    """
    var out = String(base)
    for e in elems:
        var part = String(e)
        while out.endswith("/"):
            var trimmed = String(out[byte = 0 : out.byte_length() - 1])
            out = trimmed^
        while part.startswith("/"):
            var rest = String(part[byte=1:])
            part = rest^
        out += "/"
        out += part
    return out^


def _unreserved(c: UInt8) -> Bool:
    return (
        (c >= 0x41 and c <= 0x5A)
        or (c >= 0x61 and c <= 0x7A)
        or (c >= 0x30 and c <= 0x39)
        or c == 0x2D
        or c == 0x2E
        or c == 0x5F
        or c == 0x7E
    )


def query_escape(text: StringSpan) -> String:
    """Escapes a form value like Go's `url.QueryEscape`.

    Args:
        text: The value.

    Returns:
        The value with spaces as `+` and other reserved bytes as `%XX`.
    """
    var hex = "0123456789ABCDEF".as_bytes()
    var out = List[UInt8]()
    for c in text.as_bytes():
        if _unreserved(c):
            out.append(c)
        elif c == 0x20:
            out.append(0x2B)
        else:
            out.append(0x25)
            out.append(hex[Int(c >> 4)])
            out.append(hex[Int(c & 0xF)])
    return String(unsafe_from_utf8=Span(out))


def form_encode(var values: List[Tuple[String, String]]) -> String:
    """Encodes form values sorted by key, like Go's `url.Values.Encode`.

    Args:
        values: Key/value pairs (one value per key).

    Returns:
        The `application/x-www-form-urlencoded` body.
    """
    # Insertion sort keeps this dependency-free; forms have four entries.
    for i in range(1, len(values)):
        var j = i
        while j > 0 and values[j - 1][0] > values[j][0]:
            var tmp = values[j - 1].copy()
            values[j - 1] = values[j].copy()
            values[j] = tmp^
            j -= 1
    var out = String()
    for i in range(len(values)):
        if i > 0:
            out += "&"
        out += query_escape(values[i][0])
        out += "="
        out += query_escape(values[i][1])
    return out^


def status_error(request: Request, response: Response) -> Error:
    """Builds the error for an unexpected status, without any secrets.

    Includes up to 256 bytes of the response body: error bodies from these
    services carry codes and messages, never tokens.

    Args:
        request: The request that failed.
        response: Its response.

    Returns:
        An error naming the method, URL and status.
    """
    var n = min(len(response.body), 256)
    var snippet = String(from_utf8_lossy=Span(response.body)[0:n])
    var msg = String(request.method, " ", request.url, ": ", response.status)
    var xerr = response.header("x-err")
    if case .Some(code) = xerr:
        msg += String(" (X-Err ", code, ")")
    if n > 0:
        msg += String(": ", snippet)
    return Error(msg)
