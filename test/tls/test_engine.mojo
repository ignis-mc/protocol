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
from fake_server import FakeServer
from nethernet.wire import bytes_of, put_u16, put_u8, string_of
from tls.engine import ENTROPY_LEN, ClientEngine
from tls.handshake import (
    GROUP_SECP256R1,
    GROUP_X25519,
    SIG_RSA_PKCS1_SHA256,
    SIG_RSA_PSS_RSAE_SHA256,
)
from tls.key_schedule import TLS_AES_128_GCM_SHA256, TLS_AES_256_GCM_SHA384
from tls.record import (
    CONTENT_ALERT,
    CONTENT_APPLICATION_DATA,
    CONTENT_HANDSHAKE,
)
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
        if len(message) != 64 + 34 + 32 and len(message) != 64 + 34 + 48:
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


# Handshakes against the scripted server ------------------------------------


def _engine(
    host: String = "example.com",
    groups: List[UInt16] = [GROUP_X25519, GROUP_SECP256R1],
) raises -> ClientEngine[_Recorder]:
    var entropy = List[UInt8]()
    for i in range(ENTROPY_LEN):
        entropy.append(UInt8((i * 7 + 3) & 0xFF))
    var e = ClientEngine[_Recorder](host, _Recorder(), Span(entropy), groups)
    e.start()
    return e^


def _connect(
    mut srv: FakeServer,
    groups: List[UInt16] = [GROUP_X25519, GROUP_SECP256R1],
) raises -> ClientEngine[_Recorder]:
    var e = _engine(groups=groups)
    var reply = srv.respond(Span(e.take_output()))
    if srv.hrr_sent and len(srv.hellos) == 1:
        e.feed(Span(reply))
        reply = srv.respond(Span(e.take_output()))
    e.feed(Span(reply))
    srv.finish(Span(e.take_output()))
    return e^


def _expect_failure(mut srv: FakeServer, alert: StringSpan) raises:
    var e = _engine()
    var reply = srv.respond(Span(e.take_output()))
    with assert_raises(contains=String(alert)):
        e.feed(Span(reply))
    # A fatal alert is queued for the server.
    assert_true(e.has_output())


def _ext(t: UInt16, body: List[UInt8]) -> List[UInt8]:
    var out = List[UInt8]()
    put_u16(out, t)
    put_u16(out, UInt16(len(body)))
    out += body.copy()
    return out^


def _cat(var head: List[UInt8], tail: StringSpan) -> List[UInt8]:
    head += bytes_of(tail)
    return head^


def test_client_hello_contents() raises:
    var srv = FakeServer()
    var e = _engine()
    _ = srv.respond(Span(e.take_output()))
    ref hello = srv.hellos[0]
    assert_equal(hello.server_name, "example.com")
    assert_equal(len(hello.session_id), 32)
    assert_equal(len(hello.suites), 2)
    assert_equal(hello.suites[0], TLS_AES_128_GCM_SHA256)
    assert_equal(hello.suites[1], TLS_AES_256_GCM_SHA384)
    assert_equal(len(hello.shares), 2)
    assert_equal(hello.shares[0][0], GROUP_X25519)
    assert_equal(len(hello.shares[0][1]), 32)
    assert_equal(hello.shares[1][0], GROUP_SECP256R1)
    assert_equal(len(hello.shares[1][1]), 65)
    var want: List[UInt16] = [0, 11, 10, 13, 16, 43, 51]
    assert_equal(len(hello.ext_types), len(want))
    for i in range(len(want)):
        assert_equal(hello.ext_types[i], want[i])


def test_ip_literal_has_no_sni() raises:
    var srv = FakeServer()
    var e = _engine(host="192.0.2.1")
    _ = srv.respond(Span(e.take_output()))
    assert_equal(srv.hellos[0].server_name, "")


def test_handshake_x25519_aes128_and_app_data() raises:
    var srv = FakeServer()
    srv.ee_extensions = _ext(16, _cat([0, 9, 8], "http/1.1"))
    var e = _connect(srv)
    assert_true(srv.client_finished_ok)
    assert_true(e.is_connected())
    assert_equal(e.alpn(), "http/1.1")
    assert_equal(e.group(), GROUP_X25519)
    e.feed(Span(srv.seal(CONTENT_APPLICATION_DATA, bytes_of("pong"))))
    assert_equal(string_of(Span(e.take_application_data())), "pong")
    e.write(bytes_of("ping"))
    var got = srv.open(Span(e.take_output()))
    assert_equal(len(got), 1)
    assert_equal(string_of(Span(got[0].content)), "ping")


