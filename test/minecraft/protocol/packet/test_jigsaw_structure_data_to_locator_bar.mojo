# Expected bytes come from gophertunnel v1.63.0 (header + `Marshal`).
from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.block_pos import BlockPos, ChunkPos
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.jigsaw_structure_data import (
    JigsawStructureData,
)
from minecraft.protocol.packet.lab_table import (
    LAB_TABLE_ACTION_REACT,
    LAB_TABLE_ACTION_RESET,
    LabTable,
)
from minecraft.protocol.packet.lectern_update import LecternUpdate
from minecraft.protocol.packet.lesson_progress import (
    LESSON_ACTION_COMPLETE,
    LessonProgress,
)
from minecraft.protocol.packet.level_chunk import LevelChunk
from minecraft.protocol.packet.level_event import (
    LEVEL_EVENT_PARTICLE_LEGACY_EVENT,
    LEVEL_EVENT_PARTICLES_DESTROY_BLOCK,
    PARTICLE_TYPE_YELLOW_POPLAR_LEAVES,
    LevelEvent,
)
from minecraft.protocol.packet.level_event_generic import LevelEventGeneric
from minecraft.protocol.packet.level_sound_event import (
    SOUND_EVENT_HIT,
    SOUND_EVENT_PLACE,
    SOUND_EVENT_UNDEFINED,
    LevelSoundEvent,
)
from minecraft.protocol.packet.locator_bar import LocatorBar
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.uuid import UUID
from minecraft.protocol.waypoint import (
    LocatorBarWaypoint,
    WaypointWorldPosition,
)
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime JIGSAW_STRUCTURE_DATA_HEX = "b9020a0008016b017600"

comptime LAB_TABLE_HEX = "6d0102040604"

comptime LECTERN_UPDATE_HEX = "7d020a018c010a"

comptime LESSON_PROGRESS_HEX = "b70102b401066c6573736f6e"

comptime LEVEL_CHUNK_HEX = "3a060702180000000309080701"

comptime LEVEL_CHUNK_LIMITED_HEX = (
    "3a00000002010a01020100000000000000ffffffffffffffff0000"
)

comptime LEVEL_EVENT_HEX = "19a21f0000c03f00008042000020c0a413"

comptime LEVEL_EVENT_GENERIC_HEX = "7cd41f0501610000803f"

comptime LEVEL_SOUND_EVENT_HEX = (
    "7b05706c6163650000803f000000400000404054106d696e6563726166743a706c61"
    "7965720101ffffffffffffffff00"
)

comptime LEVEL_SOUND_EVENT_FIRE_AT_HEX = (
    "7b036869740000000000000000000000000000000000000000000000000100008040"
    "0000a0400000c040"
)

comptime LOCATOR_BAR_HEX = (
    "d502017766554433221100ffeeddccbbaa9988030000000101010000803f00000040"
    "0000404000000001ffffffff00011101"
)


def _round_trip[P: Packet](mut pk: P, expected: StringSpan) raises -> P:
    assert_equal(hex_encode(Span(encode_packet(pk))), String(expected))
    var raw = hex_decode(expected)
    var back = PacketData.parse(Span(raw)).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), String(expected))
    return back^


def _truncated[P: Packet](expected: StringSpan) raises:
    var raw = hex_decode(expected)
    _ = raw.pop()
    with assert_raises():
        _ = PacketData.parse(Span(raw)).decode[P]()


def test_jigsaw_structure_data() raises:
    var pk = JigsawStructureData()
    # {"k": TAG_String("v")} in network little-endian.
    pk.structure_data = NBT(
        hex_decode("0a0008016b017600"), NETWORK_LITTLE_ENDIAN
    )
    var back = _round_trip(pk, JIGSAW_STRUCTURE_DATA_HEX)
    assert_equal(hex_encode(Span(back.structure_data.raw)), "0a0008016b017600")
    _truncated[JigsawStructureData](JIGSAW_STRUCTURE_DATA_HEX)


def test_lab_table() raises:
    assert_equal(LAB_TABLE_ACTION_RESET, 2)
    var pk = LabTable()
    pk.action_type = LAB_TABLE_ACTION_REACT
    pk.position = BlockPos(1, 2, 3)
    pk.reaction_type = 4
    var back = _round_trip(pk, LAB_TABLE_HEX)
    assert_equal(back.action_type, LAB_TABLE_ACTION_REACT)
    assert_true(back.position == BlockPos(1, 2, 3))
    assert_equal(back.reaction_type, 4)
    _truncated[LabTable](LAB_TABLE_HEX)


def test_lectern_update() raises:
    var pk = LecternUpdate()
    pk.page = 2
    pk.page_count = 10
    pk.position = BlockPos(-1, 70, 5)
    var back = _round_trip(pk, LECTERN_UPDATE_HEX)
    assert_equal(back.page, 2)
    assert_equal(back.page_count, 10)
    assert_true(back.position == BlockPos(-1, 70, 5))


def test_lesson_progress() raises:
    var pk = LessonProgress()
    pk.identifier = "lesson"
    pk.action = LESSON_ACTION_COMPLETE
    pk.score = 90
    var back = _round_trip(pk, LESSON_PROGRESS_HEX)
    assert_equal(back.identifier, "lesson")
    assert_equal(back.action, LESSON_ACTION_COMPLETE)
    assert_equal(back.score, 90)
    _truncated[LessonProgress](LESSON_PROGRESS_HEX)


