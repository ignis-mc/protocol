from nethernet.crypto.sha256 import Sha256
from nethernet.crypto.sha512 import Sha384
from nethernet.wire import hex_decode, hex_encode
from rfc8448 import (
    CLIENT_HS_TRAFFIC,
    DERIVED_FOR_HANDSHAKE,
    EARLY_SECRET,
    HANDSHAKE_SECRET,
    HASH_CH_SH,
    SHARED_SECRET,
)
from std.testing import TestSuite, assert_equal, assert_raises
from tls.hkdf import HashKind, hkdf_expand, hkdf_extract


def _range(lo: Int, hi: Int) -> List[UInt8]:
    var out = List[UInt8]()
    for i in range(lo, hi):
        out.append(UInt8(i))
    return out^


def test_rfc5869_case1() raises:
    var ikm = List[UInt8](length=22, fill=0x0B)
    var salt = _range(0, 13)
    var info = _range(0xF0, 0xFA)
    var prk = hkdf_extract[Sha256](Span(salt), Span(ikm))
    assert_equal(
        hex_encode(Span(prk)),
        "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5",
    )
    var okm = hkdf_expand[Sha256](Span(prk), Span(info), 42)
    assert_equal(
        hex_encode(Span(okm)),
        (
            "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf"
            "34007208d5b887185865"
        ),
    )


def test_rfc5869_case2() raises:
    var ikm = _range(0, 0x50)
    var salt = _range(0x60, 0xB0)
    var info = _range(0xB0, 0x100)
    var prk = hkdf_extract[Sha256](Span(salt), Span(ikm))
    assert_equal(
        hex_encode(Span(prk)),
        "06a6b88c5853361a06104c9ceb35b45cef760014904671014a193f40c15fc244",
    )
    var okm = hkdf_expand[Sha256](Span(prk), Span(info), 82)
    assert_equal(
        hex_encode(Span(okm)),
        (
            "b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c"
            "59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71"
            "cc30c58179ec3e87c14c01d5c1f3434f1d87"
        ),
    )


def test_rfc5869_case3_empty_salt_and_info() raises:
    var ikm = List[UInt8](length=22, fill=0x0B)
    var empty = List[UInt8]()
    var prk = hkdf_extract[Sha256](Span(empty), Span(ikm))
    assert_equal(
        hex_encode(Span(prk)),
        "19ef24a32c717b167f33a91d6f648bdf96596776afdb6377ac434c1c293ccb04",
    )
    var okm = hkdf_expand[Sha256](Span(prk), Span(empty), 42)
    assert_equal(
        hex_encode(Span(okm)),
        (
            "8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d"
            "9d201395faa4b61a96c8"
        ),
    )


def test_hkdf_sha384_matches_reference() raises:
    # Cross-checked with Python's hmac module (RFC 5869 case 1 inputs).
    var ikm = List[UInt8](length=22, fill=0x0B)
    var salt = _range(0, 13)
    var info = _range(0xF0, 0xFA)
    var prk = hkdf_extract[Sha384](Span(salt), Span(ikm))
    assert_equal(
        hex_encode(Span(prk)),
        (
            "704b39990779ce1dc548052c7dc39f303570dd13fb39f7acc564680bef80e8de"
            "c70ee9a7e1f3e293ef68eceb072a5ade"
        ),
    )
    var okm = HashKind.SHA384.expand(Span(prk), Span(info), 100)
    assert_equal(
        hex_encode(Span(okm)),
        (
            "9b5097a86038b805309076a44b3a9f38063e25b516dcbf369f394cfab43685f7"
            "48b6457763e4f0204fc5d95d1da3e62587b22eb8943d0fab6bb631a2fe9df1a6"
            "8c6ce5d56116a52005b3f122b88b39b7251fcd6c44d3ef25f20ed96802bf1b2c"
            "1d98bf74"
        ),
    )


def test_expand_rejects_overlong_output() raises:
    var prk = List[UInt8](length=32, fill=1)
    var empty = List[UInt8]()
    _ = hkdf_expand[Sha256](Span(prk), Span(empty), 255 * 32)
    with assert_raises():
        _ = hkdf_expand[Sha256](Span(prk), Span(empty), 255 * 32 + 1)


def test_rfc8448_early_and_handshake_secrets() raises:
    var h = HashKind.SHA256
    var zeros = List[UInt8](length=32, fill=0)
    var empty = List[UInt8]()
    var early = h.extract(Span(empty), Span(zeros))
    assert_equal(hex_encode(Span(early)), EARLY_SECRET)
    var empty_hash = h.hash(Span(empty))
    var derived = h.derive_secret(Span(early), "derived", Span(empty_hash))
    assert_equal(hex_encode(Span(derived)), DERIVED_FOR_HANDSHAKE)
    var shared = hex_decode(SHARED_SECRET)
    var hs = h.extract(Span(derived), Span(shared))
    assert_equal(hex_encode(Span(hs)), HANDSHAKE_SECRET)
    var th = hex_decode(HASH_CH_SH)
    var c_hs = h.derive_secret(Span(hs), "c hs traffic", Span(th))
    assert_equal(hex_encode(Span(c_hs)), CLIENT_HS_TRAFFIC)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
