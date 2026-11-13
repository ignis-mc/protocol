from minecraft.protocol.uuid import UUID
from minecraft.protocol.world import (
    GENERATOR_OVERWORLD,
    DimensionDefinition,
    GenerationFeature,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def test_dimension_definition() raises:
    var d = DimensionDefinition()
    d.name = "minecraft:overworld"
    d.minimum_y = -64
    d.height_range = 384
    d.generator = GENERATOR_OVERWORLD
    d.dimension_type = 1000
    d.pack_id = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    d.default_biome = "plains"
    d.cloud_height = 192
    d.render_clouds = True
    assert_equal(
        _hex(d),
        (
            "136d696e6563726166743a6f766572776f726c647f800602d00fefcdab896745"
            "2301efcdab896745230106706c61696e73800301"
        ),
    )
    var back = _read[DimensionDefinition](
        "136d696e6563726166743a6f766572776f726c647f800602d00fefcdab896745"
        "2301efcdab896745230106706c61696e73800301"
    )
    assert_equal(back.minimum_y, -64)
    assert_equal(back.cloud_height, 192)
    assert_true(back.render_clouds)
    with assert_raises():
        _ = _read[DimensionDefinition]("136d696e")


def test_generation_feature() raises:
    var f = GenerationFeature()
    f.name = "f"
    f.json = List[UInt8]("{}".as_bytes())
    assert_equal(_hex(f), "0166027b7d")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
