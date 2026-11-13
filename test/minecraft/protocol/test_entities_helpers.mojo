from minecraft.protocol.entities_helpers import (
    func_slice,
    func_slice_of_len,
    marshal_variant,
    optional_func,
)
from minecraft.protocol.io import IO, vec3
from minecraft.protocol.math import Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.shape import BoxShape, SphereShape
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true
from std.utils import Variant


def _fields[
    I: IO
](mut io: I, mut floats: List[Float32], mut pos: Optional[Vec3]) raises:
    func_slice[I.float32](io, floats)
    optional_func[vec3[I]](io, pos)


def test_func_slice_and_optional_func() raises:
    var floats: List[Float32] = [1, 2]
    var pos: Optional[Vec3] = Vec3(1, 2, 3)
    var w = Writer()
    _fields(w, floats, pos)
    comptime expected = (
        "02" + "0000803f" + "00000040" + "01" + "0000803f0000004000004040"
    )
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var floats2 = List[Float32]()
    var pos2: Optional[Vec3] = None
    _fields(r, floats2, pos2)
    assert_equal(len(floats2), 2)
    assert_equal(pos2.value().z, 3)
    var w2 = Writer()
    var none: Optional[Vec3] = None
    var empty = List[Float32]()
    _fields(w2, empty, none)
    assert_equal(hex_encode(Span(w2.buf)), "0000")


def test_func_slice_limits() raises:
    var raw = hex_decode("8108")
    var r = Reader(Span(raw))
    var x = List[UInt8]()
    with assert_raises(contains="slice length"):
        func_slice[Reader.uint8](r, x)
    var raw2 = hex_decode("0102")
    var r2 = Reader(Span(raw2))
    with assert_raises(contains="exceeds remaining"):
        func_slice_of_len[Reader.uint8](r2, 3, x)


def test_marshal_variant_dispatches() raises:
    var s = SphereShape()
    s.segments = 7
    var v = Variant[BoxShape, SphereShape](s^)
    var w = Writer()
    marshal_variant(w, v)
    assert_equal(hex_encode(Span(w.buf)), "07")
    var raw = hex_decode("09")
    var r = Reader(Span(raw))
    marshal_variant(r, v)
    assert_true(v.isa[SphereShape]())
    assert_equal(v[SphereShape].segments, 9)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