def test_handshake_p256_aes256() raises:
    var srv = FakeServer()
    srv.group = GROUP_SECP256R1
    srv.suite = TLS_AES_256_GCM_SHA384
    var e = _connect(srv)
    assert_true(srv.client_finished_ok)
    assert_equal(String(e.cipher_suite().value()), "TLS_AES_256_GCM_SHA384")
    assert_equal(e.group(), GROUP_SECP256R1)
    e.write(bytes_of("x"))
    assert_equal(len(srv.open(Span(e.take_output()))), 1)


def test_compat_mode_sends_change_cipher_spec() raises:
    var srv = FakeServer()
    var e = _engine()
    var reply = srv.respond(Span(e.take_output()))
    e.feed(Span(reply))
    var out = e.take_output()
    assert_equal(out[0], 20)  # change_cipher_spec before the Finished
    assert_equal(out[5], 1)
    assert_equal(out[6], 23)


def test_hello_retry_request_for_p256_with_cookie() raises:
    var srv = FakeServer()
    srv.group = GROUP_SECP256R1
    srv.hrr_group = GROUP_SECP256R1
    srv.hrr_cookie = bytes_of("cookie!")
    var e = _connect(srv, groups=[GROUP_X25519])
    assert_true(srv.client_finished_ok)
    assert_equal(e.group(), GROUP_SECP256R1)
    assert_equal(len(srv.hellos), 2)
    assert_equal(len(srv.hellos[0].shares), 1)
    assert_equal(srv.hellos[1].shares[0][0], GROUP_SECP256R1)
    assert_equal(string_of(Span(srv.hellos[1].cookie)), "cookie!")
    # Random and session id are reused in the second ClientHello.
    assert_equal(
        hex_encode(Span(srv.hellos[0].session_id)),
        hex_encode(Span(srv.hellos[1].session_id)),
    )


def test_hello_retry_request_cookie_only() raises:
    var srv = FakeServer()
    srv.hrr_cookie = bytes_of("c")
    srv.suite = TLS_AES_256_GCM_SHA384
    var e = _connect(srv)
    assert_true(srv.client_finished_ok)
    assert_equal(len(srv.hellos[1].shares), 2)


def test_hello_retry_request_for_offered_group_is_illegal() raises:
    var srv = FakeServer()
    srv.hrr_group = GROUP_X25519
    _expect_failure(srv, "illegal_parameter")


def test_hello_retry_request_for_unknown_group_is_illegal() raises:
    var srv = FakeServer()
    srv.hrr_group = 0x0018  # secp384r1, not supported
    _expect_failure(srv, "illegal_parameter")


def test_second_hello_retry_request_is_rejected() raises:
    var srv = FakeServer()
    srv.hrr_cookie = bytes_of("c")
    var e = _engine()
    e.feed(Span(srv.respond(Span(e.take_output()))))
    srv.hrr_sent = False
    var again = srv.respond(Span(e.take_output()))
    with assert_raises(contains="second HelloRetryRequest"):
        e.feed(Span(again))


def test_server_hello_validation() raises:
    var sentinel = FakeServer()
    for i in range(7):
        sentinel.random[24 + i] = bytes_of("DOWNGRD")[i]
    sentinel.random[31] = 1
    _expect_failure(sentinel, "downgrade sentinel")
    var tls12 = FakeServer()
    tls12.version = 0x0303
    _expect_failure(tls12, "protocol_version")
    var sid = FakeServer()
    sid.echo_session_id = False
    _expect_failure(sid, "session id not echoed")
    var suite = FakeServer()
    suite.suite = 0x1303
    _expect_failure(suite, "cipher suite not offered")
    var psk = FakeServer()
    psk.sh_extra = _ext(41, [0, 0])
    _expect_failure(psk, "unsupported_extension")
    var sni = FakeServer()
    sni.sh_extra = _ext(0, [])
    _expect_failure(sni, "illegal_parameter: extension not allowed")


def test_encrypted_extensions_validation() raises:
    var ks = FakeServer()
    ks.ee_extensions = _ext(51, [0, 0x1D])
    _expect_failure(ks, "illegal_parameter")
    var unsolicited = FakeServer()
    unsolicited.ee_extensions = _ext(28, [0x40, 0x01])
    _expect_failure(unsolicited, "unsupported_extension")
    var h2 = FakeServer()
    h2.ee_extensions = _ext(16, _cat([0, 3, 2], "h2"))
    _expect_failure(h2, "ALPN protocol not offered")


def test_pkcs1_certificate_verify_is_illegal() raises:
    var srv = FakeServer()
    srv.cv_scheme = SIG_RSA_PKCS1_SHA256
    _expect_failure(srv, "CertificateVerify scheme")


def test_bad_server_finished_is_decrypt_error() raises:
    var srv = FakeServer()
    srv.corrupt_finished = True
    _expect_failure(srv, "decrypt_error")


def test_flight_split_into_one_byte_records() raises:
    var srv = FakeServer()
    srv.split_flight = True
    var e = _connect(srv)
    assert_true(srv.client_finished_ok)
    assert_true(e.is_connected())


