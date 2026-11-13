from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.entity_metadata import (
    ENTITY_DATA_FLAG_COLLIDABLE,
    ENTITY_DATA_FLAG_NO_AI,
    ENTITY_DATA_FLAG_ON_FIRE,
    ENTITY_DATA_FLAG_SNEAKING,
    ENTITY_DATA_KEY_AIR_SUPPLY,
    ENTITY_DATA_KEY_BED_POSITION,
    ENTITY_DATA_KEY_COLOR_INDEX,
    ENTITY_DATA_KEY_FLAGS,
    ENTITY_DATA_KEY_FLAGS_TWO,
    ENTITY_DATA_KEY_NAME,
    ENTITY_DATA_KEY_NPC_DATA,
    ENTITY_DATA_KEY_PLAYER_FLAGS,
    ENTITY_DATA_KEY_SCALE,
    ENTITY_DATA_KEY_SEAT_OFFSET,
    ENTITY_DATA_KEY_VARIANT,
    EntityDataValue,
    EntityMetadata,
    new_entity_metadata,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

# gophertunnel v1.63.0 encodings (Writer.EntityMetadata, keys sorted).
comptime _NBT_A = "0a000301610200"
comptime _META_ALL = (
    "09"  # nine entries: key, type, legacy type, value
    + "0007078a8080808040"  # flags: int64
    + "0202020d"  # variant: int32
    + "03000009"  # colour index: byte
    + "040404055374657665"  # name: string
    + "0701012c01"  # air supply: int16
    + "1c0606020306"  # bed position: block pos
    + "2603030000c03f"  # scale: float32
    + "280505"  # NPC data: compound tag
    + _NBT_A
    + "3808080000003f0000803f000000c0"  # seat offset: vec3
)
comptime _META_NEW = "030007078280081a0000025c0707808080808080808004"


def _encode(mut m: EntityMetadata) raises -> String:
    var w = Writer()
    m.marshal(w)
    return hex_encode(Span(w.buf))


def _decode(h: String) raises -> EntityMetadata:
    var raw = hex_decode(h)
    var r = Reader(Span(raw))
    var m = EntityMetadata()
    m.marshal(r)
    assert_equal(r.remaining(), 0)
    return m^


def _all_types() raises -> EntityMetadata:
    # Inserted out of key order: the writer sorts like gophertunnel.
    var m = EntityMetadata()
    m.set(ENTITY_DATA_KEY_SEAT_OFFSET, Vec3(0.5, 1, -2))
    m.set(ENTITY_DATA_KEY_NAME, String("Steve"))
    m.set(ENTITY_DATA_KEY_FLAGS, Int64(1 << 40 | 5))
    m.set(
        ENTITY_DATA_KEY_NPC_DATA, NBT(hex_decode(_NBT_A), NETWORK_LITTLE_ENDIAN)
    )
    m.set(ENTITY_DATA_KEY_VARIANT, Int32(-7))
    m.set(ENTITY_DATA_KEY_COLOR_INDEX, UInt8(9))
    m.set(ENTITY_DATA_KEY_AIR_SUPPLY, Int16(300))
    m.set(ENTITY_DATA_KEY_BED_POSITION, BlockPos(1, -2, 3))
    m.set(ENTITY_DATA_KEY_SCALE, Float32(1.5))
    return m^


def test_every_value_type_matches_gophertunnel() raises:
    var m = _all_types()
    assert_equal(_encode(m), _META_ALL)


def test_decode_every_value_type() raises:
    var m = _decode(_META_ALL)
    assert_equal(len(m), 9)
    assert_equal(m.get(ENTITY_DATA_KEY_FLAGS).value()[Int64], 1 << 40 | 5)
    assert_equal(m.get(ENTITY_DATA_KEY_VARIANT).value()[Int32], -7)
    assert_equal(m.get(ENTITY_DATA_KEY_COLOR_INDEX).value()[UInt8], 9)
    assert_equal(m.get(ENTITY_DATA_KEY_NAME).value()[String], "Steve")
    assert_equal(m.get(ENTITY_DATA_KEY_AIR_SUPPLY).value()[Int16], 300)
    assert_equal(m.get(ENTITY_DATA_KEY_SCALE).value()[Float32], 1.5)
    assert_true(
        m.get(ENTITY_DATA_KEY_BED_POSITION).value()[BlockPos]
        == BlockPos(1, -2, 3)
    )
    assert_equal(
        hex_encode(Span(m.get(ENTITY_DATA_KEY_NPC_DATA).value()[NBT].raw)),
        _NBT_A,
    )
    var seat = m.get(ENTITY_DATA_KEY_SEAT_OFFSET).value()[Vec3]
    assert_equal(seat.x, 0.5)
    assert_equal(seat.z, -2)
    # Decoding keeps wire order; re-encoding is byte-identical.
    assert_equal(m.entries[0].key, ENTITY_DATA_KEY_FLAGS)
    assert_equal(_encode(m), _META_ALL)


def test_new_entity_metadata_flags() raises:
    var m = new_entity_metadata()
    m.set_flag(ENTITY_DATA_KEY_FLAGS, ENTITY_DATA_FLAG_ON_FIRE)
    m.set_flag(ENTITY_DATA_KEY_FLAGS, ENTITY_DATA_FLAG_SNEAKING)
    m.set_flag(ENTITY_DATA_KEY_FLAGS, ENTITY_DATA_FLAG_NO_AI)
    m.unset_flag(ENTITY_DATA_KEY_FLAGS, ENTITY_DATA_FLAG_SNEAKING)
    m.set_flag(ENTITY_DATA_KEY_FLAGS_TWO, ENTITY_DATA_FLAG_COLLIDABLE - 64)
    m.set_flag(ENTITY_DATA_KEY_PLAYER_FLAGS, 1)
    assert_equal(_encode(m), _META_NEW)
    assert_true(m.flag(ENTITY_DATA_KEY_FLAGS, ENTITY_DATA_FLAG_NO_AI))
    assert_false(m.flag(ENTITY_DATA_KEY_FLAGS, ENTITY_DATA_FLAG_SNEAKING))
    assert_true(m.flag(ENTITY_DATA_KEY_PLAYER_FLAGS, 1))
    # As in Go, an index past the field width does nothing.
    m.set_flag(ENTITY_DATA_KEY_FLAGS, 70)
    m.set_flag(ENTITY_DATA_KEY_PLAYER_FLAGS, 9)
    assert_false(m.flag(ENTITY_DATA_KEY_FLAGS, 70))
    assert_equal(_encode(m), _META_NEW)


def test_flag_on_missing_or_wrong_key_raises() raises:
    var m = EntityMetadata()
    with assert_raises(contains="no flag key"):
        m.set_flag(ENTITY_DATA_KEY_FLAGS, 0)
    m.set(ENTITY_DATA_KEY_FLAGS, Int32(0))
    with assert_raises(contains="not an int64"):
        _ = m.flag(ENTITY_DATA_KEY_FLAGS, 0)
    m.set(ENTITY_DATA_KEY_PLAYER_FLAGS, Int64(0))
    with assert_raises(contains="not a byte"):
        m.unset_flag(ENTITY_DATA_KEY_PLAYER_FLAGS, 0)


def test_empty_and_set_replace_remove() raises:
    var m = EntityMetadata()
    assert_equal(_encode(m), "00")
    m.set(ENTITY_DATA_KEY_NAME, String("a"))
    m.set(ENTITY_DATA_KEY_NAME, String("b"))
    assert_equal(len(m), 1)
    assert_true(ENTITY_DATA_KEY_NAME in m)
    m.remove(ENTITY_DATA_KEY_NAME)
    assert_false(ENTITY_DATA_KEY_NAME in m)
    assert_true(m.get(ENTITY_DATA_KEY_NAME) is None)


def test_repeated_key_writes_last_entry_once() raises:
    # A Go map would keep only the last value of a repeated key.
    var m = _decode("02" + "0400" + "0001" + "0400" + "0002")
    assert_equal(len(m), 2)
    assert_equal(m.get(4).value()[UInt8], 2)
    assert_equal(_encode(m), "01" + "040000" + "02")


def test_mismatched_legacy_type_is_rejected() raises:
    # Go: invalid value '3' ... does not match cereal selector 4.
    with assert_raises(contains="does not match cereal selector 4"):
        _ = _decode("01" + "04" + "04" + "03" + "00")


def test_unknown_value_type_is_rejected() raises:
    with assert_raises(contains="entity metadata"):
        _ = _decode("01" + "04" + "09" + "09" + "00")


def test_truncated_metadata_is_rejected() raises:
    with assert_raises():
        _ = _decode("02" + "04" + "00" + "00" + "01")
    with assert_raises():
        _ = _decode("01" + "04" + "04" + "04" + "05" + "6869")


def test_huge_count_does_not_preallocate() raises:
    # A count of 2^32-1 with no entries fails on the first missing byte.
    with assert_raises():
        _ = _decode("ffffffff0f")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
