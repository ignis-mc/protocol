from net.dns import (
    encode_query,
    lookup_hosts,
    parse_nameservers,
    parse_response,
)
from nethernet.os.addr import SocketAddr
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_false, assert_raises

# Response to a query for a.example (id 0x1234): a CNAME to b.example
# (compressed) and an A record 93.184.216.34.
comptime _HEADER = "123481800001000200000000"
comptime _QUESTION = "0161076578616d706c6500" + "00010001"
comptime _CNAME = "c00c000500010000003c0004" + "0162c00e"
comptime _A = "c02700010001" + "0000003c00045db8d822"


def test_encode_query() raises:
    var q = encode_query(0x1234, "a.example.")
    assert_equal(hex_encode(Span(q)), "123401000001000000000000" + _QUESTION)
    with assert_raises(contains="bad label"):
        _ = encode_query(1, "a..b")
    with assert_raises(contains="bad name length"):
        _ = encode_query(1, "")
    var long_label = String("x") * 64
    with assert_raises(contains="bad label"):
        _ = encode_query(1, long_label)


def test_parse_response_follows_cname_answers() raises:
    var msg = hex_decode(_HEADER + _QUESTION + _CNAME + _A)
    var ips = parse_response(Span(msg), 0x1234)
    assert_equal(len(ips), 1)
    assert_equal(String(SocketAddr(ips[0], 0)), "93.184.216.34:0")


def test_parse_response_errors() raises:
    var msg = hex_decode(_HEADER + _QUESTION + _CNAME + _A)
    with assert_raises(contains="id mismatch"):
        _ = parse_response(Span(msg), 0x1235)
    var nx = hex_decode("123481830001000000000000" + _QUESTION)
    with assert_raises(contains="does not exist"):
        _ = parse_response(Span(nx), 0x1234)
    var tc = hex_decode("123483800001000000000000" + _QUESTION)
    with assert_raises(contains="truncated"):
        _ = parse_response(Span(tc), 0x1234)
    var query = hex_decode("123401000001000000000000" + _QUESTION)
    with assert_raises(contains="not a response"):
        _ = parse_response(Span(query), 0x1234)
    var short = hex_decode(_HEADER + _QUESTION + "c00c0001")
    with assert_raises(contains="short read"):
        _ = parse_response(Span(short), 0x1234)


def test_parse_nameservers() raises:
    var conf = String(
        "# comment\nsearch lan\nnameserver 10.43.0.10\nnameserver"
        " fe80::1\noptions ndots:5\nnameserver 1.1.1.1\n"
    )
    var servers = parse_nameservers(conf)
    assert_equal(len(servers), 2)
    assert_equal(String(SocketAddr(servers[0], 53)), "10.43.0.10:53")
    assert_equal(String(SocketAddr(servers[1], 53)), "1.1.1.1:53")


def test_lookup_hosts() raises:
    var hosts = String(
        "127.0.0.1 localhost\n::1 ip6-localhost myhost\n10.0.0.5  MyHost"
        " alias # comment\n"
    )
    assert_equal(
        String(SocketAddr(lookup_hosts(hosts, "myhost").value(), 0)),
        "10.0.0.5:0",
    )
    assert_equal(
        String(SocketAddr(lookup_hosts(hosts, "ALIAS").value(), 0)),
        "10.0.0.5:0",
    )
    assert_false(lookup_hosts(hosts, "comment"))
    assert_false(lookup_hosts(hosts, "nothere"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
