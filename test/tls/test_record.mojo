from nethernet.wire import hex_decode, hex_encode
from nethernet.crypto.gcm import AesGcm
from rfc8448 import (
    ALERT_PAYLOAD,
    CLIENT_AP_TRAFFIC,
    CLIENT_ALERT_RECORD,
    CLIENT_APP_PAYLOAD,
    CLIENT_APP_RECORD,
    CLIENT_FINISHED,
    CLIENT_FINISHED_RECORD,
    CLIENT_HELLO,
    CLIENT_HELLO_RECORD,
    CLIENT_HS_TRAFFIC,
    NEW_SESSION_TICKET,
    NEW_SESSION_TICKET_RECORD,
    SERVER_AP_TRAFFIC,
    SERVER_ALERT_RECORD,
    SERVER_APP_PAYLOAD,
    SERVER_APP_RECORD,
    SERVER_HS_PAYLOAD,
    SERVER_HS_RECORD,
    SERVER_HS_TRAFFIC,
)
from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from tls.key_schedule import (
    CipherSuite,
    TLS_AES_128_GCM_SHA256,
    traffic_keys,
)
from tls.record import (
    CONTENT_ALERT,
    CONTENT_APPLICATION_DATA,
    CONTENT_HANDSHAKE,
    MAX_PLAINTEXT_LEN,
    RecordBuffer,
    RecordProtection,
    put_plaintext_record,
)


def _protection(secret_hex: StringSpan) raises -> RecordProtection:
    var secret = hex_decode(secret_hex)
    var keys = traffic_keys(CipherSuite(TLS_AES_128_GCM_SHA256), Span(secret))
    return RecordProtection(keys)


def test_rfc8448_plaintext_client_hello_record() raises:
    var out = List[UInt8]()
    var ch = hex_decode(CLIENT_HELLO)
    put_plaintext_record(out, CONTENT_HANDSHAKE, Span(ch))
    # RFC 8448 uses legacy_record_version 0x0301 for the first record.
    out[2] = 0x01
    assert_equal(hex_encode(Span(out)), CLIENT_HELLO_RECORD)


def test_rfc8448_open_server_handshake_flight() raises:
    var p = _protection(SERVER_HS_TRAFFIC)
    var record = hex_decode(SERVER_HS_RECORD)
    var opened = p.open(Span(record))
    assert_equal(opened.content_type, CONTENT_HANDSHAKE)
    assert_equal(hex_encode(Span(opened.content)), SERVER_HS_PAYLOAD)
    assert_equal(Int(p.sequence()), 1)


def test_rfc8448_seal_client_finished() raises:
    var p = _protection(CLIENT_HS_TRAFFIC)
    var out = List[UInt8]()
    var fin = hex_decode(CLIENT_FINISHED)
    p.seal(CONTENT_HANDSHAKE, Span(fin), out)
    assert_equal(hex_encode(Span(out)), CLIENT_FINISHED_RECORD)


def test_rfc8448_application_traffic() raises:
    var server = _protection(SERVER_AP_TRAFFIC)
    var nst = server.open(Span(hex_decode(NEW_SESSION_TICKET_RECORD)))
    assert_equal(nst.content_type, CONTENT_HANDSHAKE)
    assert_equal(hex_encode(Span(nst.content)), NEW_SESSION_TICKET)
    var data = server.open(Span(hex_decode(SERVER_APP_RECORD)))
    assert_equal(data.content_type, CONTENT_APPLICATION_DATA)
    assert_equal(hex_encode(Span(data.content)), SERVER_APP_PAYLOAD)
    var alert = server.open(Span(hex_decode(SERVER_ALERT_RECORD)))
    assert_equal(alert.content_type, CONTENT_ALERT)
    assert_equal(hex_encode(Span(alert.content)), ALERT_PAYLOAD)

    var client = _protection(CLIENT_AP_TRAFFIC)
    var out = List[UInt8]()
    client.seal(
        CONTENT_APPLICATION_DATA, Span(hex_decode(CLIENT_APP_PAYLOAD)), out
    )
    assert_equal(hex_encode(Span(out)), CLIENT_APP_RECORD)
    out.clear()
    client.seal(CONTENT_ALERT, Span(hex_decode(ALERT_PAYLOAD)), out)
    assert_equal(hex_encode(Span(out)), CLIENT_ALERT_RECORD)


def test_tampered_record_is_bad_record_mac() raises:
    var record = hex_decode(SERVER_HS_RECORD)
    record[40] ^= 1
    var p = _protection(SERVER_HS_TRAFFIC)
    with assert_raises(contains="bad_record_mac"):
        _ = p.open(Span(record))
    # A tampered header is authenticated as additional data.
    var record2 = hex_decode(SERVER_HS_RECORD)
    record2[2] = 0x01
    var p2 = _protection(SERVER_HS_TRAFFIC)
    with assert_raises(contains="bad_record_mac"):
        _ = p2.open(Span(record2))


