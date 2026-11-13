from nethernet.wire import hex_decode, hex_encode
from rfc8448 import (
    CERTIFICATE,
    CERTIFICATE_VERIFY,
    CLIENT_AP_IV,
    CLIENT_AP_KEY,
    CLIENT_AP_TRAFFIC,
    CLIENT_FINISHED,
    CLIENT_HELLO,
    CLIENT_HS_IV,
    CLIENT_HS_KEY,
    CLIENT_HS_TRAFFIC,
    CLIENT_VERIFY_DATA,
    EARLY_SECRET,
    ENCRYPTED_EXTENSIONS,
    EXPORTER_MASTER,
    HANDSHAKE_SECRET,
    HASH_CH_CF,
    HASH_CH_SF,
    HASH_CH_SH,
    MASTER_SECRET,
    RESUMPTION_MASTER,
    SERVER_AP_IV,
    SERVER_AP_KEY,
    SERVER_AP_TRAFFIC,
    SERVER_FINISHED,
    SERVER_HELLO,
    SERVER_HS_IV,
    SERVER_HS_KEY,
    SERVER_HS_TRAFFIC,
    SERVER_VERIFY_DATA,
    SHARED_SECRET,
)
from std.testing import TestSuite, assert_equal, assert_raises
from tls.hkdf import HashKind
from tls.key_schedule import (
    CipherSuite,
    KeySchedule,
    TLS_AES_128_GCM_SHA256,
    TLS_AES_256_GCM_SHA384,
    finished_verify_data,
    next_traffic_secret,
    traffic_keys,
)


def _cat(parts: List[String]) raises -> List[UInt8]:
    var out = List[UInt8]()
    for p in parts:
        out += hex_decode(p)
    return out^


def _hex(data: List[UInt8]) -> String:
    return hex_encode(Span(data))


def test_rfc8448_full_key_schedule() raises:
    var suite = CipherSuite(TLS_AES_128_GCM_SHA256)
    var h = suite.hash()
    var ks = KeySchedule(h)
    assert_equal(hex_encode(ks.secret()), EARLY_SECRET)

    var hello = _cat([CLIENT_HELLO, SERVER_HELLO])
    assert_equal(_hex(h.hash(Span(hello))), HASH_CH_SH)
    var shared = hex_decode(SHARED_SECRET)
    var hs = ks.enter_handshake(Span(shared), Span(h.hash(Span(hello))))
    assert_equal(hex_encode(ks.secret()), HANDSHAKE_SECRET)
    assert_equal(_hex(hs[0]), CLIENT_HS_TRAFFIC)
    assert_equal(_hex(hs[1]), SERVER_HS_TRAFFIC)

    var shk = traffic_keys(suite, Span(hs[1]))
    assert_equal(_hex(shk.key), SERVER_HS_KEY)
    assert_equal(_hex(shk.iv), SERVER_HS_IV)
    var chk = traffic_keys(suite, Span(hs[0]))
    assert_equal(_hex(chk.key), CLIENT_HS_KEY)
    assert_equal(_hex(chk.iv), CLIENT_HS_IV)

    var to_cv = _cat(
        [
            CLIENT_HELLO,
            SERVER_HELLO,
            ENCRYPTED_EXTENSIONS,
            CERTIFICATE,
            CERTIFICATE_VERIFY,
        ]
    )
    var sf = finished_verify_data(h, Span(hs[1]), Span(h.hash(Span(to_cv))))
    assert_equal(_hex(sf), SERVER_VERIFY_DATA)

    var to_sf = to_cv.copy()
    to_sf += hex_decode(SERVER_FINISHED)
    var sf_hash = h.hash(Span(to_sf))
    assert_equal(_hex(sf_hash), HASH_CH_SF)
    var ap = ks.enter_master(Span(sf_hash))
    assert_equal(hex_encode(ks.secret()), MASTER_SECRET)
    assert_equal(_hex(ap[0]), CLIENT_AP_TRAFFIC)
    assert_equal(_hex(ap[1]), SERVER_AP_TRAFFIC)
    var exporter = h.derive_secret(ks.secret(), "exp master", Span(sf_hash))
    assert_equal(_hex(exporter), EXPORTER_MASTER)

    var sak = traffic_keys(suite, Span(ap[1]))
    assert_equal(_hex(sak.key), SERVER_AP_KEY)
    assert_equal(_hex(sak.iv), SERVER_AP_IV)
    var cak = traffic_keys(suite, Span(ap[0]))
    assert_equal(_hex(cak.key), CLIENT_AP_KEY)
    assert_equal(_hex(cak.iv), CLIENT_AP_IV)

    var cf = finished_verify_data(h, Span(hs[0]), Span(sf_hash))
    assert_equal(_hex(cf), CLIENT_VERIFY_DATA)
    var to_cf = to_sf.copy()
    to_cf += hex_decode(CLIENT_FINISHED)
    var cf_hash = h.hash(Span(to_cf))
    assert_equal(_hex(cf_hash), HASH_CH_CF)
    var res = h.derive_secret(ks.secret(), "res master", Span(cf_hash))
    assert_equal(_hex(res), RESUMPTION_MASTER)


def test_cipher_suites() raises:
    var a = CipherSuite(TLS_AES_128_GCM_SHA256)
    var b = CipherSuite(TLS_AES_256_GCM_SHA384)
    assert_equal(a.key_len(), 16)
    assert_equal(b.key_len(), 32)
    assert_equal(String(a), "TLS_AES_128_GCM_SHA256")
    assert_equal(String(b), "TLS_AES_256_GCM_SHA384")
    assert_equal(b.hash().size(), 48)
    with assert_raises(contains="unsupported cipher suite"):
        _ = CipherSuite(0x1303)


def test_sha384_traffic_keys_have_aes256_sizes() raises:
    var suite = CipherSuite(TLS_AES_256_GCM_SHA384)
    var ks = KeySchedule(suite.hash())
    assert_equal(len(ks.secret()), 48)
    var secret = List[UInt8](length=48, fill=7)
    var keys = traffic_keys(suite, Span(secret))
    assert_equal(len(keys.key), 32)
    assert_equal(len(keys.iv), 12)
    var next = next_traffic_secret(suite.hash(), Span(secret))
    assert_equal(len(next), 48)


def test_traffic_update_label() raises:
    # "traffic upd" is HKDF-Expand-Label(secret, "traffic upd", "", HashLen).
    var h = HashKind.SHA256
    var secret = hex_decode(CLIENT_AP_TRAFFIC)
    var empty = List[UInt8]()
    assert_equal(
        _hex(next_traffic_secret(h, Span(secret))),
        _hex(h.expand_label(Span(secret), "traffic upd", Span(empty), 32)),
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
