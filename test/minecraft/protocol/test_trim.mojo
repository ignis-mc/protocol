# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.trim import TrimMaterial, TrimPattern
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


def test_trim_pattern() raises:
    var p = TrimPattern(
        "minecraft:wayfinder_armor_trim_smithing_template", "wayfinder"
    )
    comptime want = (
        "306d696e6563726166743a77617966696e6465725f61726d6f725f7472696d5f736d"
        "697468696e675f74656d706c6174650977617966696e646572"
    )
    assert_equal(_encode(p), want)
    assert_equal(_decode[TrimPattern](want).pattern_id, "wayfinder")


def test_trim_material() raises:
    var m = TrimMaterial("netherite", "§j", "minecraft:netherite_ingot")
    comptime want = (
        "096e657468657269746503c2a76a196d696e6563726166743a6e65746865726974"
        "655f696e676f74"
    )
    assert_equal(_encode(m), want)
    assert_equal(_decode[TrimMaterial](want).colour, "§j")


def test_string_past_payload_is_rejected() raises:
    with assert_raises(contains="exceeds remaining"):
        _ = _decode[TrimPattern]("306d69")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
