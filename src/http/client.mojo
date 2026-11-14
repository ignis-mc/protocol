"""An HTTPS/1.1 client (RFC 9110, RFC 9112) over `tls.client.TlsConn`.

One request per connection with `Connection: close`. Bodies framed by
Content-Length, the chunked transfer coding, or the end of the connection
are supported; content codings are not, so every request sends
`Accept-Encoding: identity`. Redirects are returned, not followed.

`parse_url`, `encode_request` and `ResponseParser` are sans-I/O;
`HttpClient` connects them to the network.
"""

from nethernet.os.time import monotonic_ms
from nethernet.wire import put_bytes

from tls.client import TlsConn
from tls.roots import RootStore

comptime DEFAULT_USER_AGENT = "ignis-protocol/0.1"
"""The User-Agent sent when the caller gives none."""
comptime MAX_HEAD_LEN = 65536
"""The longest status line plus header block accepted."""
comptime MAX_BODY_LEN = 64 * 1024 * 1024
"""The largest response body accepted."""


def _ascii_lower(text: StringSpan) -> String:
    var out = List[UInt8](capacity=text.byte_length())
    for b in text.as_bytes():
        if b >= UInt8(ord("A")) and b <= UInt8(ord("Z")):
            out.append(b + 32)
        else:
            out.append(b)
    return String(from_utf8_lossy=Span(out))


def _is_token(text: StringSpan) -> Bool:
    if text.byte_length() == 0:
        return False
    for b in text.as_bytes():
        var ok = (
            (b >= UInt8(ord("a")) and b <= UInt8(ord("z")))
            or (b >= UInt8(ord("A")) and b <= UInt8(ord("Z")))
            or (b >= UInt8(ord("0")) and b <= UInt8(ord("9")))
        )
        if not ok:
            for c in StringSpan("!#$%&'*+-.^_`|~").as_bytes():
                if b == c:
                    ok = True
        if not ok:
            return False
    return True


def _has_ctl(text: StringSpan) -> Bool:
    for b in text.as_bytes():
        if b == 0x0D or b == 0x0A or b == 0:
            return True
    return False


@fieldwise_init
struct Url(Copyable, Writable):
    """The parts of an https URL a request needs."""

    var host: String
    """The host name or IPv4 literal, lowercased."""
    var port: Int
    """The port, 443 unless given."""
    var target: String
    """The request target: path and query, at least "/"."""

    def write_to(self, mut writer: Some[Writer]):
        """Writes the URL back out (without a fragment)."""
        writer.write("https://", self.host)
        if self.port != 443:
            writer.write(":", self.port)
        writer.write(self.target)


def parse_url(url: StringSpan) raises -> Url:
    """Parses an absolute https URL."""
    var text = String(url.strip())
    var lower = _ascii_lower(text)
    if not lower.startswith("https://"):
        raise Error("http: only https URLs are supported")
    var rest = String(text[byte=8:])
    var hash = rest.find("#")
    if hash >= 0:
        var cut = String(rest[byte=0:hash])
        rest = cut^
    var slash = -1
    var bytes = rest.as_bytes()
    for i in range(len(bytes)):
        if bytes[i] == UInt8(ord("/")) or bytes[i] == UInt8(ord("?")):
            slash = i
            break
    var authority: String
    var target: String
    if slash < 0:
        authority = rest
        target = "/"
    else:
        authority = String(rest[byte=0:slash])
        target = String(rest[byte=slash:])
        if target.startswith("?"):
            target = String("/") + target
    if "@" in authority:
        raise Error("http: user info in URLs is not supported")
    if authority.startswith("["):
        raise Error("http: IPv6 hosts are not supported")
    var host = authority
    var port = 443
    var colon = authority.find(":")
    if colon >= 0:
        host = String(authority[byte=0:colon])
        var port_text = String(authority[byte = colon + 1 :])
        if port_text.byte_length() == 0 or port_text.byte_length() > 5:
            raise Error("http: bad port")
        port = 0
        for b in port_text.as_bytes():
            if b < UInt8(ord("0")) or b > UInt8(ord("9")):
                raise Error("http: bad port")
            port = port * 10 + Int(b - UInt8(ord("0")))
        if port == 0 or port > 65535:
            raise Error("http: bad port")
    if host.byte_length() == 0:
        raise Error("http: missing host")
    if _has_ctl(target) or " " in target:
        raise Error("http: invalid characters in URL path")
    for b in host.as_bytes():
        if b <= 0x20 or b == UInt8(ord("/")) or b == UInt8(ord("\\")):
            raise Error("http: invalid host")
    return Url(_ascii_lower(host), port, target^)


