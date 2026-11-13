from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.color import RGBA
from minecraft.protocol.io import (
    block_pos,
    rgba,
    string_slice,
    uuid,
    varint32_slice,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_varints_match_gophertunnel() raises:
    var w = Writer()
    var a = UInt32(300)
    var b = Int32(-1)
    var c = Int32(64)
    var d = UInt64(0xFFFFFFFFFFFFFFFF)
    var e = Int64(-9223372036854775808)
    w.varuint32(a)
    w.varint32(b)
    w.varint32(c)
    w.varuint64(d)
    w.varint64(e)
    assert_equal(
        hex_encode(Span(w.buf)),
        "ac02018001ffffffffffffffffff01ffffffffffffffffff01",
    )
    var r = Reader(Span(w.buf))
    var a2 = UInt32(0)
    var b2 = Int32(0)
    var c2 = Int32(0)
    var d2 = UInt64(0)
    var e2 = Int64(0)
    r.varuint32(a2)
    r.varint32(b2)
    r.varint32(c2)
    r.varuint64(d2)
    r.varint64(e2)
    assert_equal(a2, 300)
    assert_equal(b2, -1)
    assert_equal(c2, 64)
    assert_equal(d2, 0xFFFFFFFFFFFFFFFF)
    assert_equal(e2, -9223372036854775808)
    assert_equal(r.remaining(), 0)


def test_fixed_width_and_floats() raises:
    var w = Writer()
    var a = UInt16(0x0102)
    var b = Int32(-2)
    var c = Int32(0x01020304)
    var f = Float32(1.5)
    var g = Float64(-2.25)
    var t = True
    w.uint16(a)
    w.int32(b)
    w.be_int32(c)
    w.float32(f)
    w.float64(g)
    w.bool(t)
    assert_equal(
        hex_encode(Span(w.buf)),
        "0201feffffff010203040000c03f00000000000002c001",
    )
    var r = Reader(Span(w.buf))
    var a2 = UInt16(0)
    var b2 = Int32(0)
    var c2 = Int32(0)
    var f2 = Float32(0)
    var g2 = Float64(0)
    var t2 = False
    r.uint16(a2)
    r.int32(b2)
    r.be_int32(c2)
    r.float32(f2)
    r.float64(g2)
    r.bool(t2)
    assert_equal(a2, 0x0102)
    assert_equal(b2, -2)
    assert_equal(c2, 0x01020304)
    assert_equal(f2, 1.5)
    assert_equal(g2, -2.25)
    assert_true(t2)


def test_strings_and_lists() raises:
    var w = Writer()
    var s = String("héllo")
    var names: List[String] = ["a", "bc"]
    var nums: List[Int32] = [1, -1]
    w.string(s)
    string_slice(w, names)
    varint32_slice(w, nums)
    var r = Reader(Span(w.buf))
    var s2 = String()
    var names2 = List[String]()
    var nums2 = List[Int32]()
    r.string(s2)
    string_slice(r, names2)
    varint32_slice(r, nums2)
    assert_equal(s2, "héllo")
    assert_equal(len(names2), 2)
    assert_equal(names2[1], "bc")
    assert_equal(nums2[1], -1)


def test_composites() raises:
    var w = Writer()
    var pos = BlockPos(-1, 64, 300)
    var colour = RGBA(1, 2, 3, 4)
    var id = UUID.parse("01234567-89ab-cdef-0011-223344556677")
    block_pos(w, pos)
    rgba(w, colour)
    uuid(w, id)
    # UUID halves are little-endian: gophertunnel reverses each 8-byte half.
    assert_equal(
        hex_encode(Span(w.buf)[len(w.buf) - 16 : len(w.buf)]),
        "efcdab89674523017766554433221100",
    )
    var r = Reader(Span(w.buf))
    var pos2 = BlockPos()
    var colour2 = RGBA()
    var id2 = UUID()
    block_pos(r, pos2)
    rgba(r, colour2)
    uuid(r, id2)
    assert_true(pos2 == pos)
    assert_true(colour2 == colour)
    assert_equal(String(id2), "01234567-89ab-cdef-0011-223344556677")


def test_reader_rejects_truncated_and_oversized() raises:
    var short: List[UInt8] = [0x05, 0x61]
    var r = Reader(Span(short))
    var s = String()
    with assert_raises(contains="exceeds remaining"):
        r.string(s)
    var huge: List[UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0x0F]
    var r2 = Reader(Span(huge))
    var names = List[String]()
    with assert_raises(contains="too long"):
        string_slice(r2, names)
    var endless: List[UInt8] = [0x80, 0x80, 0x80, 0x80, 0x80, 0x01]
    var r3 = Reader(Span(endless))
    var v = UInt32(0)
    with assert_raises(contains="overflows"):
        r3.varuint32(v)
    var r4 = Reader(Span(short))
    var x = UInt64(0)
    with assert_raises():
        r4.uint64(x)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
