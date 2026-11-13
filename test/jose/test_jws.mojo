from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

from jose.jwk import parse_key
from jose.jws import (
    CURVE_P384,
    ES256,
    ES384,
    RS256,
    ec_point_valid,
    parse_signed,
)
from nethernet.crypto.base64 import base64url_encode
from nethernet.crypto.p384 import p384_public_key, p384_sign
from nethernet.crypto.sha512 import sha384

# RFC 7515 appendix A.3: ES256.
comptime RFC_TOKEN = (
    "eyJhbGciOiJFUzI1NiJ9"
    ".eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ"
    ".DtEhU3ljbEg8L38VWAfUAqOyKAM6-Xx-F4GawxaepmXFCgfTjDxw5djxLa8ISlSApmWQxfKTUJqPP3-Kg6NU1Q"
)
comptime RFC_JWK = (
    '{"kty":"EC","crv":"P-256",'
    '"x":"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU",'
    '"y":"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0"}'
)


def _algs(a: StaticString) -> List[String]:
    return [String(a)]


def test_rfc7515_es256() raises:
    var jws = parse_signed(RFC_TOKEN, _algs(ES256))
    var key = parse_key(RFC_JWK)
    assert_true(key.verify(jws))
    assert_equal(len(jws.signature), 64)
    var payload = String(from_utf8=Span(jws.payload))
    assert_true(payload.startswith('{"iss":"joe"'))


def test_algorithm_must_be_accepted() raises:
    with assert_raises(contains="unexpected signature algorithm"):
        _ = parse_signed(RFC_TOKEN, _algs(RS256))


def test_tampered_signature_fails() raises:
    var bad = String(RFC_TOKEN).replace("DtEh", "DtEi")
    var jws = parse_signed(bad, _algs(ES256))
    assert_false(parse_key(RFC_JWK).verify(jws))


def test_shape_errors() raises:
    with assert_raises(contains="three parts"):
        _ = parse_signed("a.b", _algs(ES256))
    with assert_raises(contains="three parts"):
        _ = parse_signed("a.b.c.d", _algs(ES256))
    with assert_raises():
        _ = parse_signed("e30.e30.c2ln=", _algs(ES256))


def test_crit_rejected() raises:
    var h = base64url_encode('{"alg":"ES256","crit":["b64"]}'.as_bytes())
    with assert_raises(contains="critical"):
        _ = parse_signed(String(t"{h}.e30.AA"), _algs(ES256))


def test_es384_with_point_and_wrong_curve() raises:
    var priv = List[UInt8](length=48, fill=0x11)
    var point = p384_public_key(Span(priv))
    var h = base64url_encode('{"alg":"ES384"}'.as_bytes())
    var p = base64url_encode('{"a":1}'.as_bytes())
    var input = String(t"{h}.{p}")
    var sig = p384_sign(Span(priv), Span(sha384(input.as_bytes())))
    var token = String(t"{input}.{base64url_encode(Span(sig))}")
    var jws = parse_signed(token, _algs(ES384))
    assert_true(jws.verify_ecdsa(CURVE_P384, Span(point)))
    assert_true(ec_point_valid(CURVE_P384, Span(point)))
    # The same signature under ES256 rules (wrong curve) never verifies.
    assert_false(parse_key(RFC_JWK).verify(jws))


def test_jwk_errors() raises:
    with assert_raises(contains="point not on curve"):
        _ = parse_key(
            '{"kty":"EC","crv":"P-256",'
            '"x":"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU",'
            '"y":"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a4"}'
        )
    with assert_raises(contains="wrong length"):
        _ = parse_key('{"kty":"EC","crv":"P-256","x":"AA","y":"AA"}')
    with assert_raises(contains="unknown json web key type"):
        _ = parse_key('{"kty":"oct","k":"AA"}')
    with assert_raises(contains="missing n/e"):
        _ = parse_key('{"kty":"RSA","n":"","e":"AQAB"}')
    var small = parse_key('{"kty":"RSA","n":"AQAB","e":"AQAB","kid":"x"}')
    assert_false(Bool(small.rsa))
    assert_equal(small.key_id, "x")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
