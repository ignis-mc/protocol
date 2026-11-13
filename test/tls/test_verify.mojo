from nethernet.wire import hex_decode
from std.os.path import exists
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)
from tls.roots import RootStore, pem_decode_certificates
from tls.verify import (
    PeerKey,
    verify_chain,
    verify_handshake_signature,
    verify_hostname,
)
from tls.x509 import KEY_EC_P256, KEY_EC_P384, KEY_RSA, parse_certificate

comptime _CHAINS = "test/tls/testdata/chains/"
comptime _SYN = "test/tls/testdata/synthetic/"
# 2026-11-13 18:54:55 UTC, when the chains were captured.
comptime CAPTURED = 1794596095
# 2027-01-01 00:00:00 UTC, inside the synthetic certificates' validity.
comptime SYN_NOW = 1798761600

comptime _HOSTS: List[StaticString] = [
    "login.live.com",
    "user.auth.xboxlive.com",
    "device.auth.xboxlive.com",
    "sisu.xboxlive.com",
    "xsts.auth.xboxlive.com",
    "client.discovery.minecraft-services.net",
    "authorization.franchise.minecraft-services.net",
    "multiplayer.minecraft.net",
    "20ca2.playfabapi.com",
]


def _pem(path: String) raises -> List[List[UInt8]]:
    var data: List[UInt8]
    with open(path, "r") as f:
        data = f.read_bytes()
    return pem_decode_certificates(Span(data))


def _roots(path: String) raises -> RootStore:
    var data: List[UInt8]
    with open(path, "r") as f:
        data = f.read_bytes()
    return RootStore.from_pem(Span(data))


def _chain(host: StringSpan) raises -> List[List[UInt8]]:
    return _pem(String(_CHAINS, host, ".pem"))


def _syn(*names: StaticString) raises -> List[List[UInt8]]:
    # Concatenates synthetic certificates into one chain, in order.
    var out = List[List[UInt8]]()
    for name in names:
        for der in _pem(String(_SYN, name, ".pem")):
            out.append(der.copy())
    return out^


def _syn_roots() raises -> RootStore:
    var store = _roots(String(_SYN, "root.pem"))
    store.add(parse_certificate(Span(_syn("root384")[0])))
    return store^


def _fails(
    chain: List[List[UInt8]],
    host: StringSpan,
    now: Int,
    roots: RootStore,
    expected: StringSpan,
) raises:
    # verify_chain must raise, with `expected` in the message.
    try:
        _ = verify_chain(chain, host, now, roots)
    except e:
        var msg = String(e)
        if msg.find(expected) < 0:
            raise Error(t"wrong error: {msg} (wanted {expected})")
        return
    raise Error(t"chain for {host} verified; wanted failure: {expected}")


def test_real_chains_verify() raises:
    var roots = _roots(String(_CHAINS, "roots.pem"))
    assert_equal(len(roots), 2)
    for host in materialize[_HOSTS]():
        var key = verify_chain(_chain(host), host, CAPTURED, roots)
        if host == "sisu.xboxlive.com":
            assert_equal(key.kind, KEY_EC_P256)
        else:
            assert_equal(key.kind, KEY_RSA)
            assert_equal(String(key), "RSA-2048")


def test_real_chains_with_system_bundle() raises:
    if not exists("/etc/ssl/certs/ca-certificates.crt"):
        print("no system bundle; skipped")
        return
    var roots = RootStore.load()
    assert_true(len(roots) > 100)
    for host in materialize[_HOSTS]():
        _ = verify_chain(_chain(host), host, CAPTURED, roots)


def test_real_chain_order_and_extras() raises:
    # Reversed intermediates plus an unrelated certificate still verify.
    var roots = _roots(String(_CHAINS, "roots.pem"))
    var chain = _chain("multiplayer.minecraft.net")
    var shuffled = List[List[UInt8]]()
    shuffled.append(chain[0].copy())
    shuffled.append(_chain("sisu.xboxlive.com")[1].copy())
    for i in range(len(chain) - 1, 0, -1):
        shuffled.append(chain[i].copy())
    _ = verify_chain(shuffled, "multiplayer.minecraft.net", CAPTURED, roots)


def test_presented_certificate_in_store_is_an_anchor() raises:
    # Trusting only the presented "Microsoft TLS RSA Root G2" (itself
    # cross-signed by DigiCert) ends the path there.
    var chain = _chain("user.auth.xboxlive.com")
    var store = RootStore()
    store.add(parse_certificate(Span(chain[2])))
    _ = verify_chain(chain, "user.auth.xboxlive.com", CAPTURED, store)