def test_server_hello_must_end_its_record() raises:
    var srv = FakeServer()
    srv.trailing_after_server_hello = True
    _expect_failure(srv, "key change")


def test_certificate_request_gets_empty_certificate() raises:
    var srv = FakeServer()
    srv.cert_request = True
    var e = _connect(srv)
    assert_true(srv.got_empty_certificate)
    assert_true(srv.client_finished_ok)
    assert_true(e.is_connected())


def test_key_update_requested() raises:
    var srv = FakeServer()
    var e = _connect(srv)
    var ku: List[UInt8] = [24, 0, 0, 1, 1]
    e.feed(Span(srv.seal(CONTENT_HANDSHAKE, Span(ku))))
    srv.update_write_key()
    e.feed(Span(srv.seal(CONTENT_APPLICATION_DATA, bytes_of("after"))))
    assert_equal(string_of(Span(e.take_application_data())), "after")
    # The client answered with KeyUpdate(update_not_requested) ...
    var reply = srv.open(Span(e.take_output()))
    assert_equal(len(reply), 1)
    assert_equal(reply[0].content_type, CONTENT_HANDSHAKE)
    assert_equal(hex_encode(Span(reply[0].content)), "1800000100")
    # ... and writes under its next key afterwards.
    srv.update_read_key()
    e.write(bytes_of("new key"))
    assert_equal(
        string_of(Span(srv.open(Span(e.take_output()))[0].content)), "new key"
    )
    var bad: List[UInt8] = [24, 0, 0, 1, 2]
    with assert_raises(contains="illegal_parameter"):
        e.feed(Span(srv.seal(CONTENT_HANDSHAKE, Span(bad))))


def test_new_session_ticket_is_ignored() raises:
    var srv = FakeServer()
    var e = _connect(srv)
    var nst: List[UInt8] = [
        4,
        0,
        0,
        16,
        0,
        0,
        0,
        60,
        1,
        2,
        3,
        4,
        1,
        9,
        0,
        2,
        7,
        7,
        0,
        0,
    ]
    e.feed(Span(srv.seal(CONTENT_HANDSHAKE, Span(nst))))
    assert_false(e.has_output())
    var bad: List[UInt8] = [4, 0, 0, 3, 0, 0, 0]
    with assert_raises(contains="decode_error"):
        e.feed(Span(srv.seal(CONTENT_HANDSHAKE, Span(bad))))


def test_post_handshake_certificate_request_is_unexpected() raises:
    var srv = FakeServer()
    var e = _connect(srv)
    var cr: List[UInt8] = [13, 0, 0, 3, 0, 0, 0]
    with assert_raises(contains="unexpected_message"):
        e.feed(Span(srv.seal(CONTENT_HANDSHAKE, Span(cr))))


def test_peer_alerts() raises:
    var srv = FakeServer()
    var e = _connect(srv)
    var fatal: List[UInt8] = [2, 40]
    with assert_raises(contains="peer sent alert handshake_failure"):
        e.feed(Span(srv.seal(CONTENT_ALERT, Span(fatal))))
    assert_false(e.has_output())  # no alert is sent back
    var srv2 = FakeServer()
    var e2 = _connect(srv2)
    var close: List[UInt8] = [1, 0]
    e2.feed(Span(srv2.seal(CONTENT_ALERT, Span(close))))
    assert_true(e2.peer_closed())
    assert_equal(len(e2.take_application_data()), 0)
    # Writing is still allowed until we close.
    e2.write(bytes_of("bye"))
    e2.close()
    var tail = srv2.open(Span(e2.take_output()))
    assert_equal(len(tail), 2)
    assert_equal(tail[1].content_type, CONTENT_ALERT)
    with assert_raises(contains="closed for writing"):
        e2.write(bytes_of("more"))


def test_unprotected_alert_after_keys_is_rejected() raises:
    var srv = FakeServer()
    var e = _connect(srv)
    var plain: List[UInt8] = [21, 3, 3, 0, 2, 1, 0]
    with assert_raises(contains="unprotected alert close_notify"):
        e.feed(Span(plain))


def test_write_before_handshake_fails() raises:
    var e = _engine()
    with assert_raises(contains="handshake not complete"):
        e.write(bytes_of("x"))


def test_large_write_is_split_into_records() raises:
    var srv = FakeServer()
    var e = _connect(srv)
    var big = List[UInt8](length=40000, fill=0x61)
    e.write(Span(big))
    var records = srv.open(Span(e.take_output()))
    assert_equal(len(records), 3)
    assert_equal(len(records[0].content), 16384)
    assert_equal(
        len(records[0].content)
        + len(records[1].content)
        + len(records[2].content),
        40000,
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