def encode_request(
    method: StringSpan,
    url: Url,
    headers: List[Tuple[String, String]],
    body: Span[UInt8, _],
    mut out: List[UInt8],
) raises:
    """Appends an HTTP/1.1 request.

    Host, Content-Length, Connection and Accept-Encoding are always set by
    this function (caller values for them are dropped); User-Agent defaults
    to `DEFAULT_USER_AGENT`.
    """
    if not _is_token(method):
        raise Error("http: invalid method")
    var head = String(method, " ", url.target, " HTTP/1.1\r\nHost: ", url.host)
    if url.port != 443:
        head += String(":", url.port)
    head += "\r\n"
    var has_agent = False
    for h in headers:
        var name = h[0]
        if not _is_token(name):
            raise Error(t"http: invalid header name {name}")
        if _has_ctl(h[1]):
            raise Error(t"http: invalid value for header {name}")
        var key = _ascii_lower(name)
        if (
            key == "host"
            or key == "content-length"
            or key == "transfer-encoding"
            or key == "connection"
            or key == "accept-encoding"
        ):
            continue
        if key == "user-agent":
            has_agent = True
        head += String(name, ": ", h[1], "\r\n")
    if not has_agent:
        head += String("User-Agent: ", DEFAULT_USER_AGENT, "\r\n")
    head += "Accept-Encoding: identity\r\nConnection: close\r\n"
    var m = String(method)
    if len(body) > 0 or m == "POST" or m == "PUT" or m == "PATCH":
        head += String("Content-Length: ", len(body), "\r\n")
    head += "\r\n"
    put_bytes(out, head.as_bytes())
    put_bytes(out, body)


struct HttpResponse(Copyable):
    """A complete HTTP response."""

    var status: Int
    """The status code."""
    var reason: String
    """The reason phrase."""
    var headers: List[Tuple[String, String]]
    """The header fields in order, names lowercased."""
    var body: List[UInt8]
    """The body with any transfer coding removed."""

    def __init__(out self):
        """Creates an empty response."""
        self.status = 0
        self.reason = String()
        self.headers = List[Tuple[String, String]]()
        self.body = List[UInt8]()

    def header(self, name: StringSpan) -> Optional[String]:
        """Looks up a header field."""
        var key = _ascii_lower(name)
        for h in self.headers:
            if h[0] == key:
                return h[1]
        return None

    def text(self) -> String:
        """Decodes the body as UTF-8, replacing invalid sequences."""
        return String(from_utf8_lossy=Span(self.body))


comptime _HEAD = 0
comptime _LENGTH = 1
comptime _CHUNK_SIZE = 2
comptime _CHUNK_DATA = 3
comptime _CHUNK_CRLF = 4
comptime _TRAILERS = 5
comptime _UNTIL_EOF = 6
comptime _DONE = 7


def _find_crlf(data: List[UInt8], start: Int) -> Int:
    for i in range(start, len(data) - 1):
        if data[i] == 0x0D and data[i + 1] == 0x0A:
            return i
    return -1


def _trim(text: StringSpan) -> String:
    return String(text.strip(" \t"))