def test_real_chain_failures() raises:
    var roots = _roots(String(_CHAINS, "roots.pem"))
    var chain = _chain("sisu.xboxlive.com")
    # Wrong host names, including wildcard edge cases.
    _fails(chain, "evil.example.com", CAPTURED, roots, "not valid for")
    _fails(chain, "xboxlive.com", CAPTURED, roots, "not valid for")
    _fails(chain, "a.sisu.xboxlive.com", CAPTURED, roots, "not valid for")
    # Expired and not yet valid.
    _fails(chain, "sisu.xboxlive.com", 1893456000, roots, "expired")
    _fails(chain, "sisu.xboxlive.com", 1700000000, roots, "not yet valid")
    # Missing intermediate.
    var leaf_only = List[List[UInt8]]()
    leaf_only.append(chain[0].copy())
    _fails(leaf_only, "sisu.xboxlive.com", CAPTURED, roots, "unknown authority")
    # Root not trusted: the RSA chains need DigiCert Global Root G2.
    var g3_only = _roots(String(_CHAINS, "roots.pem"))
    g3_only.certs = [g3_only.certs[1].copy()]
    _fails(
        _chain("login.live.com"),
        "login.live.com",
        CAPTURED,
        g3_only,
        "unknown authority",
    )


def test_tampered_signatures() raises:
    var roots = _roots(String(_CHAINS, "roots.pem"))
    for host in ["sisu.xboxlive.com", "login.live.com"]:
        # Last byte of the leaf is the last byte of its signature.
        var chain = _chain(host)
        chain[0][len(chain[0]) - 1] ^= 0x01
        _fails(chain, host, CAPTURED, roots, "signature")
        # A byte inside an intermediate's TBSCertificate (its serial).
        chain = _chain(host)
        chain[1][15] ^= 0x01
        _fails(chain, host, CAPTURED, roots, "signature")


def test_synthetic_good_chains() raises:
    var roots = _syn_roots()
    var key = verify_chain(
        _syn("leaf", "int"), "good.example.com", SYN_NOW, roots
    )
    assert_equal(key.kind, KEY_EC_P256)
    _ = verify_chain(_syn("leaf", "int"), "GOOD.Example.COM.", SYN_NOW, roots)
    _ = verify_chain(_syn("leaf", "int"), "x.wild.example.com", SYN_NOW, roots)
    _ = verify_chain(_syn("leaf", "int"), "192.0.2.7", SYN_NOW, roots)
    _ = verify_chain(
        _syn("leaf_nc_ok", "int_nc"), "good.example.com", SYN_NOW, roots
    )
    # RSASSA-PSS certificate signatures: salt 32 / SHA-256 on the
    # intermediate, salt 20 / SHA-384 on the leaf.
    key = verify_chain(
        _syn("leaf_pss", "int_pss"), "good.example.com", SYN_NOW, roots
    )
    assert_equal(key.kind, KEY_RSA)
    # P-256 leaf under a P-384 root, ecdsa-with-SHA384.
    _ = verify_chain(_syn("leaf_384"), "good.example.com", SYN_NOW, roots)


def test_synthetic_failures() raises:
    var roots = _syn_roots()
    var host = "good.example.com"
    _fails(_syn("leaf", "int"), "example.com", SYN_NOW, roots, "not valid")
    _fails(_syn("leaf", "int"), "a.b.wild.example.com", SYN_NOW, roots, "valid")
    _fails(_syn("leaf", "int"), "wild.example.com", SYN_NOW, roots, "valid")
    _fails(_syn("leaf", "int"), "192.0.2.8", SYN_NOW, roots, "not valid")
    _fails(_syn("leaf", "int"), "::1", SYN_NOW, roots, "IPv6")
    _fails(_syn("leaf_nonca", "nonca"), host, SYN_NOW, roots, "not a CA")
    _fails(
        _syn("leaf_pl", "int_under", "int_pl0"),
        host,
        SYN_NOW,
        roots,
        "path length",
    )
    _fails(_syn("leaf_noku", "int_noku"), host, SYN_NOW, roots, "may not sign")
    _fails(_syn("leaf_crit", "int"), host, SYN_NOW, roots, "critical")
    _fails(
        _syn("leaf_client", "int"),
        host,
        SYN_NOW,
        roots,
        "server authentication",
    )
    _fails(_syn("leaf_cn", "int"), host, SYN_NOW, roots, "no subjectAltName")
    _fails(_syn("leaf_nc_bad", "int_nc"), host, SYN_NOW, roots, "not permitted")
    _fails(_syn("leaf_old", "int_old"), host, SYN_NOW, roots, "expired")
    # An intermediate whose issuer is not trusted.
    var other = _roots(String(_CHAINS, "roots.pem"))
    _fails(_syn("leaf", "int"), host, SYN_NOW, other, "unknown authority")
    var empty = List[List[UInt8]]()
    _fails(empty, host, SYN_NOW, roots, "empty")


