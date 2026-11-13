from minecraft.protocol.color import RGBA
from minecraft.protocol.math import Vec2, Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.shape import (
    PRIMITIVE_SHAPE_TEXT,
    SHAPE_DATA_CONE,
    SHAPE_DATA_TEXT,
    ArrowShape,
    BoxShape,
    ConeShape,
    CylinderShape,
    EllipsoidShape,
    LastShape,
    LineShape,
    PrimitiveShape,
    PyramidShape,
    ShapeData,
    ShapeDataVariant,
    SphereShape,
    TextShape,
    shape_data,
)
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _check(var s: PrimitiveShape, expected: String) raises -> PrimitiveShape:
    var w = Writer()
    s.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = PrimitiveShape()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    var w2 = Writer()
    back.marshal(w2)
    assert_equal(hex_encode(Span(w2.buf)), expected)
    return back^


def _shape(id: UInt64, var data: ShapeDataVariant) -> PrimitiveShape:
    var s = PrimitiveShape()
    s.network_id = id
    s.extra_shape_data = ShapeData(data^)
    return s^


def test_last_shape() raises:
    _ = _check(_shape(300, LastShape()), "ac0200000000000000000000")


def test_arrow_shape() raises:
    var a = ArrowShape()
    a.arrow_end_location = Vec3(1, 2, 3)
    a.arrow_head_length = Float32(0.5)
    a.arrow_head_radius = Float32(0.25)
    a.segments = UInt8(8)
    _ = _check(
        _shape(301, a^),
        "ad02000000000000000000"
        + "01"
        + "01"
        + "0000803f0000004000004040"
        + "01"
        + "0000003f"
        + "01"
        + "0000803e"
        + "01"
        + "08",
    )


def test_text_shape_with_every_optional() raises:
    var t = TextShape()
    t.text = "hi"
    t.use_rotation = True
    t.background_colour = RGBA(1, 2, 3, 4)
    t.line_gap_height = 0.5
    t.depth_test = True
    t.show_backface_text = True
    var s = _shape(302, t^)
    s.dimension_id = Int32(1)
    s.attached_to_entity_id = Int64(-9)
    s.type = PRIMITIVE_SHAPE_TEXT
    s.location = Vec3(1, 2, 3)
    s.scale = Float32(2)
    s.rotation = Vec3(0, 90, 0)
    s.total_time_left = Float32(10)
    s.max_render_distance = Float32(64)
    s.colour = RGBA(255, 128, 0, 200)
    var back = _check(
        s^,
        "ae02"
        + "0104"  # type
        + "01"
        + "0000803f0000004000004040"  # location
        + "01"
        + "00000040"  # scale
        + "01"
        + "00000000"
        + "0000b442"
        + "00000000"  # rotation
        + "01"
        + "00002041"  # total time left
        + "01"
        + "00008042"  # max render distance
        + "01"
        + "0080ffc8"  # colour, big-endian ARGB
        + "0102"  # dimension
        + "0111"  # attached entity
        + "02"
        + "026869"
        + "01"
        + "01"
        + "03020104"  # text, background
        + "0000003f"
        + "01"
        + "00"
        + "01",
    )
    assert_equal(back.extra_shape_data.shape_data_type(), SHAPE_DATA_TEXT)
    ref text = back.extra_shape_data.value[TextShape]
    assert_true(text.background_colour.value() == RGBA(1, 2, 3, 4))
    assert_true(back.colour.value() == RGBA(255, 128, 0, 200))


def test_box_line_sphere() raises:
    var box = BoxShape()
    box.box_bound = Vec3(1, 1, 2)
    _ = _check(
        _shape(303, box^), "af02000000000000000000030000803f0000803f00000040"
    )
    var line = LineShape()
    line.line_end_location = Vec3(3, 4, 5)
    _ = _check(
        _shape(304, line^), "b0020000000000000000000400004040000080400000a040"
    )
    var sphere = SphereShape()
    sphere.segments = 20
    _ = _check(_shape(305, sphere^), "b1020000000000000000000514")


def test_cylinder_pyramid_ellipsoid_cone() raises:
    var c = CylinderShape()
    c.radius_x = Vec2(1, 2)
    c.radius_z = Vec2(3, 4)
    c.height = 5
    c.num_segments = 6
    _ = _check(
        _shape(306, c^),
        "b202000000000000000000060000803f0000004000004040000080400000a04006",
    )
    var p = PyramidShape()
    p.width = 2
    p.depth = Float32(3)
    p.height = 4
    _ = _check(
        _shape(307, p^), "b3020000000000000000000700000040010000404000008040"
    )
    var e = EllipsoidShape()
    e.radii = Vec3(1, 2, 3)
    e.segments_per_axis = 9
    _ = _check(
        _shape(308, e^), "b402000000000000000000080000803f000000400000404009"
    )
    var cone = ConeShape()
    cone.radii = Vec2(1, 2)
    cone.height = 3
    cone.num_segments = 10
    var back = _check(
        _shape(309, cone^), "b502000000000000000000090000803f00000040000040400a"
    )
    assert_equal(back.extra_shape_data.shape_data_type(), SHAPE_DATA_CONE)


def test_unknown_shape_type_is_rejected() raises:
    # Go: unknown value '0xa' for enum type 'debug shape data type'.
    var raw = hex_decode("0a")
    var r = Reader(Span(raw))
    var s = ShapeData()
    with assert_raises(contains="debug shape data type"):
        shape_data(r, s)
    var short = hex_decode("03" + "0000803f")
    var r2 = Reader(Span(short))
    with assert_raises():
        shape_data(r2, s)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
