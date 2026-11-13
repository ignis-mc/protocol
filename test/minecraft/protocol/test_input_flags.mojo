from minecraft.protocol.input_flags import InputFlags, input_flag_list
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


def test_flags_match_gophertunnel() raises:
    var ids: List[Int32] = [3, 1, 7, 3]
    var f = InputFlags.from_ids(10, Span(ids))
    var w = Writer()
    input_flag_list(w, f, 10)
    assert_equal(hex_encode(Span(w.buf)), "0306020e")
    var raw = hex_decode("0306020e")
    var r = Reader(Span(raw))
    var back = InputFlags()
    input_flag_list(r, back, 10)
    assert_equal(r.remaining(), 0)
    assert_true(back == f)
    assert_true(back.present())
    assert_true(back.load(7))
    assert_false(back.load(0))


def test_set_unset_and_absent_value() raises:
    var zero = InputFlags()
    assert_false(zero.present())
    assert_false(zero.load(100))
    zero.unset(100)
    var f = InputFlags(4)
    f.set(2)
    f.set(2)
    assert_equal(len(f.ids()), 1)
    f.unset(2)
    assert_false(f.load(2))
    with assert_raises(contains="out of bounds"):
        f.set(4)
    var w = Writer()
    var empty = InputFlags()
    input_flag_list(w, empty, 4)
    assert_equal(hex_encode(Span(w.buf)), "00")


def _read(h: String) raises -> InputFlags:
    var raw = hex_decode(h)
    var r = Reader(Span(raw))
    var f = InputFlags()
    input_flag_list(r, f, 10)
    return f^


def test_malformed_flags_are_rejected() raises:
    # Messages as in gophertunnel's InputFlagList.
    with assert_raises(contains="flags must be unique"):
        _ = _read("02" + "02" + "02")
    with assert_raises(contains="unknown value '10'"):
        _ = _read("01" + "14")
    with assert_raises(contains="unknown value '-1'"):
        _ = _read("01" + "01")
    with assert_raises(contains="too many flags"):
        _ = _read("0b")
    with assert_raises():
        _ = _read("03" + "02")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
