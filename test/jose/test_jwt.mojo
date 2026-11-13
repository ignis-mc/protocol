from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

from jose.json import decode_object
from jose.jwt import Claims, DEFAULT_LEEWAY, Expected, validate


def _claims(text: StringSpan) raises -> Claims:
    return Claims.decode(decode_object(text.as_bytes()))


def test_decode() raises:
    var c = _claims(
        '{"ISS":"me","sub":"s","aud":"a","exp":100.9,"nbf":-1.5,"iat":5,'
        '"jti":"j"}'
    )
    assert_equal(c.issuer, "me")
    assert_equal(c.subject, "s")
    assert_equal(len(c.audience), 1)
    assert_equal(c.expiry.value(), 100)
    assert_equal(c.not_before.value(), -1)
    assert_equal(c.issued_at.value(), 5)
    assert_equal(c.id, "j")
    var many = _claims('{"aud":["x","y"],"exp":null}')
    assert_equal(len(many.audience), 2)
    assert_false(Bool(many.expiry))
    with assert_raises(contains="expected number"):
        _ = _claims('{"exp":"100"}')
    with assert_raises():
        _ = _claims('{"aud":5}')


def test_leeway_boundaries() raises:
    var c = _claims('{"exp":1000,"nbf":2000,"iat":2000}')
    c.not_before = None
    c.issued_at = None
    validate(c, Expected(1000 + DEFAULT_LEEWAY))
    with assert_raises(contains="expired"):
        validate(c, Expected(1001 + DEFAULT_LEEWAY))
    var n = _claims('{"nbf":2000}')
    validate(n, Expected(2000 - DEFAULT_LEEWAY))
    with assert_raises(contains="not valid yet"):
        validate(n, Expected(1999 - DEFAULT_LEEWAY))
    var i = _claims('{"iat":2000}')
    with assert_raises(contains="issued in the future"):
        validate(i, Expected(1000))


def test_issuer_and_audience() raises:
    var c = _claims('{"iss":"Mojang","aud":["a","b"]}')
    validate(c, Expected(0, "Mojang"))
    with assert_raises(contains="issuer"):
        validate(c, Expected(0, "Other"))
    var e = Expected(0)
    e.any_audience = ["z", "b"]
    validate(c, e)
    e.any_audience = ["z"]
    with assert_raises(contains="audience"):
        validate(c, e)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
