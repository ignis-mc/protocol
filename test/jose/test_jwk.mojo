from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

from jose.jwk import KEY_TYPE_EC, KEY_TYPE_RSA, JSONWebKey, parse_key
from jose.jws import CURVE_P256, ES256, parse_signed

# RFC 7515 appendix A.3.
comptime TOKEN = (
    "eyJhbGciOiJFUzI1NiJ9"
    ".eyJpc3MiOiJqb2UiLA0KICJleHAiOjEzMDA4MTkzODAsDQogImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlfQ"
    ".DtEhU3ljbEg8L38VWAfUAqOyKAM6-Xx-F4GawxaepmXFCgfTjDxw5djxLa8ISlSApmWQxfKTUJqPP3-Kg6NU1Q"
)


def test_ec_key() raises:
    var k = parse_key(
        '{"kty":"EC","crv":"P-256","kid":"k1","use":"sig","alg":"ES256",'
        '"x":"f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU",'
        '"y":"x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0="}'
    )
    assert_equal(k.key_type, KEY_TYPE_EC)
    assert_equal(k.curve, CURVE_P256)
    assert_equal(len(k.point), 65)
    assert_equal(k.key_id, "k1")
    assert_equal(k.use, "sig")
    assert_true(k.verify(parse_signed(TOKEN, [String(ES256)])))
    var copy = JSONWebKey.ec(k.curve, Span(k.point), "k2")
    assert_true(copy.verify(parse_signed(TOKEN, [String(ES256)])))


def test_rsa_key_and_errors() raises:
    # RFC 7517 appendix A.1, the RSA example key.
    var k = parse_key(
        '{"kty":"RSA","e":"AQAB","kid":"2011-04-29","n":"0vx7agoebGcQSuuPiLJ'
        "XZptN9nndrQmbXEps2aiAFbWhM78LhWx4cbbfAAtVT86zwu1RK7aPFFxuhDR1L6tSoc_"
        "BJECPebWKRXjBZCiFV4n3oknjhMstn64tZ_2W-5JsGY4Hc5n9yBXArwl93lqt7_RN5w6"
        "Cf0h4QyQ5v-65YGjQR0_FDW2QvzqY368QQMicAtaSqzs8KJZgnYb9c7d0zgdAZHzu6qM"
        "QvRL5hajrn1n91CbOpbISD08qNLyrdkt-bFTWhAI4vMQFh6WeZu0fM4lFd2NcRwr3XPk"
        'sINHaQ-G_xBniIqbw0Ls1jF44-csFCur-kEgU8awapJzKnqDKgw"}'
    )
    assert_equal(k.key_type, KEY_TYPE_RSA)
    assert_true(Bool(k.rsa))
    assert_false(k.verify(parse_signed(TOKEN, [String(ES256)])))
    with assert_raises(contains="unsupported elliptic curve"):
        _ = parse_key('{"kty":"EC","crv":"P-521","x":"AA","y":"AA"}')


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
