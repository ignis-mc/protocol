from std.testing import TestSuite, assert_equal, assert_raises

from jose.base64 import raw_url_decode, std_decode


def _hex(b: List[UInt8]) -> String:
    var s = String()
    for x in b:
        s += hex(Int(x), prefix="")
        s += ","
    return s^


def test_std_padding_rules() raises:
    assert_equal(len(std_decode("AAAAAA==")), 4)
    assert_equal(len(std_decode("AAAAAAA=")), 5)
    assert_equal(len(std_decode("")), 0)
    with assert_raises():
        _ = std_decode("AAAAAA")
    with assert_raises():
        _ = std_decode("AAAAA===")
    with assert_raises():
        _ = std_decode("AAA=A===")
    with assert_raises():
        _ = std_decode("AAAAAA=")
    with assert_raises():
        _ = std_decode("AAAA AA==")


def test_std_lenient_like_go() raises:
    # Non-zero trailing bits and embedded newlines are accepted.
    assert_equal(_hex(std_decode("AAAAAB==")), "0,0,0,0,")
    assert_equal(len(std_decode("AAAA\nAA==\r\n")), 4)
    assert_equal(_hex(std_decode("/+8=")), "ff,ef,")


def test_raw_url() raises:
    assert_equal(_hex(raw_url_decode("_-8")), "ff,ef,")
    with assert_raises():
        _ = raw_url_decode("_-8=")
    with assert_raises():
        _ = raw_url_decode("A")
    with assert_raises():
        _ = raw_url_decode("+/")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
