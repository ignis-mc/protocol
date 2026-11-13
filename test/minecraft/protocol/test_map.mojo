from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.color import RGBA
from minecraft.protocol.io import Marshaler
from minecraft.protocol.map import (
    MAP_DECORATION_TYPE_MANSION,
    MAP_OBJECT_TYPE_BLOCK,
    MAP_OBJECT_TYPE_ENTITY,
    MapDecoration,
    MapTrackedObject,
    PixelRequest,
)
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


def test_tracked_entity() raises:
    var o = MapTrackedObject()
    o.type = MAP_OBJECT_TYPE_ENTITY
    o.entity_unique_id = Int64(-77)
    assert_equal(_hex(o), "0000000001990100")
    var back = _read[MapTrackedObject]("0000000001990100")
    assert_equal(back.type, MAP_OBJECT_TYPE_ENTITY)
    assert_equal(back.entity_unique_id.value(), -77)
    assert_true(back.block_position is None)


def test_tracked_block() raises:
    var o = MapTrackedObject()
    o.type = MAP_OBJECT_TYPE_BLOCK
    o.block_position = BlockPos(10, 64, -10)
    assert_equal(_hex(o), "01000000000114800113")
    var back = _read[MapTrackedObject]("01000000000114800113")
    assert_true(back.entity_unique_id is None)
    assert_true(back.block_position.value() == BlockPos(10, 64, -10))


def test_tracked_object_rejects_unknown_type() raises:
    with assert_raises(contains="map tracked object type"):
        _ = _read[MapTrackedObject]("020000000000")
    var o = MapTrackedObject()
    o.type = 5
    with assert_raises(contains="map tracked object type"):
        _ = _hex(o)
    with assert_raises():
        _ = _read[MapTrackedObject]("0000000001")


def test_decoration_and_pixel_request() raises:
    var d = MapDecoration()
    d.type = MAP_DECORATION_TYPE_MANSION
    d.rotation = 8
    d.x = 1
    d.y = 2
    d.label = "home"
    d.colour = RGBA(1, 2, 3, 4)
    assert_equal(_hex(d), "0e08010204686f6d6503020104")
    assert_true(
        _read[MapDecoration]("0e08010204686f6d6503020104").colour
        == RGBA(1, 2, 3, 4)
    )
    var p = PixelRequest()
    p.colour = RGBA(1, 2, 3, 4)
    p.index = 513
    assert_equal(_hex(p), "010203040102")
    assert_equal(_read[PixelRequest]("010203040102").index, 513)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
