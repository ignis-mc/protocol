from nethernet.wire import hex_decode, hex_encode
from rfc8448 import (
    CLIENT_PRIVATE_KEY,
    CLIENT_PUBLIC_KEY,
    SERVER_PRIVATE_KEY,
    SERVER_PUBLIC_KEY,
    SHARED_SECRET,
)
from std.testing import TestSuite, assert_equal, assert_raises
from tls.x25519 import x25519, x25519_public_key, x25519_shared_secret


def _x(scalar: StringSpan, u: StringSpan) raises -> String:
    var k = hex_decode(scalar)
    var p = hex_decode(u)
    return hex_encode(Span(x25519(Span(k), Span(p))))


def test_rfc7748_vectors() raises:
    assert_equal(
        _x(
            "a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
            "e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
        ),
        "c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
    )
    # The u-coordinate has its top bit set, which must be ignored.
    assert_equal(
        _x(
            "4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
            "e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
        ),
        "95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
    )


def test_rfc7748_iterated() raises:
    var k = Array[UInt8, 32](fill=0)
    k[0] = 9
    var u = k.copy()
    for i in range(1000):
        var next = x25519(Span(k), Span(u))
        u = k.copy()
        k = next.copy()
        if i == 0:
            assert_equal(
                hex_encode(Span(k)),
                "422c8e7a6227d7bca1350b3e2bb7279f7897b87bb6854b783c60e80311ae3079",
            )
    assert_equal(
        hex_encode(Span(k)),
        "684cf59ba83309552800ef566f2f4d3c1c3887c49360e3875f2eb94d99532c51",
    )


def test_rfc7748_diffie_hellman() raises:
    var a = hex_decode(
        "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a"
    )
    var b = hex_decode(
        "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb"
    )
    var pa = x25519_public_key(Span(a))
    var pb = x25519_public_key(Span(b))
    assert_equal(
        hex_encode(Span(pa)),
        "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a",
    )
    assert_equal(
        hex_encode(Span(pb)),
        "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f",
    )
    var k1 = x25519_shared_secret(Span(a), Span(pb))
    var k2 = x25519_shared_secret(Span(b), Span(pa))
    assert_equal(
        hex_encode(Span(k1)),
        "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742",
    )
    assert_equal(hex_encode(Span(k1)), hex_encode(Span(k2)))


def test_rfc8448_key_exchange() raises:
    var c = hex_decode(CLIENT_PRIVATE_KEY)
    var s = hex_decode(SERVER_PRIVATE_KEY)
    assert_equal(
        hex_encode(Span(x25519_public_key(Span(c)))), CLIENT_PUBLIC_KEY
    )
    assert_equal(
        hex_encode(Span(x25519_public_key(Span(s)))), SERVER_PUBLIC_KEY
    )
    var sp = hex_decode(SERVER_PUBLIC_KEY)
    assert_equal(
        hex_encode(Span(x25519_shared_secret(Span(c), Span(sp)))),
        SHARED_SECRET,
    )


def test_small_order_point_is_rejected() raises:
    var k = hex_decode(CLIENT_PRIVATE_KEY)
    var zero = List[UInt8](length=32, fill=0)
    with assert_raises(contains="small order"):
        _ = x25519_shared_secret(Span(k), Span(zero))
    # u = 1 has order 4 on the curve.
    var one = List[UInt8](length=32, fill=0)
    one[0] = 1
    with assert_raises(contains="small order"):
        _ = x25519_shared_secret(Span(k), Span(one))


def test_wrong_length_is_rejected() raises:
    var k = List[UInt8](length=31, fill=1)
    var u = List[UInt8](length=32, fill=1)
    with assert_raises():
        _ = x25519(Span(k), Span(u))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
