from http.client import (
    HttpResponse,
    ResponseParser,
    Url,
    encode_request,
    parse_url,
)
from nethernet.wire import bytes_of, string_of
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _parse_all(method: StringSpan, text: StringSpan) raises -> HttpResponse:
    var p = ResponseParser(method)
    p.feed(text.as_bytes())
    if not p.is_complete():
        p.finish()
    return p.take_response()


def _parse_bytewise(
    method: StringSpan, text: StringSpan
) raises -> HttpResponse:
    var p = ResponseParser(method)
    var data = bytes_of(text)
    for i in range(len(data)):
        p.feed(Span(data)[i : i + 1])
    if not p.is_complete():
        p.finish()
    return p.take_response()


def test_parse_url() raises:
    var u = parse_url(
        "https://Client.Discovery.minecraft-services.net/api/v1.0/x?y=1#frag"
    )
    assert_equal(u.host, "client.discovery.minecraft-services.net")
    assert_equal(u.port, 443)
    assert_equal(u.target, "/api/v1.0/x?y=1")
    var v = parse_url("HTTPS://example.com:8443")
    assert_equal(v.port, 8443)
    assert_equal(v.target, "/")
    assert_equal(String(v), "https://example.com:8443/")
    var w = parse_url("https://example.com?q")
    assert_equal(w.target, "/?q")


def test_parse_url_rejects() raises:
    with assert_raises(contains="only https"):
        _ = parse_url("http://example.com/")
    with assert_raises(contains="user info"):
        _ = parse_url("https://user:pw@example.com/")
    with assert_raises(contains="IPv6"):
        _ = parse_url("https://[::1]/")
    with assert_raises(contains="bad port"):
        _ = parse_url("https://example.com:0/")
    with assert_raises(contains="bad port"):
        _ = parse_url("https://example.com:65536/")
    with assert_raises(contains="bad port"):
        _ = parse_url("https://example.com:4a/")
    with assert_raises(contains="missing host"):
        _ = parse_url("https:///path")
    with assert_raises(contains="invalid characters"):
        _ = parse_url("https://example.com/a b")


def test_encode_get() raises:
    var out = List[UInt8]()
    var headers: List[Tuple[String, String]] = [
        ("Accept", "application/json"),
        ("accept-encoding", "gzip"),
        ("Content-Length", "99"),
    ]
    var empty = List[UInt8]()
    encode_request(
        "GET", parse_url("https://a.example/p?q=1"), headers, Span(empty), out
    )
    assert_equal(
        string_of(Span(out)),
        (
            "GET /p?q=1 HTTP/1.1\r\nHost: a.example\r\nAccept:"
            " application/json\r\nUser-Agent: ignis-protocol/0.1\r\n"
            "Accept-Encoding: identity\r\nConnection: close\r\n\r\n"
        ),
    )


def test_encode_post_with_body_and_port() raises:
    var out = List[UInt8]()
    var headers: List[Tuple[String, String]] = [
        ("User-Agent", "bot/1"),
        ("Content-Type", "application/json"),
    ]
    var body = bytes_of('{"a":1}')
    encode_request(
        "POST", parse_url("https://a.example:444/x"), headers, Span(body), out
    )
    assert_equal(
        string_of(Span(out)),
        (
            "POST /x HTTP/1.1\r\nHost: a.example:444\r\nUser-Agent: bot/1\r\n"
            "Content-Type: application/json\r\nAccept-Encoding: identity\r\n"
            'Connection: close\r\nContent-Length: 7\r\n\r\n{"a":1}'
        ),
    )
    out.clear()
    var empty = List[UInt8]()
    var none = List[Tuple[String, String]]()
    encode_request(
        "POST", parse_url("https://a.example/"), none, Span(empty), out
    )
    assert_true("Content-Length: 0\r\n" in string_of(Span(out)))


def test_encode_rejects_header_injection() raises:
    var out = List[UInt8]()
    var empty = List[UInt8]()
    var bad_value: List[Tuple[String, String]] = [("X", "a\r\nEvil: 1")]
    with assert_raises(contains="invalid value"):
        encode_request(
            "GET", parse_url("https://a/"), bad_value, Span(empty), out
        )
    var bad_name: List[Tuple[String, String]] = [("X Y", "1")]
    with assert_raises(contains="invalid header name"):
        encode_request(
            "GET", parse_url("https://a/"), bad_name, Span(empty), out
        )
    var none = List[Tuple[String, String]]()
    with assert_raises(contains="invalid method"):
        encode_request("GE T", parse_url("https://a/"), none, Span(empty), out)


comptime _CL_RESPONSE = (
    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 5\r\n"
    "X-Multi: a\r\nx-multi: b\r\n\r\nhelloEXTRA"
)


