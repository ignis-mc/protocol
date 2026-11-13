from minecraft.protocol.color import RGBA
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.skin import (
    ARM_SIZE_WIDE,
    EXPRESSION_TYPE_BLINKING,
    PIECE_TYPE_EYES,
    PIECE_TYPE_HAIR,
    SKIN_ANIMATION_HEAD,
    PersonaPiece,
    PersonaPieceTintColour,
    Skin,
    SkinAnimation,
)
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


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


def _pack_id() raises -> UUID:
    return UUID.parse("01234567-89ab-cdef-0123-456789abcdef")


def _tint(
    var piece_type: String, a: RGBA, b: RGBA, c: RGBA, d: RGBA
) -> PersonaPieceTintColour:
    var t = PersonaPieceTintColour()
    t.piece_type = piece_type^
    t.colours[0] = a
    t.colours[1] = b
    t.colours[2] = c
    t.colours[3] = d
    return t^


def _full_skin() raises -> Skin:
    var s = Skin()
    s.skin_id = "skin"
    s.skin_resource_patch = List[UInt8]('{"a":1}'.as_bytes())
    s.skin_image_width = 2
    s.skin_image_height = 1
    s.skin_data = [1, 2, 3, 4, 5, 6, 7, 8]
    var anim = SkinAnimation()
    anim.image_width = 1
    anim.image_height = 1
    anim.image_data = [9, 10, 11, 12]
    anim.animation_type = SKIN_ANIMATION_HEAD
    anim.frame_count = 2
    anim.expression_type = EXPRESSION_TYPE_BLINKING
    s.animations = [anim^]
    s.cape_image_width = 1
    s.cape_image_height = 1
    s.cape_data = [13, 14, 15, 16]
    s.skin_geometry = List[UInt8]("geo".as_bytes())
    s.animation_data = List[UInt8]("ad".as_bytes())
    s.geometry_data_engine_version = List[UInt8]("1.0".as_bytes())
    s.premium_skin = True
    s.persona_skin = True
    s.primary_user = True
    s.cape_id = "cape"
    s.full_id = "full"
    s.skin_colour = RGBA(1, 2, 3, 4)
    s.arm_size = ARM_SIZE_WIDE
    var p1 = PersonaPiece()
    p1.piece_id = "p1"
    p1.piece_type = PIECE_TYPE_HAIR
    p1.pack_id = _pack_id()
    p1.default = True
    var p2 = PersonaPiece()
    p2.piece_id = "p2"
    p2.piece_type = PIECE_TYPE_EYES
    p2.pack_id = _pack_id()
    p2.product_id = "prod"
    s.persona_pieces = [p1^, p2^]
    var opaque = RGBA(0, 0, 0, 0xFF)
    s.piece_tint_colours = [
        _tint(
            "persona_hair",
            RGBA(0x11, 0x22, 0x33, 0xFF),
            RGBA(1, 0, 0, 2),
            RGBA(0, 3, 0, 0),
            RGBA(0, 0, 4, 0),
        ),
        _tint("persona_hand", opaque, opaque, opaque, opaque),
    ]
    s.trusted = True
    s.override_appearance = True
    s.profile_hash = "ph"
    return s^


def test_full_skin_matches_gophertunnel() raises:
    var s = _full_skin()
    var expected = (
        "04736b696e077b2261223a317d02000000010000000801020304050607080101"
        "0000000100000004090a0b0c0100000040010100000001000000040d0e0f1003"
        "67656f03312e3002616404636170650466756c6c0103020104020270310e0000"
        "00efcdab8967452301efcdab896745230101000270320d000000efcdab896745"
        "2301efcdab8967452301000470726f64020468616972332211ff000001020003"
        "0000040000000568616e6473000000ff000000ff000000ff000000ff01010001"
        "010474727565027068"
    )
    assert_equal(_hex(s), expected)


