from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.math import Vec2, Vec3
from minecraft.protocol.misc_helpers import (
    optional_actor_unique_id,
    optional_block_pos,
    optional_byte_slice,
    optional_uint64,
    optional_uuid,
    optional_vec2,
    optional_vec3,
    uint32_slice,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_optionals_write_flag_then_value() raises:
    var w = Writer()
    var a: Optional[Int64] = Int64(-1)
    var b: Optional[UInt64] = None
    var c: Optional[List[UInt8]] = List[UInt8]([UInt8(7)])
    var d: Optional[BlockPos] = BlockPos(1, 2, 3)
    var e: Optional[Vec2] = None
    var f: Optional[Vec3] = Vec3(0, 0, 0)
    var g: Optional[UUID] = UUID()
    optional_actor_unique_id(w, a)
    optional_uint64(w, b)
    optional_byte_slice(w, c)
    optional_block_pos(w, d)
    optional_vec2(w, e)
    optional_vec3(w, f)
    optional_uuid(w, g)
    var expected = (
        "0101"
        + "00"
        + "010107"
        + "01020406"
        + "00"
        + "01"
        + "00" * 12
        + "01"
        + "00" * 16
    )
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var a2: Optional[Int64] = None
    var b2: Optional[UInt64] = UInt64(5)
    var c2: Optional[List[UInt8]] = None
    var d2: Optional[BlockPos] = None
    var e2: Optional[Vec2] = Vec2(1, 1)
    var f2: Optional[Vec3] = None
    var g2: Optional[UUID] = None
    optional_actor_unique_id(r, a2)
    optional_uint64(r, b2)
    optional_byte_slice(r, c2)
    optional_block_pos(r, d2)
    optional_vec2(r, e2)
    optional_vec3(r, f2)
    optional_uuid(r, g2)
    assert_equal(r.remaining(), 0)
    assert_equal(a2.value(), -1)
    assert_true(b2 is None)
    assert_equal(c2.value()[0], 7)
    assert_true(d2.value() == BlockPos(1, 2, 3))
    assert_true(e2 is None)
    assert_true(f2 is not None)
    assert_true(g2.value().is_nil())


def test_uint32_slice() raises:
    var w = Writer()
    var xs: List[UInt32] = [1, 0x01020304]
    uint32_slice(w, xs)
    assert_equal(hex_encode(Span(w.buf)), "020100000004030201")
    var raw = hex_decode("020100000004030201")
    var r = Reader(Span(raw))
    var back = List[UInt32]()
    uint32_slice(r, back)
    assert_equal(back[1], 0x01020304)
    var big = hex_decode("ffff03")
    var r2 = Reader(Span(big))
    with assert_raises():
        uint32_slice(r2, back)
    var short = hex_decode("0201000000")
    var r3 = Reader(Span(short))
    with assert_raises():
        uint32_slice(r3, back)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