def test_wrong_sequence_number_fails() raises:
    var p = _protection(SERVER_AP_TRAFFIC)
    with assert_raises(contains="bad_record_mac"):
        _ = p.open(Span(hex_decode(SERVER_APP_RECORD)))


def test_padding_is_removed_and_all_padding_rejected() raises:
    var tx = _protection(CLIENT_AP_TRAFFIC)
    var rx = _protection(CLIENT_AP_TRAFFIC)
    # Content type 0 with "hi" 0x17 0 0 as content: inner = "hi" 17 00 00 00.
    var inner: List[UInt8] = [0x68, 0x69, CONTENT_APPLICATION_DATA, 0, 0]
    var out = List[UInt8]()
    tx.seal(0, Span(inner), out)
    var opened = rx.open(Span(out))
    assert_equal(opened.content_type, CONTENT_APPLICATION_DATA)
    assert_equal(len(opened.content), 2)
    assert_equal(opened.content[1], 0x69)
    out.clear()
    var zeros = List[UInt8](length=10, fill=0)
    tx.seal(0, Span(zeros), out)
    with assert_raises(contains="unexpected_message"):
        _ = rx.open(Span(out))


def test_oversized_content_is_rejected() raises:
    var tx = _protection(CLIENT_AP_TRAFFIC)
    var big = List[UInt8](length=MAX_PLAINTEXT_LEN + 1, fill=1)
    var out = List[UInt8]()
    with assert_raises(contains="too long"):
        tx.seal(CONTENT_APPLICATION_DATA, Span(big), out)
    with assert_raises(contains="too long"):
        put_plaintext_record(out, CONTENT_HANDSHAKE, Span(big))
    # Seal 2^14 + 2 inner bytes by hand: the receiver must refuse them.
    var secret = hex_decode(CLIENT_AP_TRAFFIC)
    var keys = traffic_keys(CipherSuite(TLS_AES_128_GCM_SHA256), Span(secret))
    var gcm = AesGcm(Span(keys.key))
    var inner = List[UInt8](length=MAX_PLAINTEXT_LEN + 2, fill=1)
    var length = len(inner) + 16
    var record: List[UInt8] = [
        CONTENT_APPLICATION_DATA,
        3,
        3,
        UInt8(length >> 8),
        UInt8(length & 0xFF),
    ]
    var header = record.copy()
    gcm.seal(Span(keys.iv), Span(header), Span(inner), record)
    var rx = _protection(CLIENT_AP_TRAFFIC)
    with assert_raises(contains="record_overflow"):
        _ = rx.open(Span(record))


def test_unprotected_record_after_keys_is_rejected() raises:
    var p = _protection(SERVER_HS_TRAFFIC)
    var record = hex_decode(SERVER_HS_RECORD)
    record[0] = CONTENT_HANDSHAKE
    with assert_raises(contains="unexpected_message"):
        _ = p.open(Span(record))


def test_record_buffer_reassembles_byte_by_byte() raises:
    var stream = hex_decode(SERVER_HS_RECORD)
    stream += hex_decode(NEW_SESSION_TICKET_RECORD)
    var buf = RecordBuffer()
    var records = List[List[UInt8]]()
    for i in range(len(stream)):
        buf.feed(Span(stream)[i : i + 1])
        while True:
            var r = buf.next()
            if case .Some(rec) = r:
                records.append(rec.copy())
            else:
                break
    assert_equal(len(records), 2)
    assert_equal(hex_encode(Span(records[0])), SERVER_HS_RECORD)
    assert_equal(hex_encode(Span(records[1])), NEW_SESSION_TICKET_RECORD)
    assert_equal(buf.buffered(), 0)


def test_record_buffer_limits() raises:
    var buf = RecordBuffer()
    var header: List[UInt8] = [CONTENT_APPLICATION_DATA, 3, 3, 0x41, 0x01]
    buf.feed(Span(header))
    with assert_raises(contains="record_overflow"):
        _ = buf.next()
    var buf2 = RecordBuffer()
    var bad: List[UInt8] = [99, 3, 3, 0, 1, 0]
    buf2.feed(Span(bad))
    with assert_raises(contains="unexpected_message"):
        _ = buf2.next()
    var buf3 = RecordBuffer()
    var exact: List[UInt8] = [CONTENT_APPLICATION_DATA, 3, 3, 0x41, 0x00]
    buf3.feed(Span(exact))
    assert_true(not buf3.next())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
