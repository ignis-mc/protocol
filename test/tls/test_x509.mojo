from nethernet.crypto.der import DER_GENERALIZED_TIME, DER_UTC_TIME
from nethernet.wire import bytes_of, hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from tls.roots import pem_decode_certificates
from tls.rsa import HASH_SHA256, HASH_SHA384
from tls.x509 import (
    KEY_EC_P256,
    KEY_RSA,
    KU_DIGITAL_SIGNATURE,
    KU_KEY_CERT_SIGN,
    SIG_ECDSA,
    SIG_RSA_PKCS1,
    SIG_RSA_PSS,
    days_from_civil,
    parse_certificate,
    parse_time,
)


def _pem(path: String) raises -> List[List[UInt8]]:
    var data: List[UInt8]
    with open(path, "r") as f:
        data = f.read_bytes()
    return pem_decode_certificates(Span(data))


def _utc(text: StringSpan) raises -> Int:
    var b = bytes_of(text)
    return parse_time(DER_UTC_TIME, Span(b))


def _gen(text: StringSpan) raises -> Int:
    var b = bytes_of(text)
    return parse_time(DER_GENERALIZED_TIME, Span(b))


def test_days_from_civil() raises:
    assert_equal(days_from_civil(1970, 1, 1), 0)
    assert_equal(days_from_civil(2000, 3, 1), 11017)
    assert_equal(days_from_civil(1969, 12, 31), -1)
    assert_equal(days_from_civil(2026, 11, 13), 20770)


def test_times() raises:
    assert_equal(_utc("261026003123Z"), 1792974683)
    assert_equal(_gen("20261026003123Z"), 1792974683)
    # UTCTime years 50-99 are 19YY, 00-49 are 20YY.
    assert_equal(_utc("491231235959Z"), 2524607999)
    assert_equal(_utc("500101000000Z"), -631152000)
    assert_equal(_gen("99991231235959Z"), 253402300799)
    assert_equal(_gen("20240229000000Z"), 1709164800)
    for bad in [
        "20230229000000Z",  # not a leap year
        "20261326000000Z",
        "20261026240000Z",
        "20261026003160Z",
        "2026102600312Z",
        "20261026003123+0000",
        "2026102600312.Z",
    ]:
        with assert_raises():
            _ = _gen(bad)
    with assert_raises():
        _ = _utc("2610260031Z")
    with assert_raises():
        _ = _utc("261026003123")


def test_real_ecdsa_leaf() raises:
    var chain = _pem("test/tls/testdata/chains/sisu.xboxlive.com.pem")
    var leaf = parse_certificate(Span(chain[0]))
    assert_equal(leaf.version, 3)
    assert_equal(leaf.common_name, "*.xboxlive.com")
    assert_equal(leaf.key.kind, KEY_EC_P256)
    assert_equal(len(leaf.key.point), 65)
    assert_equal(leaf.signature_algorithm.kind, SIG_ECDSA)
    assert_equal(leaf.signature_algorithm.hash, HASH_SHA384)
    assert_equal(leaf.not_before, 1792974683)
    assert_equal(leaf.not_after, 1810081883)
    assert_true(leaf.has_basic_constraints)
    assert_false(leaf.is_ca)
    if case .Some(ku) = leaf.key_usage:
        assert_equal(ku, KU_DIGITAL_SIGNATURE)
    else:
        raise Error("keyUsage missing")
    assert_true(leaf.has_ext_key_usage)
    assert_true(leaf.eku_server_auth)
    assert_false(leaf.eku_any)
    assert_true(leaf.has_san)
    assert_equal(len(leaf.dns_names), 1)
    assert_equal(leaf.dns_names[0], "*.xboxlive.com")
    assert_false(leaf.unhandled_critical)
    var aki = leaf.authority_key_id.value().copy()
    assert_equal(
        hex_encode(Span(aki)), "389b2ce59c4f9dc21461eae944108d70494bea5b"
    )
    var issuer = parse_certificate(Span(chain[1]))
    assert_true(issuer.is_ca)
    assert_equal(issuer.max_path_len.value(), 0)
    assert_equal(issuer.key_usage.value() & KU_KEY_CERT_SIGN, KU_KEY_CERT_SIGN)
    var ski = issuer.subject_key_id.value().copy()
    assert_equal(hex_encode(Span(ski)), hex_encode(Span(aki)))
    assert_true(issuer.subject == leaf.issuer)
    assert_equal(len(leaf.der), len(chain[0]))
    assert_true(len(leaf.tbs) < len(leaf.der))
    # An ECDSA P-384 signature over the leaf, DER-encoded.
    assert_equal(leaf.signature[0], 0x30)


