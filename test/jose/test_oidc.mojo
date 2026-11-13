from std.testing import TestSuite, assert_equal, assert_raises, assert_true

from jose.jwk import JSONWebKey
from jose.jws import CURVE_P384
from jose.oidc import Config, IDTokenVerifier, StaticKeySet
from nethernet.crypto.base64 import base64url_encode
from nethernet.crypto.p384 import p384_public_key, p384_sign
from nethernet.crypto.sha512 import sha384

comptime ISSUER = "https://issuer.test/"
comptime NOW = 1_800_000_000


def _token(
    fill: UInt8, claims: StringSpan, kid: StringSpan = "k"
) raises -> String:
    var priv = List[UInt8](length=48, fill=fill)
    var h = base64url_encode(
        String('{"alg":"ES384","kid":"', kid, '"}').as_bytes()
    )
    var input = String(h, ".", base64url_encode(claims.as_bytes()))
    var sig = p384_sign(Span(priv), Span(sha384(input.as_bytes())))
    return String(input, ".", base64url_encode(Span(sig)))


def _verifier() raises -> IDTokenVerifier[StaticKeySet]:
    var priv = List[UInt8](length=48, fill=0x11)
    var point = p384_public_key(Span(priv))
    var keys: List[JSONWebKey] = [JSONWebKey.ec(CURVE_P384, Span(point), "k")]
    var config = Config()
    config.client_id = "aud"
    config.supported_signing_algs = ["ES384"]
    return IDTokenVerifier(String(ISSUER), StaticKeySet(keys^), config^)


def _claims(extra: StringSpan) -> String:
    return String(
        '{"iss":"', ISSUER, '","aud":"aud","exp":', NOW + 60, extra, "}"
    )


def test_valid_token() raises:
    var v = _verifier()
    var t = v.verify(_token(0x11, _claims(',"sub":"s","iat":5')), NOW)
    assert_equal(t.subject, "s")
    assert_equal(t.expiry, NOW + 60)
    assert_equal(t.issued_at, 5)
    assert_equal(t.sig_algorithm, "ES384")
    assert_true(len(t.claims) > 0)


def test_rejections() raises:
    var v = _verifier()
    with assert_raises(contains="failed to verify signature"):
        _ = v.verify(_token(0x22, _claims("")), NOW)
    with assert_raises(contains="different provider"):
        _ = v.verify(
            _token(0x11, '{"iss":"x","aud":"aud","exp":1900000000}'), NOW
        )
    with assert_raises(contains="expected audience"):
        _ = v.verify(
            _token(
                0x11,
                String('{"iss":"', ISSUER, '","aud":"x","exp":1900000000}'),
            ),
            NOW,
        )
    with assert_raises(contains="expired"):
        _ = v.verify(_token(0x11, _claims("")), NOW + 61)
    _ = v.verify(_token(0x11, _claims("")), NOW + 60)
    with assert_raises(contains="expired"):
        _ = v.verify(
            _token(0x11, String('{"iss":"', ISSUER, '","aud":"aud"}')), NOW
        )
    # nbf: five minutes of skew are tolerated.
    _ = v.verify(_token(0x11, _claims(String(',"nbf":', NOW + 300))), NOW)
    with assert_raises(contains="nbf"):
        _ = v.verify(_token(0x11, _claims(String(',"nbf":', NOW + 301))), NOW)
    with assert_raises(contains="malformed jwt"):
        _ = v.verify("a.b", NOW)
    with assert_raises(contains="unmarshal claims"):
        _ = v.verify(_token(0x11, '{"iss":5}'), NOW)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