struct ResponseParser(Movable):
    """Parses one response from a byte stream, incrementally."""

    var _state: Int
    var _buf: List[UInt8]
    var _remaining: Int
    var _no_body: Bool
    var _response: HttpResponse

    def __init__(out self, method: StringSpan):
        """Creates a parser for the response to a request."""
        self._state = _HEAD
        self._buf = List[UInt8]()
        self._remaining = 0
        self._no_body = String(method) == "HEAD"
        self._response = HttpResponse()

    def is_complete(self) -> Bool:
        """Checks whether the whole response has been parsed."""
        return self._state == _DONE

    def feed(mut self, data: Span[UInt8, _]) raises:
        """Consumes more bytes from the connection."""
        if self._state == _DONE:
            return
        put_bytes(self._buf, data)
        self._advance()

    def finish(mut self) raises:
        """Signals that the connection ended."""
        if self._state == _UNTIL_EOF:
            self._state = _DONE
            return
        if self._state != _DONE:
            raise Error("http: connection closed before the response ended")

    def take_response(mut self) raises -> HttpResponse:
        """Removes the parsed response."""
        if self._state != _DONE:
            raise Error("http: response not complete")
        var r = self._response^
        self._response = HttpResponse()
        return r^

    def _take_body(mut self, n: Int) raises:
        if len(self._response.body) + n > MAX_BODY_LEN:
            raise Error("http: response body too large")
        put_bytes(self._response.body, Span(self._buf)[0:n])
        self._consume(n)

    def _consume(mut self, n: Int):
        if n >= len(self._buf):
            self._buf.clear()
        else:
            var rest = List[UInt8](Span(self._buf)[n:])
            self._buf = rest^

    def _advance(mut self) raises:
        while True:
            if self._state == _HEAD:
                if not self._parse_head():
                    return
            elif self._state == _LENGTH:
                var n = min(self._remaining, len(self._buf))
                self._take_body(n)
                self._remaining -= n
                if self._remaining > 0:
                    return
                self._state = _DONE
            elif self._state == _UNTIL_EOF:
                self._take_body(len(self._buf))
                return
            elif self._state == _CHUNK_SIZE:
                var end = _find_crlf(self._buf, 0)
                if end < 0:
                    if len(self._buf) > 1024:
                        raise Error("http: chunk size line too long")
                    return
                var size = 0
                var digits = 0
                for i in range(end):
                    var b = self._buf[i]
                    var v: Int
                    if b >= UInt8(ord("0")) and b <= UInt8(ord("9")):
                        v = Int(b - UInt8(ord("0")))
                    elif b >= UInt8(ord("a")) and b <= UInt8(ord("f")):
                        v = Int(b - UInt8(ord("a"))) + 10
                    elif b >= UInt8(ord("A")) and b <= UInt8(ord("F")):
                        v = Int(b - UInt8(ord("A"))) + 10
                    elif b == UInt8(ord(";")) or b == 0x20 or b == 0x09:
                        break  # chunk extensions are ignored
                    else:
                        raise Error("http: bad chunk size")
                    size = size * 16 + v
                    digits += 1
                    if digits > 8:
                        raise Error("http: chunk too large")
                if digits == 0:
                    raise Error("http: bad chunk size")
                self._consume(end + 2)
                if size == 0:
                    self._state = _TRAILERS
                else:
                    self._remaining = size
                    self._state = _CHUNK_DATA
            elif self._state == _CHUNK_DATA:
                var n = min(self._remaining, len(self._buf))
                self._take_body(n)
                self._remaining -= n
                if self._remaining > 0:
                    return
                self._state = _CHUNK_CRLF
            elif self._state == _CHUNK_CRLF:
                if len(self._buf) < 2:
                    return
                if self._buf[0] != 0x0D or self._buf[1] != 0x0A:
                    raise Error("http: missing CRLF after chunk")
                self._consume(2)
                self._state = _CHUNK_SIZE
            elif self._state == _TRAILERS:
                var end = _find_crlf(self._buf, 0)
                if end < 0:
                    if len(self._buf) > MAX_HEAD_LEN:
                        raise Error("http: trailers too long")
                    return
                self._consume(end + 2)
                if end == 0:
                    self._state = _DONE
            else:
                return

    def _parse_head(mut self) raises -> Bool:
        var end = -1
        for i in range(len(self._buf) - 3):
            if (
                self._buf[i] == 0x0D
                and self._buf[i + 1] == 0x0A
                and self._buf[i + 2] == 0x0D
                and self._buf[i + 3] == 0x0A
            ):
                end = i
                break
        if end < 0:
            if len(self._buf) > MAX_HEAD_LEN:
                raise Error("http: response header too long")
            return False
        var head = String(from_utf8_lossy=Span(self._buf)[0:end])
        self._consume(end + 4)
        var lines = head.split("\r\n")
        var status_line = lines[0]
        if not status_line.startswith("HTTP/1."):
            raise Error("http: bad status line")
        var parts = status_line.split(" ", 2)
        if len(parts) < 2 or parts[1].byte_length() != 3:
            raise Error("http: bad status line")
        var status = 0
        for b in parts[1].as_bytes():
            if b < UInt8(ord("0")) or b > UInt8(ord("9")):
                raise Error("http: bad status code")
            status = status * 10 + Int(b - UInt8(ord("0")))
        if status < 100:
            raise Error("http: bad status code")
        var headers = List[Tuple[String, String]]()
        for i in range(1, len(lines)):
            var line = lines[i]
            if line.startswith(" ") or line.startswith("\t"):
                raise Error("http: obsolete header line folding")
            var colon = line.find(":")
            if colon <= 0:
                raise Error("http: bad header line")
            var name = String(line[byte=0:colon])
            if not _is_token(name):
                raise Error("http: bad header name")
            var value = _trim(line[byte = colon + 1 :])
            headers.append((_ascii_lower(name), value^))
        if status < 200 and status != 101:
            # 1xx interim responses precede the real one.
            return True
        self._response.status = status
        self._response.reason = String(parts[2]) if len(parts) > 2 else ""
        self._response.headers = headers^
        self._choose_framing(status)
        return True

    def _choose_framing(mut self, status: Int) raises:
        if self._no_body or status == 204 or status == 304 or status < 200:
            self._state = _DONE
            return
        # RFC 9112 6.3: Transfer-Encoding overrides Content-Length.
        var te = self._response.header("transfer-encoding")
        if case .Some(coding) = te:
            var codings = _ascii_lower(coding).split(",")
            if _trim(codings[len(codings) - 1]) == "chunked":
                self._state = _CHUNK_SIZE
            else:
                self._state = _UNTIL_EOF
            return
        var length = -1
        for h in self._response.headers:
            if h[0] != "content-length":
                continue
            var v = 0
            var text = h[1]
            if text.byte_length() == 0 or text.byte_length() > 12:
                raise Error("http: bad Content-Length")
            for b in text.as_bytes():
                if b < UInt8(ord("0")) or b > UInt8(ord("9")):
                    raise Error("http: bad Content-Length")
                v = v * 10 + Int(b - UInt8(ord("0")))
            if length >= 0 and v != length:
                raise Error("http: conflicting Content-Length")
            length = v
        if length > MAX_BODY_LEN:
            raise Error("http: response body too large")
        if length >= 0:
            self._remaining = length
            self._state = _LENGTH if length > 0 else _DONE
        else:
            self._state = _UNTIL_EOF


