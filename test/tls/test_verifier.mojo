from nethernet.wire import hex_decode
from rfc8448 import (
    CERTIFICATE,
    CERTIFICATE_VERIFY,
    CLIENT_HELLO,
    CLIENT_PRIVATE_KEY,
    ENCRYPTED_EXTENSIONS,
    SERVER_HELLO,
    SERVER_HELLO_RECORD,
    SERVER_HS_RECORD,
)
from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from tls.engine import ClientEngine
from tls.handshake import (
    certificate_verify_content,
    parse_certificate,
    parse_certificate_verify,
)
from tls.hkdf import HashKind
from tls.roots import RootStore
from tls.verifier import CertificateVerifier, PkiVerifier
from tls.verify import verify_handshake_signature
from tls.x509 import PeerKey
from tls.x509 import parse_certificate as parse_x509


struct _LeafOnly(CertificateVerifier):
    """Checks the real CertificateVerify signature but trusts any leaf."""

    var key: Optional[PeerKey]

    def __init__(out self):
        self.key = None

    def verify_certificate(
        mut self, chain: List[List[UInt8]], host: String
    ) raises:
        self.key = parse_x509(Span(chain[0])).key.copy()

    def verify_signature(
        self, scheme: UInt16, message: List[UInt8], signature: List[UInt8]
    ) raises:
        verify_handshake_signature(
            self.key.value(), scheme, Span(message), Span(signature)
        )


def _trace_chain() raises -> List[List[UInt8]]:
    var cert = hex_decode(CERTIFICATE)
    return parse_certificate(Span(cert)[4:])


def test_rfc8448_certificate_verify_signature() raises:
    var chain = _trace_chain()
    assert_equal(len(chain), 1)
    var key = parse_x509(Span(chain[0])).key.copy()
    var transcript = hex_decode(CLIENT_HELLO)
    transcript += hex_decode(SERVER_HELLO)
    transcript += hex_decode(ENCRYPTED_EXTENSIONS)
    transcript += hex_decode(CERTIFICATE)
    var cv_msg = hex_decode(CERTIFICATE_VERIFY)
    var cv = parse_certificate_verify(Span(cv_msg)[4:])
    assert_equal(cv.scheme, 0x0804)
    var content = certificate_verify_content(
        Span(HashKind.SHA256.hash(Span(transcript)))
    )
    verify_handshake_signature(
        key, cv.scheme, Span(content), Span(cv.signature)
    )
    content[70] ^= 1
    with assert_raises():
        verify_handshake_signature(
            key, cv.scheme, Span(content), Span(cv.signature)
        )


def test_rfc8448_engine_with_real_signature_check() raises:
    var entropy = List[UInt8](length=64, fill=0)
    entropy += hex_decode(CLIENT_PRIVATE_KEY)
    entropy += List[UInt8](length=48, fill=1)
    var e = ClientEngine[_LeafOnly]("server", _LeafOnly(), Span(entropy))
    var empty = List[UInt8]()
    e._start_with_client_hello(hex_decode(CLIENT_HELLO), Span(empty))
    _ = e.take_output()
    e.feed(Span(hex_decode(SERVER_HELLO_RECORD)))
    e.feed(Span(hex_decode(SERVER_HS_RECORD)))
    assert_true(e.is_connected())


def test_pki_verifier_rejects_untrusted_chain() raises:
    var v = PkiVerifier(RootStore.load(), 1548000000)
    with assert_raises():
        v.verify_certificate(_trace_chain(), "server")
    var none = List[UInt8]()
    with assert_raises(contains="no verified certificate"):
        v.verify_signature(0x0804, none.copy(), none.copy())


def test_pki_verifier_empty_store_rejects() raises:
    var v = PkiVerifier(RootStore(), 1548000000)
    with assert_raises():
        v.verify_certificate(_trace_chain(), "server")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
