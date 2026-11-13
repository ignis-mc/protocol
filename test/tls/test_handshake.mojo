from nethernet.wire import bytes_of, hex_decode, hex_encode
from rfc8448 import (
    CERTIFICATE,
    CLIENT_HELLO,
    ENCRYPTED_EXTENSIONS,
    SERVER_HELLO,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from tls.handshake import (
    GROUP_X25519,
    KeyShareEntry,
    ServerHello,
    certificate_verify_content,
    check_certificate_request,
    check_new_session_ticket,
    client_hello_extension_types,
    encode_client_hello,
    encode_empty_certificate,
    has_downgrade_sentinel,
    hello_retry_request_random,
    is_certificate_verify_scheme,
    is_ip_literal,
    parse_alpn,
    parse_certificate,
    parse_certificate_verify,
    parse_encrypted_extensions,
    parse_extensions,
)
from tls.hkdf import HashKind


def test_hello_retry_request_random_is_sha256_of_name() raises:
    assert_equal(
        hex_encode(Span(hello_retry_request_random())),
        hex_encode(Span(HashKind.SHA256.hash(bytes_of("HelloRetryRequest")))),
    )


def test_encode_client_hello_exact_bytes() raises:
    var out = List[UInt8]()
    var random = List[UInt8](length=32, fill=0xAA)
    var sid = List[UInt8](length=32, fill=0xBB)
    var shares: List[KeyShareEntry] = [
        KeyShareEntry(GROUP_X25519, List[UInt8](length=32, fill=9))
    ]
    var groups: List[UInt16] = [0x001D, 0x0017]
    encode_client_hello(
        out, Span(random), Span(sid), "a.b.", groups, shares, bytes_of("ck")
    )
    var want = String(
        "010000c7",  # client_hello
        "0303",
        "aa" * 32,
        "20",
        "bb" * 32,
        "000413011302",
        "0100",
        "007a",  # extensions length
        "000000080006000003612e62",  # server_name a.b
        "000b00020100",  # ec_point_formats
        "000a00060004001d0017",  # supported_groups
        "000d0012001008040403080505030806040105010601",  # signatures
        "0010000b000908687474702f312e31",  # ALPN http/1.1
        "002b0003020304",  # supported_versions
        "002c00040002636b",  # cookie "ck"
        "003300260024001d0020",
        "09" * 32,  # key_share
    )
    assert_equal(hex_encode(Span(out)), want)
    var types = client_hello_extension_types(Span(out))
    assert_equal(len(types), 8)
    assert_equal(types[6], 44)


def test_client_hello_extension_types_of_rfc8448() raises:
    var types = client_hello_extension_types(Span(hex_decode(CLIENT_HELLO)))
    var want: List[UInt16] = [0, 0xFF01, 10, 0x23, 51, 43, 13, 45, 28]
    assert_equal(len(types), len(want))
    for i in range(len(want)):
        assert_equal(types[i], want[i])


def test_server_hello_rfc8448() raises:
    var msg = hex_decode(SERVER_HELLO)
    var sh = ServerHello(Span(msg)[4:])
    assert_equal(sh.cipher_suite, 0x1301)
    assert_false(sh.is_hello_retry_request())
    assert_equal(sh.selected_version().value(), 0x0304)
    var share = sh.key_share().value().copy()
    assert_equal(share.group, GROUP_X25519)
    assert_equal(len(share.key_exchange), 32)
    assert_false(sh.cookie())


def test_server_hello_rejects_malformed() raises:
    var msg = hex_decode(SERVER_HELLO)
    var body = List[UInt8](Span(msg)[4:])
    body.append(0)
    with assert_raises(contains="decode_error"):
        _ = ServerHello(Span(body))
    with assert_raises(contains="short read"):
        _ = ServerHello(Span(msg)[4:40])


def test_duplicate_extensions_are_illegal() raises:
    var exts = hex_decode("002b00020304002b00020304")
    with assert_raises(contains="illegal_parameter: duplicate"):
        _ = parse_extensions(Span(exts))


def test_encrypted_extensions_rfc8448() raises:
    var msg = hex_decode(ENCRYPTED_EXTENSIONS)
    var exts = parse_encrypted_extensions(Span(msg)[4:])
    assert_equal(len(exts), 3)
    assert_equal(exts[0].ext_type, 10)
    assert_equal(exts[1].ext_type, 28)
    assert_equal(exts[2].ext_type, 0)


def test_certificate_parsing() raises:
    var msg = hex_decode(CERTIFICATE)
    var chain = parse_certificate(Span(msg)[4:])
    assert_equal(len(chain), 1)
    assert_equal(chain[0][0], 0x30)  # a DER SEQUENCE
    var empty = hex_decode("00000000")
    with assert_raises(contains="no certificate"):
        _ = parse_certificate(Span(empty))
    var ctx = hex_decode("0101000000")
    with assert_raises(contains="illegal_parameter"):
        _ = parse_certificate(Span(ctx))
    var zero_len = hex_decode("00000005000000" + "0000")
    with assert_raises(contains="empty certificate"):
        _ = parse_certificate(Span(zero_len))


def test_certificate_verify_content_layout() raises:
    var h = List[UInt8](length=32, fill=0xEE)
    var c = certificate_verify_content(Span(h))
    assert_equal(len(c), 64 + 33 + 1 + 32)
    assert_equal(c[0], 0x20)
    assert_equal(c[63], 0x20)
    assert_equal(c[64], UInt8(ord("T")))
    assert_equal(c[64 + 33], 0)
    assert_equal(c[len(c) - 1], 0xEE)
    var cv = parse_certificate_verify(Span(hex_decode("0804000201ff")))
    assert_equal(cv.scheme, 0x0804)
    assert_equal(len(cv.signature), 2)
    with assert_raises(contains="trailing"):
        _ = parse_certificate_verify(Span(hex_decode("0804000101ff")))
    with assert_raises(contains="empty signature"):
        _ = parse_certificate_verify(Span(hex_decode("08040000")))


def test_scheme_and_sentinel_predicates() raises:
    assert_true(is_certificate_verify_scheme(0x0804))
    assert_true(is_certificate_verify_scheme(0x0403))
    assert_false(is_certificate_verify_scheme(0x0401))
    assert_false(is_certificate_verify_scheme(0x0201))
    var r = List[UInt8](length=32, fill=0)
    assert_false(has_downgrade_sentinel(Span(r)))
    var marker = bytes_of("DOWNGRD")
    for i in range(7):
        r[24 + i] = marker[i]
    r[31] = 1
    assert_true(has_downgrade_sentinel(Span(r)))
    r[31] = 0
    assert_true(has_downgrade_sentinel(Span(r)))
    r[31] = 2
    assert_false(has_downgrade_sentinel(Span(r)))


def test_ip_literals() raises:
    assert_true(is_ip_literal("10.0.0.1"))
    assert_true(is_ip_literal("::1"))
    assert_false(is_ip_literal("login.live.com"))
    assert_false(is_ip_literal("20ca2.playfabapi.com"))
    assert_false(is_ip_literal(""))


def test_alpn_and_misc_messages() raises:
    assert_equal(
        parse_alpn(Span(hex_decode("0009" + "08687474702f312e31"))),
        "http/1.1",
    )
    with assert_raises(contains="bad ALPN"):
        _ = parse_alpn(Span(hex_decode("000a" + "08687474702f312e31")))
    with assert_raises(contains="bad ALPN"):
        _ = parse_alpn(Span(hex_decode("000100")))
    var ctx = check_certificate_request(
        Span(hex_decode("00" + "0008" + "000d000400020804"))
    )
    assert_equal(len(ctx), 0)
    with assert_raises(contains="missing_extension"):
        _ = check_certificate_request(Span(hex_decode("000000")))
    var cert = List[UInt8]()
    encode_empty_certificate(cert, Span(List[UInt8]()))
    assert_equal(hex_encode(Span(cert)), "0b00000400000000")
    check_new_session_ticket(
        Span(hex_decode("0000003c" + "01020304" + "0100" + "0001aa" + "0000"))
    )
    with assert_raises(contains="empty ticket"):
        check_new_session_ticket(
            Span(hex_decode("0000003c" + "01020304" + "00" + "0000" + "0000"))
        )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
