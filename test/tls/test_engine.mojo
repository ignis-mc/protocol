from nethernet.wire import hex_decode, hex_encode
from rfc8448 import (
    CERTIFICATE_VERIFY,
    CLIENT_ALERT_RECORD,
    CLIENT_APP_PAYLOAD,
    CLIENT_APP_RECORD,
    CLIENT_FINISHED_RECORD,
    CLIENT_HELLO,
    CLIENT_HELLO_RECORD,
    CLIENT_PRIVATE_KEY,
    NEW_SESSION_TICKET_RECORD,
    SERVER_ALERT_RECORD,
    SERVER_APP_PAYLOAD,
    SERVER_APP_RECORD,
    SERVER_HELLO_RECORD,
    SERVER_HS_RECORD,
)
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from tls.engine import ENTROPY_LEN, ClientEngine
from tls.handshake import GROUP_X25519, SIG_RSA_PSS_RSAE_SHA256
from tls.verifier import CertificateVerifier


struct _Recorder(CertificateVerifier):
    """Accepts everything and remembers what it was asked."""

    var chain_len: Int
    var host: String
    var scheme: UInt16
    var message_len: Int
    var fail_chain: Bool
    var fail_signature: Bool

    def __init__(
        out self, fail_chain: Bool = False, fail_signature: Bool = False
    ):
        self.chain_len = 0
        self.host = String()
        self.scheme = 0
        self.message_len = 0
        self.fail_chain = fail_chain
        self.fail_signature = fail_signature

    def verify_certificate(
        mut self, chain: List[List[UInt8]], host: String
    ) raises:
        if self.fail_chain:
            raise Error("x509: certificate has expired")
        self.chain_len = len(chain)
        self.host = host

    def verify_signature(
        self, scheme: UInt16, message: List[UInt8], signature: List[UInt8]
    ) raises:
        if self.fail_signature:
            raise Error("rsa: bad signature")
        if len(message) != 64 + 34 + 32:
            raise Error("unexpected CertificateVerify content length")


def _trace_entropy() raises -> List[UInt8]:
    var e = List[UInt8](length=64, fill=0)
    e += hex_decode(CLIENT_PRIVATE_KEY)
    e += List[UInt8](length=48, fill=0x5A)
    return e^


def _trace_engine(var v: _Recorder) raises -> ClientEngine[_Recorder]:
    var e = ClientEngine[_Recorder]("server", v^, Span(_trace_entropy()))
    var empty = List[UInt8]()
    e._start_with_client_hello(hex_decode(CLIENT_HELLO), Span(empty))
    return e^


def test_rfc8448_full_connection() raises:
    var e = _trace_engine(_Recorder())
    var hello = e.take_output()
    hello[2] = 0x01  # the trace's first record uses version 0x0301
    assert_equal(hex_encode(Span(hello)), CLIENT_HELLO_RECORD)
    e.feed(Span(hex_decode(SERVER_HELLO_RECORD)))
    assert_false(e.has_output())
    e.feed(Span(hex_decode(SERVER_HS_RECORD)))
    assert_true(e.is_connected())
    assert_equal(String(e.cipher_suite().value()), "TLS_AES_128_GCM_SHA256")
    assert_equal(e.group(), GROUP_X25519)
    assert_equal(hex_encode(Span(e.take_output())), CLIENT_FINISHED_RECORD)
    e.feed(Span(hex_decode(NEW_SESSION_TICKET_RECORD)))
    e.feed(Span(hex_decode(SERVER_APP_RECORD)))
    assert_equal(
        hex_encode(Span(e.take_application_data())), SERVER_APP_PAYLOAD
    )
    e.write(Span(hex_decode(CLIENT_APP_PAYLOAD)))
    assert_equal(hex_encode(Span(e.take_output())), CLIENT_APP_RECORD)
    e.feed(Span(hex_decode(SERVER_ALERT_RECORD)))
    assert_true(e.peer_closed())
    e.close()
    assert_equal(hex_encode(Span(e.take_output())), CLIENT_ALERT_RECORD)


def test_rfc8448_byte_at_a_time() raises:
    var e = _trace_engine(_Recorder())
    _ = e.take_output()
    var stream = hex_decode(SERVER_HELLO_RECORD)
    stream += hex_decode(SERVER_HS_RECORD)
    stream += hex_decode(NEW_SESSION_TICKET_RECORD)
    stream += hex_decode(SERVER_APP_RECORD)
    for i in range(len(stream)):
        e.feed(Span(stream)[i : i + 1])
    assert_equal(hex_encode(Span(e.take_output())), CLIENT_FINISHED_RECORD)
    assert_equal(
        hex_encode(Span(e.take_application_data())), SERVER_APP_PAYLOAD
    )


def test_rfc8448_tampered_flight_sends_bad_record_mac() raises:
    var e = _trace_engine(_Recorder())
    _ = e.take_output()
    e.feed(Span(hex_decode(SERVER_HELLO_RECORD)))
    var flight = hex_decode(SERVER_HS_RECORD)
    flight[100] ^= 0x80
    with assert_raises(contains="bad_record_mac"):
        e.feed(Span(flight))
    # The alert goes out under the client handshake key: one 24-byte record.
    var out = e.take_output()
    assert_equal(len(out), 24)
    assert_equal(out[0], 23)
    with assert_raises(contains="bad_record_mac"):
        e.feed(Span(flight))


def test_rfc8448_rejected_chain_is_bad_certificate() raises:
    var e = _trace_engine(_Recorder(fail_chain=True))
    _ = e.take_output()
    e.feed(Span(hex_decode(SERVER_HELLO_RECORD)))
    with assert_raises(contains="certificate_expired"):
        e.feed(Span(hex_decode(SERVER_HS_RECORD)))


def test_rfc8448_bad_signature_is_decrypt_error() raises:
    var e = _trace_engine(_Recorder(fail_signature=True))
    _ = e.take_output()
    e.feed(Span(hex_decode(SERVER_HELLO_RECORD)))
    with assert_raises(contains="decrypt_error"):
        e.feed(Span(hex_decode(SERVER_HS_RECORD)))


def test_rfc8448_app_data_before_finished_is_rejected() raises:
    var e = _trace_engine(_Recorder())
    _ = e.take_output()
    with assert_raises(contains="unexpected_message"):
        e.feed(Span(hex_decode(SERVER_APP_RECORD)))


def test_rfc8448_ccs_is_ignored_during_handshake() raises:
    var e = _trace_engine(_Recorder())
    _ = e.take_output()
    var ccs: List[UInt8] = [20, 3, 3, 0, 1, 1]
    e.feed(Span(ccs))
    e.feed(Span(hex_decode(SERVER_HELLO_RECORD)))
    e.feed(Span(ccs))
    e.feed(Span(hex_decode(SERVER_HS_RECORD)))
    assert_true(e.is_connected())
    with assert_raises(contains="unexpected_message"):
        e.feed(Span(ccs))


def test_entropy_must_be_long_enough() raises:
    var short = List[UInt8](length=ENTROPY_LEN - 1, fill=1)
    with assert_raises(contains="entropy"):
        _ = ClientEngine[_Recorder]("x", _Recorder(), Span(short))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
