from std.testing import TestSuite, assert_equal

from minecraft.internal.md5 import md5


def _hex(data: StringSpan) -> String:
    var d = md5(data.as_bytes())
    var s = String()
    comptime digits = "0123456789abcdef"
    for i in range(16):
        s += digits[byte=Int(d[i] >> 4)]
        s += digits[byte=Int(d[i] & 15)]
    return s^


def test_rfc1321_suite() raises:
    assert_equal(_hex(""), "d41d8cd98f00b204e9800998ecf8427e")
    assert_equal(_hex("a"), "0cc175b9c0f1b6a831c399e269772661")
    assert_equal(_hex("abc"), "900150983cd24fb0d6963f7d28e17f72")
    assert_equal(_hex("message digest"), "f96b697d7cb7938d525a2f31aaf161d0")
    assert_equal(
        _hex("abcdefghijklmnopqrstuvwxyz"), "c3fcd3d76192e4007dfb496cca67e13b"
    )
    assert_equal(
        _hex("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"),
        "d174ab98d277d9f5a5611c2c9f419d9f",
    )
    assert_equal(
        _hex(
            "1234567890123456789012345678901234567890"
            "1234567890123456789012345678901234567890"
        ),
        "57edf4a22be3c955ac49da2e2107b67a",
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