def test_content_length() raises:
    var r = _parse_all("GET", _CL_RESPONSE)
    assert_equal(r.status, 200)
    assert_equal(r.reason, "OK")
    assert_equal(r.text(), "hello")
    assert_equal(r.header("CONTENT-TYPE").value(), "text/plain")
    assert_equal(r.header("x-multi").value(), "a")
    assert_false(r.header("missing"))
    assert_equal(len(r.headers), 4)
    var b = _parse_bytewise("GET", _CL_RESPONSE)
    assert_equal(b.text(), "hello")


comptime _CHUNKED = (
    "HTTP/1.1 201 Created\r\nTransfer-Encoding: chunked\r\nContent-Length:"
    " 3\r\n\r\n4;ext=1\r\nWiki\r\n5\r\npedia\r\nE\r\n in\r\n\r\nchunks.\r\n"
    "0\r\nTrailer: x\r\n\r\n"
)


def test_chunked_overrides_content_length() raises:
    var r = _parse_all("GET", _CHUNKED)
    assert_equal(r.status, 201)
    assert_equal(r.text(), "Wikipedia in\r\n\r\nchunks.")
    var b = _parse_bytewise("GET", _CHUNKED)
    assert_equal(b.text(), "Wikipedia in\r\n\r\nchunks.")


def test_interim_responses_are_skipped() raises:
    var r = _parse_all(
        "POST",
        (
            "HTTP/1.1 100 Continue\r\n\r\nHTTP/1.1 302 Found\r\nLocation:"
            " https://x/\r\nContent-Length: 0\r\n\r\n"
        ),
    )
    assert_equal(r.status, 302)
    assert_equal(r.header("location").value(), "https://x/")
    assert_equal(len(r.body), 0)


def test_bodyless_responses() raises:
    var head = ResponseParser("HEAD")
    head.feed(
        StringSpan("HTTP/1.1 200 OK\r\nContent-Length: 50\r\n\r\n").as_bytes()
    )
    assert_true(head.is_complete())
    var nc = ResponseParser("GET")
    nc.feed(StringSpan("HTTP/1.1 204 No Content\r\n\r\n").as_bytes())
    assert_true(nc.is_complete())


def test_body_until_close() raises:
    var p = ResponseParser("GET")
    p.feed(StringSpan("HTTP/1.0 200 OK\r\n\r\nabc").as_bytes())
    p.feed(StringSpan("def").as_bytes())
    assert_false(p.is_complete())
    p.finish()
    assert_equal(p.take_response().text(), "abcdef")


def test_truncated_responses_fail() raises:
    var p = ResponseParser("GET")
    p.feed(
        StringSpan(
            "HTTP/1.1 200 OK\r\nContent-Length: 10\r\n\r\nabc"
        ).as_bytes()
    )
    with assert_raises(contains="closed before"):
        p.finish()
    var q = ResponseParser("GET")
    q.feed(
        StringSpan(
            "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nab"
        ).as_bytes()
    )
    with assert_raises(contains="closed before"):
        q.finish()
    var h = ResponseParser("GET")
    h.feed(StringSpan("HTTP/1.1 200 OK\r\nContent-Le").as_bytes())
    with assert_raises(contains="closed before"):
        h.finish()


def test_malformed_responses_fail() raises:
    with assert_raises(contains="bad status line"):
        _ = _parse_all("GET", "HTTP/2 200 OK\r\n\r\n")
    with assert_raises(contains="bad status"):
        _ = _parse_all("GET", "HTTP/1.1 2x0 OK\r\n\r\n")
    with assert_raises(contains="conflicting Content-Length"):
        _ = _parse_all(
            "GET",
            "HTTP/1.1 200 OK\r\nContent-Length: 1\r\nContent-Length: 2\r\n\r\n",
        )
    with assert_raises(contains="bad Content-Length"):
        _ = _parse_all("GET", "HTTP/1.1 200 OK\r\nContent-Length: -1\r\n\r\n")
    with assert_raises(contains="bad chunk size"):
        _ = _parse_all(
            "GET",
            "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\nzz\r\n",
        )
    with assert_raises(contains="missing CRLF"):
        _ = _parse_all(
            "GET",
            "HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n1\r\nabc",
        )
    with assert_raises(contains="line folding"):
        _ = _parse_all("GET", "HTTP/1.1 200 OK\r\nA: b\r\n c\r\n\r\n")
    with assert_raises(contains="chunk too large"):
        _ = _parse_all(
            "GET",
            (
                "HTTP/1.1 200 OK\r\nTransfer-Encoding:"
                " chunked\r\n\r\n123456789\r\n"
            ),
        )


def test_oversized_head_fails() raises:
    var p = ResponseParser("GET")
    var junk = List[UInt8](length=70000, fill=UInt8(ord("a")))
    with assert_raises(contains="too long"):
        p.feed(Span(junk))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
