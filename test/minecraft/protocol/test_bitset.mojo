from minecraft.protocol.bitset import Bitset, bitset
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _check(size: Int, bits: List[Int], expected: String) raises:
    var b = Bitset(size)
    for i in bits:
        b.set(i)
    var w = Writer()
    bitset(w, b, size)
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = Bitset()
    bitset(r, back, size)
    assert_equal(r.remaining(), 0)
    assert_true(back == b)
    for i in range(size):
        assert_equal(back.load(i), i in bits)


def test_sizes_match_gophertunnel() raises:
    _check(7, [], "00")
    _check(7, [0, 6], "41")
    _check(8, [7], "8001")
    _check(64, [0, 63], "81808080808080808001")
    _check(131, [0, 7, 64, 130], "81818080808080808082808080808080808010")
    _check(200, [199], "80" * 28 + "08")


def test_set_unset_load() raises:
    var b = Bitset(70)
    assert_equal(len(b), 70)
    b.set(69)
    b.set(3)
    b.unset(3)
    assert_true(b.load(69))
    assert_false(b.load(3))
    assert_equal(String(b), "Bitset(70){69}")
    with assert_raises(contains="out of bounds"):
        b.set(70)
    with assert_raises(contains="out of bounds"):
        _ = b.load(-1)


def test_write_size_mismatch_is_rejected() raises:
    var b = Bitset(8)
    var w = Writer()
    with assert_raises(contains="size mismatch"):
        bitset(w, b, 9)


def _read(size: Int, h: String) raises -> Bitset:
    var raw = hex_decode(h)
    var r = Reader(Span(raw))
    var b = Bitset()
    bitset(r, b, size)
    return b^


def test_overflow_is_rejected_like_gophertunnel() raises:
    # Each case is checked against gophertunnel's Reader.Bitset.
    with assert_raises(contains="overflows"):
        _ = _read(7, "80")
    with assert_raises(contains="overflows"):
        _ = _read(8, "8102")
    with assert_raises(contains="overflows"):
        _ = _read(8, "8104")
    with assert_raises(contains="overflows"):
        _ = _read(8, "8180")
    with assert_raises(contains="overflows"):
        _ = _read(10, "ff08")
    with assert_raises(contains="overflows"):
        _ = _read(14, "8080")
    with assert_raises():
        _ = _read(14, "80")
    var ok = _read(10, "ff07")
    for i in range(10):
        assert_true(ok.load(i))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
