from minecraft.auth.nsal import (
    NSAL_DEFAULT_URL,
    default_title_request,
    parse_title_data,
    title_request,
)
from minecraft.auth.signature import auth_policy
from std.testing import TestSuite, assert_equal, assert_false, assert_true

# The public document from title.mgt.xboxlive.com, fetched 2026-11-13.
comptime DEFAULT = "test/minecraft/auth/testdata/nsal_default.json"


def _default() raises -> String:
    var text: String
    with open(DEFAULT, "r") as f:
        text = f.read()
    return text^


def test_parses_the_default_title_data() raises:
    var t = parse_title_data(_default().as_bytes())
    assert_equal(len(t.endpoints), 90)
    assert_equal(len(t.signature_policies), 3)
    assert_equal(t.signature_policies[0].max_body_bytes, 8192)
    assert_equal(t.signature_policies[1].max_body_bytes, 2147483647)
    assert_equal(t.signature_policies[2].version, 2)
    assert_equal(t.signature_policies[2].supported_algorithms[0], "ES256")


def test_matches_like_go() raises:
    var t = parse_title_data(_default().as_bytes())
    # The fqdn entry for SISU comes after the *.xboxlive.com wildcard and wins.
    var sisu = t.match("https://sisu.xboxlive.com/authorize").value().copy()
    assert_equal(sisu.relying_party, "http://sisu.xboxlive.com/")
    assert_equal(sisu.policy.max_body_bytes, 2147483647)
    var user = (
        t.match("https://user.auth.xboxlive.com/user/authenticate")
        .value()
        .copy()
    )
    assert_equal(user.relying_party, "http://xboxlive.com")
    assert_equal(user.policy.max_body_bytes, 8192)
    var pf = t.match("https://playfabapi.com/x").value().copy()
    assert_equal(pf.relying_party, "http://playfab.xboxlive.com/")
    # No policy index: the auth policy.
    assert_equal(pf.policy.version, 1)
    assert_equal(pf.policy.max_body_bytes, 0)
    # Endpoints without a relying party never match; nor do other schemes.
    assert_false(
        Bool(t.match("https://multiplayer.minecraft.net/authentication"))
    )
    assert_false(Bool(t.match("http://xboxlive.com/")))
    assert_false(
        Bool(t.match("https://20ca2.playfabapi.com/Client/LoginWithXbox"))
    )


def test_paths_ports_and_wildcards() raises:
    var t = parse_title_data(
        '{"EndPoints":[{"Protocol":"https","Host":"*.a.*.com","HostType":"wildcard","RelyingParty":"rp1"},'
        '{"Protocol":"https","Host":"x.com","HostType":"fqdn","Port":8443,"Path":"/p","RelyingParty":"rp2","SignaturePolicyIndex":7}],'
        '"SignaturePolicies":null}'.as_bytes()
    )
    assert_equal(t.match("https://q.a.b.com/").value().relying_party, "rp1")
    assert_false(Bool(t.match("https://q.a.com/")))
    assert_false(Bool(t.match("https://x.com/p")))
    var m = t.match("https://x.com:8443/p?q").value().copy()
    assert_equal(m.relying_party, "rp2")
    assert_equal(m.policy.version, auth_policy().version)
    assert_false(Bool(t.match("https://x.com:8443/other")))


def test_requests() raises:
    var d = default_title_request()
    assert_equal(d.method, "GET")
    assert_equal(d.url, NSAL_DEFAULT_URL)
    assert_equal(d.header("x-xbl-contract-version").value(), "1")
    assert_false(Bool(d.header("Signature")))
    var key = List[UInt8]()
    for i in range(32):
        key.append(UInt8(i + 1))
    var r = title_request(
        "current", "XBL3.0 x=1;t", Span(key), 1794564000000000000
    )
    assert_equal(
        r.url, "https://title.mgt.xboxlive.com/titles/current/endpoints"
    )
    assert_equal(r.header("Authorization").value(), "XBL3.0 x=1;t")
    assert_true(Bool(r.header("Signature")))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
