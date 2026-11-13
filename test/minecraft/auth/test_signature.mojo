from minecraft.auth.signature import SignaturePolicy, auth_policy, proof_key_jwk
from minecraft.auth.transport import Request
from nethernet.crypto.base64 import base64_decode
from nethernet.crypto.p256 import p256_public_key, p256_verify
from nethernet.wire import hex_encode
from std.testing import TestSuite, assert_equal, assert_false, assert_true

comptime NOW_NS = 1794564000123456789


def _key() -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(32):
        out.append(UInt8(i + 1))
    return out^


def _request() -> Request:
    var headers = List[Tuple[String, String]]()
    headers.append(("Authorization", "XBL3.0 x=1;tok"))
    headers.append(("X-Extra", "extra-value"))
    return Request(
        "POST",
        "https://x.xboxlive.com/a/b?c=d&e=f",
        headers^,
        List[UInt8]("0123456789".as_bytes()),
    )


def _policy() -> SignaturePolicy:
    var extra = List[String]()
    extra.append("X-Extra")
    extra.append("X-Missing")
    return SignaturePolicy(1, List[String](), 4, extra^)


def test_proof_key_jwk_matches_go_jose() raises:
    # From the XASD request body go-xsapi builds for this key.
    assert_equal(
        proof_key_jwk(Span(_key())),
        (
            '{"use":"sig","kty":"EC","crv":"P-256","alg":"ES256",'
            '"x":"UVw9brnjlrkE0_7Kf1T9zQzB6Ze_N13KUVrQpsO0A18",'
            '"y":"RTa-OlDzGPv5pUdZAqIhUCvvDVfgjFOyzApW8X2fk1Q"}'
        ),
    )


def test_go_signature_verifies_against_our_digest() raises:
    # go-xsapi nsal.SignaturePolicy{Version: 1, MaxBodyBytes: 4,
    # ExtraHeaders: {"X-Extra", "X-Missing"}}.Sign(req, "0123456789", key,
    # time.Unix(1794564000, 123456789)) for the same request.
    var go = base64_decode(
        "AAAAAQHdc1W+yOaHpxodtBBpJTgWBXuVPulsqOf+dz1o5BPfd2w36Q3ehujzHt7NVVGfTiqd3SO4bwo8rnBiH1edI8dt/gtPb2XA+Q=="
    )
    var pub = p256_public_key(Span(_key()))
    var digest = _policy().digest(_request(), NOW_NS)
    assert_true(p256_verify(Span(pub), Span(digest), Span(go)[12:76]))
    # Version and FILETIME prefix are identical.
    var ours = _policy().generate(_request(), Span(_key()), NOW_NS)
    assert_equal(len(ours), 76)
    assert_equal(hex_encode(Span(ours)[0:12]), hex_encode(Span(go)[0:12]))
    assert_true(p256_verify(Span(pub), Span(digest), Span(ours)[12:76]))
    # Any change to a signed part breaks the signature.
    # Only the first MaxBodyBytes (4) body bytes are signed.
    var tail = _request()
    tail.body[6] = 0x58
    assert_true(
        p256_verify(
            Span(pub), Span(_policy().digest(tail, NOW_NS)), Span(go)[12:76]
        )
    )
    var head = _request()
    head.body[2] = 0x58
    assert_false(
        p256_verify(
            Span(pub), Span(_policy().digest(head, NOW_NS)), Span(go)[12:76]
        )
    )
    var changed = _request()
    changed.headers[1] = ("X-Extra", "other")
    assert_false(
        p256_verify(
            Span(pub), Span(_policy().digest(changed, NOW_NS)), Span(go)[12:76]
        )
    )
    assert_false(
        p256_verify(
            Span(pub),
            Span(_policy().digest(_request(), NOW_NS + 100)),
            Span(go)[12:76],
        )
    )


def test_sign_sets_the_header() raises:
    var req = _request()
    auth_policy().sign(req, Span(_key()), NOW_NS)
    var raw = base64_decode(req.header("Signature").value())
    assert_equal(len(raw), 76)
    assert_equal(hex_encode(Span(raw)[0:4]), "00000001")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
