# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.furnace import (
    FURNACE_LAYOUT_DEFAULT,
    FURNACE_LEFT_TAB_RECIPE_BLOCKS,
    FurnaceOptions,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _encode[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _decode[T: Marshaler](hex: StringSpan) raises -> T:
    var data = hex_decode(hex)
    var r = Reader(Span(data))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(_encode(x), String(hex))
    return x^


def test_furnace_options() raises:
    var f = FurnaceOptions()
    f.left_furnace_tab = FURNACE_LEFT_TAB_RECIPE_BLOCKS
    f.filtering = True
    f.layout = FURNACE_LAYOUT_DEFAULT
    assert_equal(_encode(f), "060104")
    var back = _decode[FurnaceOptions]("060104")
    assert_equal(back.layout, FURNACE_LAYOUT_DEFAULT)
    assert_true(back.filtering)


def test_truncated_input_is_rejected() raises:
    with assert_raises():
        _ = _decode[FurnaceOptions]("0601")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