def test_real_rsa_leaf() raises:
    var chain = _pem("test/tls/testdata/chains/xsts.auth.xboxlive.com.pem")
    var leaf = parse_certificate(Span(chain[0]))
    assert_equal(leaf.key.kind, KEY_RSA)
    assert_equal(String(leaf.key), "RSA-2048")
    assert_equal(leaf.signature_algorithm.kind, SIG_RSA_PKCS1)
    assert_equal(leaf.signature_algorithm.hash, HASH_SHA384)
    assert_equal(len(leaf.signature), 512)  # RSA-4096 issuer
    assert_equal(len(leaf.dns_names), 6)
    assert_equal(leaf.dns_names[1], "xsts.auth.xboxlive.com")
    assert_equal(leaf.common_name, "ssl-xsts.auth.xboxlive.com")


def test_pss_parameters() raises:
    var leaf = parse_certificate(
        Span(_pem("test/tls/testdata/synthetic/leaf_pss.pem")[0])
    )
    assert_equal(leaf.signature_algorithm.kind, SIG_RSA_PSS)
    assert_equal(leaf.signature_algorithm.hash, HASH_SHA384)
    assert_equal(leaf.signature_algorithm.salt_length, 20)
    var inter = parse_certificate(
        Span(_pem("test/tls/testdata/synthetic/int_pss.pem")[0])
    )
    assert_equal(inter.signature_algorithm.kind, SIG_RSA_PSS)
    assert_equal(inter.signature_algorithm.hash, HASH_SHA256)
    assert_equal(inter.signature_algorithm.salt_length, 32)


def test_extension_flags() raises:
    comptime syn = "test/tls/testdata/synthetic/"
    var crit = parse_certificate(Span(_pem(String(syn, "leaf_crit.pem"))[0]))
    assert_true(crit.unhandled_critical)
    var nc = parse_certificate(Span(_pem(String(syn, "int_nc.pem"))[0]))
    assert_equal(len(nc.permitted_dns), 1)
    assert_equal(nc.permitted_dns[0], "example.com")
    assert_false(nc.unhandled_critical)
    var leaf = parse_certificate(Span(_pem(String(syn, "leaf.pem"))[0]))
    assert_equal(len(leaf.ip_addresses), 1)
    assert_equal(hex_encode(Span(leaf.ip_addresses[0])), "c0000207")
    var client = parse_certificate(
        Span(_pem(String(syn, "leaf_client.pem"))[0])
    )
    assert_true(client.has_ext_key_usage)
    assert_false(client.eku_server_auth)
    var no_san = parse_certificate(Span(_pem(String(syn, "leaf_cn.pem"))[0]))
    assert_false(no_san.has_san)


def test_truncated_and_corrupted_input_raises_or_parses() raises:
    # Every strict prefix fails cleanly; single-byte corruptions never
    # crash (they either raise or produce some certificate).
    var der = _pem("test/tls/testdata/chains/sisu.xboxlive.com.pem")[0].copy()
    for n in range(len(der)):
        with assert_raises():
            _ = parse_certificate(Span(der)[0:n])
    var parsed = 0
    for i in range(len(der)):
        var bad = der.copy()
        bad[i] ^= 0x80
        try:
            _ = parse_certificate(Span(bad))
            parsed += 1
        except:
            pass
    assert_true(parsed > 0)
    var longer = der.copy()
    longer.append(0)
    with assert_raises():
        _ = parse_certificate(Span(longer))


def test_duplicate_extension_rejected() raises:
    # A real certificate whose subjectKeyIdentifier OID (55 1d 0e) is
    # renamed to keyUsage's (55 1d 0f), which it already has.
    var der = _pem("test/tls/testdata/chains/sisu.xboxlive.com.pem")[0].copy()
    var hits = 0
    for i in range(len(der) - 4):
        if (
            der[i] == 0x06
            and der[i + 1] == 0x03
            and der[i + 2] == 0x55
            and der[i + 3] == 0x1D
            and der[i + 4] == 0x0E
        ):
            der[i + 4] = 0x0F
            hits += 1
    assert_equal(hits, 1)
    with assert_raises(contains="duplicate"):
        _ = parse_certificate(Span(der))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