struct HttpClient(Movable):
    """Sends HTTPS requests, verifying servers against a `RootStore`."""

    var roots: RootStore
    """The trusted root certificates."""

    def __init__(out self, var roots: RootStore):
        """Creates a client."""
        self.roots = roots^

    @staticmethod
    def system() raises -> HttpClient:
        """Creates a client that trusts the system CA bundle."""
        return HttpClient(RootStore.load())

    def request(
        self,
        method: String,
        url: String,
        headers: List[Tuple[String, String]],
        body: Span[UInt8, _],
        timeout_ms: Int = 30000,
    ) raises -> HttpResponse:
        """Sends one request on a new connection and reads the response."""
        var deadline = monotonic_ms() + timeout_ms
        var u = parse_url(url)
        var request = List[UInt8]()
        encode_request(method, u, headers, body, request)
        var conn = TlsConn.connect(u.host, u.port, self.roots, timeout_ms)
        conn.write(Span(request))
        var parser = ResponseParser(method)
        while not parser.is_complete():
            var left = deadline - monotonic_ms()
            if left <= 0:
                raise Error("http: request timed out")
            var data = conn.read(left)
            if len(data) == 0:
                parser.finish()
                break
            parser.feed(Span(data))
        conn.close()
        return parser.take_response()

    def get(
        self,
        url: String,
        headers: List[Tuple[String, String]] = [],
        timeout_ms: Int = 30000,
    ) raises -> HttpResponse:
        """Sends a GET request."""
        var empty = List[UInt8]()
        return self.request("GET", url, headers, Span(empty), timeout_ms)
