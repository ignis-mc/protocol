from minecraft.auth.scrypt import _salsa20_8, pbkdf2_hmac_sha256, scrypt
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises


def _hex(data: List[UInt8]) -> String:
    return hex_encode(Span(data))


def test_salsa20_8_rfc7914_section8() raises:
    var input = hex_decode(
        "7e879a214f3ec9867ca940e641718f26baee555b8c61c1b50df846116dcd3b1d"
        "ee24f319df9b3d8514121e4b5ac5aa3276021d2909c74829edebc68db8b8c25e"
    )
    var b = Array[UInt32, 16](fill=0)
    for i in range(16):
        b[i] = (
            UInt32(input[4 * i])
            | (UInt32(input[4 * i + 1]) << 8)
            | (UInt32(input[4 * i + 2]) << 16)
            | (UInt32(input[4 * i + 3]) << 24)
        )
    _salsa20_8(b)
    var out = List[UInt8]()
    for i in range(16):
        for k in range(4):
            out.append(UInt8((b[i] >> UInt32(8 * k)) & 0xFF))
    assert_equal(
        _hex(out),
        (
            "a41f859c6608cc993b81cacb020cef05044b2181a2fd337dfd7b1c6396682f29"
            "b4393168e3c9e6bcfe6bc5b7a06d96bae424cc102c91745c24ad673dc7618f81"
        ),
    )


def test_pbkdf2_rfc7914_section11() raises:
    assert_equal(
        _hex(pbkdf2_hmac_sha256("passwd".as_bytes(), "salt".as_bytes(), 1, 64)),
        (
            "55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc"
            "49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783"
        ),
    )
    assert_equal(
        _hex(
            pbkdf2_hmac_sha256(
                "Password".as_bytes(), "NaCl".as_bytes(), 80000, 64
            )
        ),
        (
            "4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56"
            "a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d"
        ),
    )


def test_pbkdf2_short_and_odd_lengths() raises:
    var full = pbkdf2_hmac_sha256("passwd".as_bytes(), "salt".as_bytes(), 1, 64)
    var short = pbkdf2_hmac_sha256(
        "passwd".as_bytes(), "salt".as_bytes(), 1, 33
    )
    assert_equal(len(short), 33)
    for i in range(33):
        assert_equal(short[i], full[i])
    assert_equal(
        len(pbkdf2_hmac_sha256("a".as_bytes(), "b".as_bytes(), 1, 0)), 0
    )
    with assert_raises():
        _ = pbkdf2_hmac_sha256("a".as_bytes(), "b".as_bytes(), 0, 32)


def test_scrypt_rfc7914_section12() raises:
    assert_equal(
        _hex(scrypt("".as_bytes(), "".as_bytes(), 16, 1, 1, 64)),
        (
            "77d6576238657b203b19ca42c18a0497f16b4844e3074ae8dfdffa3fede21442"
            "fcd0069ded0948f8326a753a0fc81f17e8d3e0fb2e0d3628cf35e20c38d18906"
        ),
    )
    assert_equal(
        _hex(scrypt("password".as_bytes(), "NaCl".as_bytes(), 1024, 8, 16, 64)),
        (
            "fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b373162"
            "2eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640"
        ),
    )
    assert_equal(
        _hex(
            scrypt(
                "pleaseletmein".as_bytes(),
                "SodiumChloride".as_bytes(),
                16384,
                8,
                1,
                64,
            )
        ),
        (
            "7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2"
            "d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887"
        ),
    )


def test_scrypt_rejects_bad_parameters() raises:
    with assert_raises():
        _ = scrypt("".as_bytes(), "".as_bytes(), 15, 1, 1, 32)
    with assert_raises():
        _ = scrypt("".as_bytes(), "".as_bytes(), 1, 1, 1, 32)
    with assert_raises():
        _ = scrypt("".as_bytes(), "".as_bytes(), 16, 0, 1, 32)
    with assert_raises():
        _ = scrypt("".as_bytes(), "".as_bytes(), 16, 1, 0, 32)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
