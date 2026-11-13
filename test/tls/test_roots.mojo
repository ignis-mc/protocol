from nethernet.wire import bytes_of
from std.os.path import exists
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from tls.roots import RootStore, pem_decode_certificates
from tls.x509 import parse_certificate


def _read(path: String) raises -> List[UInt8]:
    var data: List[UInt8]
    with open(path, "r") as f:
        data = f.read_bytes()
    return data^


def test_pem_decoding() raises:
    var pem = _read("test/tls/testdata/chains/roots.pem")
    var certs = pem_decode_certificates(Span(pem))
    assert_equal(len(certs), 2)
    assert_equal(certs[0][0], 0x30)
    # CRLF line ends and surrounding text are fine.
    var text = String(from_utf8=Span(pem))
    var crlf = bytes_of(String("junk\r\n", text.replace("\n", "\r\n")))
    assert_equal(len(pem_decode_certificates(Span(crlf))), 2)
    var none = bytes_of("no certificates here")
    assert_equal(len(pem_decode_certificates(Span(none))), 0)
    var unterminated = bytes_of("-----BEGIN CERTIFICATE-----\nMIIB\n")
    with assert_raises():
        _ = pem_decode_certificates(Span(unterminated))
    var bad = bytes_of(
        "-----BEGIN CERTIFICATE-----\nM!IB\n-----END CERTIFICATE-----\n"
    )
    with assert_raises():
        _ = pem_decode_certificates(Span(bad))


def test_from_pem_and_find() raises:
    var pem = _read("test/tls/testdata/chains/roots.pem")
    var store = RootStore.from_pem(Span(pem))
    assert_equal(len(store), 2)
    assert_equal(store.skipped, 0)
    var g2 = parse_certificate(Span(store.certs[0].der))
    assert_equal(store.find(g2).value(), 0)
    store.add(g2.copy())  # exact duplicate: ignored
    assert_equal(len(store), 2)
    # A different certificate with another key is not found.
    var leaf = parse_certificate(
        Span(
            pem_decode_certificates(
                Span(_read("test/tls/testdata/chains/login.live.com.pem"))
            )[0]
        )
    )
    assert_false(Bool(store.find(leaf)))
    # Garbage inside a block is skipped and counted; no usable cert raises.
    var junk = bytes_of(
        "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----\n"
    )
    with assert_raises():
        _ = RootStore.from_pem(Span(junk))
    var mixed = junk.copy()
    mixed += pem.copy()
    var store2 = RootStore.from_pem(Span(mixed))
    assert_equal(len(store2), 2)
    assert_equal(store2.skipped, 1)


def test_load() raises:
    with assert_raises():
        _ = RootStore.load("/nonexistent/bundle.pem")
    var store = RootStore.load("test/tls/testdata/chains/roots.pem")
    assert_equal(len(store), 2)
    if exists("/etc/ssl/certs/ca-certificates.crt"):
        var system = RootStore.load()
        print(
            "system bundle:", len(system), "anchors,", system.skipped, "skipped"
        )
        assert_true(len(system) > 100)
        assert_equal(system.skipped, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
