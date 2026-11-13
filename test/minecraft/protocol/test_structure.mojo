from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.math import Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.structure import (
    ANIMATION_MODE_BLOCKS,
    STRUCTURE_MIRROR_Z_AXIS,
    STRUCTURE_ROTATION_ROTATE180,
    StructureSettings,
)
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_structure_settings_match_gophertunnel() raises:
    var s = StructureSettings()
    s.palette_name = "default"
    s.ignore_entities = True
    s.allow_non_ticking_chunks = True
    s.size = BlockPos(16, 32, 48)
    s.offset = BlockPos(-1, 0, 1)
    s.last_editing_player_unique_id = 12345
    s.rotation = STRUCTURE_ROTATION_ROTATE180
    s.mirror = STRUCTURE_MIRROR_Z_AXIS
    s.animation_mode = ANIMATION_MODE_BLOCKS
    s.animation_duration = 1.5
    s.integrity = 0.75
    s.seed = 0xDEADBEEF
    s.pivot = Vec3(0.5, 1, -2)
    var w = Writer()
    s.marshal(w)
    var expected = (
        "0764656661756c74010001204060010002f2c0010202020000c03f0000403fef"
        "beadde0000003f0000803f000000c0"
    )
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = StructureSettings()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.palette_name, "default")
    assert_true(back.ignore_entities)
    assert_true(back.size == BlockPos(16, 32, 48))
    assert_true(back.offset == BlockPos(-1, 0, 1))
    assert_equal(back.last_editing_player_unique_id, 12345)
    assert_equal(back.mirror, STRUCTURE_MIRROR_Z_AXIS)
    assert_equal(back.integrity, 0.75)
    assert_equal(back.seed, 0xDEADBEEF)
    assert_equal(back.pivot.z, -2)
    var truncated = Reader(Span(raw)[: len(raw) - 1])
    var bad = StructureSettings()
    with assert_raises():
        bad.marshal(truncated)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