def test_level_chunk() raises:
    var pk = LevelChunk()
    pk.position = ChunkPos(3, -4)
    pk.dimension = 1
    pk.sub_chunk_count = 24
    pk.raw_payload = [9, 8, 7]
    pk.client_biome_update = True
    var back = _round_trip(pk, LEVEL_CHUNK_HEX)
    assert_true(back.position == ChunkPos(3, -4))
    assert_equal(back.dimension, 1)
    assert_equal(back.sub_chunk_count, 24)
    assert_true(back.sub_chunk_limit is None)
    assert_equal(len(back.raw_payload), 3)
    assert_true(back.client_biome_update)
    _truncated[LevelChunk](LEVEL_CHUNK_HEX)


def test_level_chunk_limited_cached() raises:
    var pk = LevelChunk()
    pk.sub_chunk_count = 2
    pk.sub_chunk_limit = Int32(5)
    pk.cache_enabled = True
    pk.blob_hashes = [1, 0xFFFFFFFFFFFFFFFF]
    var back = _round_trip(pk, LEVEL_CHUNK_LIMITED_HEX)
    assert_equal(back.sub_chunk_limit.value(), 5)
    assert_true(back.cache_enabled)
    assert_equal(len(back.blob_hashes), 2)
    assert_equal(back.blob_hashes[1], 0xFFFFFFFFFFFFFFFF)


def test_level_chunk_too_many_sub_chunks() raises:
    var pk = LevelChunk()
    pk.sub_chunk_count = 65
    with assert_raises(contains="must not exceed 64"):
        _ = encode_packet(pk)
    # Position (0, 0), dimension 0, sub-chunk count 65.
    var raw = hex_decode("3a00000041000000000000")
    with assert_raises(contains="must not exceed 64"):
        _ = PacketData.parse(Span(raw)).decode[LevelChunk]()


def test_level_event() raises:
    assert_equal(PARTICLE_TYPE_YELLOW_POPLAR_LEAVES, 104)
    assert_equal(LEVEL_EVENT_PARTICLE_LEGACY_EVENT, 0x4000)
    var pk = LevelEvent()
    pk.event_type = LEVEL_EVENT_PARTICLES_DESTROY_BLOCK
    pk.position = Vec3(1.5, 64, -2.5)
    pk.event_data = 1234
    var back = _round_trip(pk, LEVEL_EVENT_HEX)
    assert_equal(back.event_type, LEVEL_EVENT_PARTICLES_DESTROY_BLOCK)
    assert_equal(back.position.z, -2.5)
    assert_equal(back.event_data, 1234)
    _truncated[LevelEvent](LEVEL_EVENT_HEX)


def test_level_event_generic() raises:
    var pk = LevelEventGeneric()
    pk.event_id = 2026
    # Loose tags, not wrapped in a compound: TAG_Float "a" = 1.0.
    pk.serialised_event_data = [5, 1, 0x61, 0, 0, 0x80, 0x3F]
    var back = _round_trip(pk, LEVEL_EVENT_GENERIC_HEX)
    assert_equal(back.event_id, 2026)
    assert_equal(len(back.serialised_event_data), 7)
    assert_equal(back.serialised_event_data[6], 0x3F)


def test_level_sound_event() raises:
    assert_equal(SOUND_EVENT_UNDEFINED, "undefined")
    var pk = LevelSoundEvent()
    pk.sound_type = SOUND_EVENT_PLACE
    pk.position = Vec3(1, 2, 3)
    pk.extra_data = 42
    pk.entity_type = "minecraft:player"
    pk.baby_mob = True
    pk.disable_relative_volume = True
    pk.entity_unique_id = -1
    var back = _round_trip(pk, LEVEL_SOUND_EVENT_HEX)
    assert_equal(back.sound_type, "place")
    assert_equal(back.extra_data, 42)
    assert_equal(back.entity_type, "minecraft:player")
    assert_true(back.baby_mob)
    assert_true(back.disable_relative_volume)
    assert_equal(back.entity_unique_id, -1)
    assert_true(back.fire_at_position is None)
    _truncated[LevelSoundEvent](LEVEL_SOUND_EVENT_HEX)


def test_level_sound_event_fire_at() raises:
    var pk = LevelSoundEvent()
    pk.sound_type = SOUND_EVENT_HIT
    pk.fire_at_position = Vec3(4, 5, 6)
    var back = _round_trip(pk, LEVEL_SOUND_EVENT_FIRE_AT_HEX)
    assert_equal(back.fire_at_position.value().y, 5)


def test_locator_bar() raises:
    var pk = LocatorBar()
    var w = LocatorBarWaypoint()
    w.group_handle = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    w.action = 1
    w.waypoint.update_flag = 3
    w.waypoint.visible = True
    var pos = WaypointWorldPosition()
    pos.position = Vec3(1, 2, 3)
    w.waypoint.world_position = pos^
    w.waypoint.colour = Int32(-1)
    w.waypoint.actor_unique_id = Int64(-9)
    pk.waypoints = [w^]
    var back = _round_trip(pk, LOCATOR_BAR_HEX)
    assert_equal(back.waypoints[0].action, 1)
    assert_true(back.waypoints[0].waypoint.visible.value())
    assert_equal(back.waypoints[0].waypoint.colour.value(), -1)
    assert_equal(back.waypoints[0].waypoint.actor_unique_id.value(), -9)
    _truncated[LocatorBar](LOCATOR_BAR_HEX)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