def test_signature_check_budget() raises:
    # 120 copies of an intermediate whose root is not trusted: each is a
    # candidate, so path building stops at the budget instead of trying all.
    var chain = _syn("leaf")
    var inter = _syn("int")[0].copy()
    for _ in range(120):
        chain.append(inter.copy())
    var other = _roots(String(_CHAINS, "roots.pem"))
    _fails(chain, "good.example.com", SYN_NOW, other, "too many signature")


def _sigs() raises -> Dict[String, List[UInt8]]:
    var out = Dict[String, List[UInt8]]()
    var text = open(String(_SYN, "sigs.txt"), "r").read()
    for line in text.split("\n"):
        var parts = line.split(" ")
        if len(parts) == 2:
            out[String(parts[0])] = hex_decode(parts[1])
    return out^


def _check_scheme(
    key: PeerKey,
    scheme: UInt16,
    msg: List[UInt8],
    sig: List[UInt8],
) raises:
    verify_handshake_signature(key, scheme, Span(msg), Span(sig))
    var bad = msg.copy()
    bad[70] ^= 0x20
    with assert_raises():
        verify_handshake_signature(key, scheme, Span(bad), Span(sig))


def test_handshake_signatures() raises:
    var sigs = _sigs()
    var msg = sigs["msg"].copy()
    var rsa = parse_certificate(Span(_syn("leaf_pss")[0])).key.copy()
    var p256 = parse_certificate(Span(_syn("leaf")[0])).key.copy()
    var p384 = parse_certificate(Span(_syn("root384")[0])).key.copy()
    assert_equal(p384.kind, KEY_EC_P384)
    _check_scheme(rsa, 0x0804, msg, sigs["rsa_pss_rsae_sha256"])
    _check_scheme(rsa, 0x0805, msg, sigs["rsa_pss_rsae_sha384"])
    _check_scheme(rsa, 0x0806, msg, sigs["rsa_pss_rsae_sha512"])
    _check_scheme(rsa, 0x0401, msg, sigs["rsa_pkcs1_sha256"])
    _check_scheme(rsa, 0x0501, msg, sigs["rsa_pkcs1_sha384"])
    _check_scheme(rsa, 0x0601, msg, sigs["rsa_pkcs1_sha512"])
    _check_scheme(p256, 0x0403, msg, sigs["ecdsa_secp256r1_sha256"])
    _check_scheme(p384, 0x0503, msg, sigs["ecdsa_secp384r1_sha384"])
    # Scheme / key mismatches and unknown schemes.
    var pss = sigs["rsa_pss_rsae_sha256"].copy()
    with assert_raises():
        verify_handshake_signature(rsa, 0x0805, Span(msg), Span(pss))
    with assert_raises():
        verify_handshake_signature(p256, 0x0804, Span(msg), Span(pss))
    var ec = sigs["ecdsa_secp256r1_sha256"].copy()
    with assert_raises():
        verify_handshake_signature(p256, 0x0503, Span(msg), Span(ec))
    with assert_raises():
        verify_handshake_signature(rsa, 0x0403, Span(msg), Span(ec))
    with assert_raises():
        verify_handshake_signature(p256, 0x0603, Span(msg), Span(ec))
    with assert_raises():
        verify_handshake_signature(rsa, 0x0201, Span(msg), Span(pss))


def test_hostname_rules() raises:
    var leaf = parse_certificate(Span(_syn("leaf")[0]))
    verify_hostname(leaf, "good.example.com")
    verify_hostname(leaf, "abc.wild.example.com")
    for bad in [
        "wild.example.com",
        ".wild.example.com",
        "a.b.wild.example.com",
        "good.example.com..",
        "",
        "192.0.2.07",
    ]:
        with assert_raises():
            verify_hostname(leaf, bad)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