def test_full_skin_round_trip() raises:
    var expected = (
        "04736b696e077b2261223a317d02000000010000000801020304050607080101"
        "0000000100000004090a0b0c0100000040010100000001000000040d0e0f1003"
        "67656f03312e3002616404636170650466756c6c0103020104020270310e0000"
        "00efcdab8967452301efcdab896745230101000270320d000000efcdab896745"
        "2301efcdab8967452301000470726f64020468616972332211ff000001020003"
        "0000040000000568616e6473000000ff000000ff000000ff000000ff01010001"
        "010474727565027068"
    )
    var back = _read[Skin](expected)
    assert_equal(back.skin_id, "skin")
    assert_equal(back.skin_image_width, 2)
    assert_equal(len(back.skin_data), 8)
    assert_equal(len(back.animations), 1)
    assert_equal(back.animations[0].frame_count, 2)
    assert_equal(back.animations[0].expression_type, EXPRESSION_TYPE_BLINKING)
    assert_true(back.skin_colour == RGBA(1, 2, 3, 4))
    assert_equal(back.arm_size, ARM_SIZE_WIDE)
    assert_equal(len(back.persona_pieces), 2)
    assert_true(back.persona_pieces[0].default)
    assert_true(back.persona_pieces[1].pack_id == _pack_id())
    assert_equal(back.persona_pieces[1].product_id, "prod")
    # The wire names `hair` and `hands` map back to login-data names.
    assert_equal(back.piece_tint_colours[0].piece_type, "persona_hair")
    assert_equal(back.piece_tint_colours[1].piece_type, "persona_hand")
    assert_true(
        back.piece_tint_colours[0].colours[0] == RGBA(0x11, 0x22, 0x33, 0xFF)
    )
    assert_true(back.piece_tint_colours[0].colours[1] == RGBA(1, 0, 0, 2))
    assert_true(back.trusted)
    assert_true(back.override_appearance)
    assert_false(back.persona_cape_on_classic_skin)
    assert_equal(back.profile_hash, "ph")
    assert_equal(_hex(back), expected)


def test_empty_skin() raises:
    var s = Skin()
    assert_equal(
        _hex(s),
        (
            "0000000000000000000000000000000000000000000000000000000000000000"
            "0000000000000566616c736500"
        ),
    )
    assert_false(
        _read[Skin](
            "0000000000000000000000000000000000000000000000000000000000000000"
            "0000000000000566616c736500"
        ).trusted
    )


def test_skin_rejects_mismatched_image_sizes() raises:
    var s = _full_skin()
    s.skin_image_width = 3
    with assert_raises(contains="expected size of skin is 3x1"):
        _ = _hex(s)
    var cape = _full_skin()
    cape.cape_data = [1]
    with assert_raises(contains="expected size of cape"):
        _ = _hex(cape)
    var anim = _full_skin()
    anim.animations[0].image_data = [1, 2]
    with assert_raises(contains="expected size of animation 0"):
        _ = _hex(anim)
    # An empty skin claiming a 1x1 image without pixel data.
    var bad = "00" + "00" + "01000000" + "01000000" + "00" * 30
    with assert_raises(contains="serialised skin"):
        _ = _read[Skin](bad)


def test_skin_rejects_truncated_input() raises:
    var expected = (
        "04736b696e077b2261223a317d02000000010000000801020304050607080101"
        "0000000100000004090a0b0c0100000040010100000001000000040d0e0f1003"
        "67656f03312e3002616404636170650466756c6c0103020104020270310e0000"
        "00efcdab8967452301efcdab896745230101000270320d000000efcdab896745"
        "2301efcdab8967452301000470726f64020468616972332211ff000001020003"
        "0000040000000568616e6473000000ff000000ff000000ff000000ff01010001"
        "010474727565027068"
    )
    var raw = hex_decode(expected)
    for cut in [1, 10, 40, len(raw) // 2, len(raw) - 1]:
        var r = Reader(Span(raw)[:cut])
        var s = Skin()
        with assert_raises():
            s.marshal(r)


def test_tint_names_without_prefix_pass_through() raises:
    var t = _tint("unsupported", RGBA(), RGBA(), RGBA(), RGBA())
    var text = _hex(t)
    assert_true(text.startswith("0b" + hex_encode("unsupported".as_bytes())))
    assert_equal(_read[PersonaPieceTintColour](text).piece_type, "unsupported")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
