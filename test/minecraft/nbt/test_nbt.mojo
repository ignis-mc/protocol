from minecraft.nbt.nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
    NBT,
    NETWORK_LITTLE_ENDIAN,
    TAG_COMPOUND,
    nbt,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_network_compound_round_trip() raises:
    # {"": {"a": byte 1, "n": int -3, "s": "hi", "l": list[int]{1, 2}, "c": {}}}
    var raw = hex_decode(
        "0a00"  # compound, empty name
        + "010161"
        + "01"  # byte "a" = 1
        + "03016e"
        + "05"  # int "n" = -3 (zigzag 5)
        + "080173"
        + "026869"  # string "s" = "hi"
        + "09016c"
        + "03"
        + "04"
        + "0204"  # list "l" of int, len 2, 1, 2
        + "0a0163"
        + "00"  # compound "c" {}
        + "00"  # end
        + "ff"  # trailing byte, not part of the tag
    )
    var r = Reader(Span(raw))
    var v = NBT()
    nbt(r, v, NETWORK_LITTLE_ENDIAN)
    assert_equal(r.remaining(), 1)
    assert_equal(v.root_type(), TAG_COMPOUND)
    assert_equal(len(v.raw), len(raw) - 1)
    var w = Writer()
    nbt(w, v, NETWORK_LITTLE_ENDIAN)
    assert_equal(
        hex_encode(Span(w.buf)), hex_encode(Span(raw)[0 : len(raw) - 1])
    )


def test_empty_and_end() raises:
    var end: List[UInt8] = [0]
    var r = Reader(Span(end))
    var v = NBT()
    nbt(r, v, NETWORK_LITTLE_ENDIAN)
    assert_true(v.is_empty())
    var w = Writer()
    var none = NBT()
    nbt(w, none, NETWORK_LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(w.buf)), "00")
    var w2 = Writer()
    var empty = NBT.empty_compound(LITTLE_ENDIAN)
    nbt(w2, empty, LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(w2.buf)), "0a000000")


def test_fixed_width_encodings() raises:
    # Little-endian: compound "" { int "x" = 1, string "s" = "a" }
    var le = hex_decode(
        "0a0000"
        + "03"
        + "0100"
        + "78"
        + "01000000"
        + "08"
        + "0100"
        + "73"
        + "0100"
        + "61"
        + "00"
    )
    var r = Reader(Span(le))
    var v = NBT()
    nbt(r, v, LITTLE_ENDIAN)
    assert_equal(r.remaining(), 0)
    var be = hex_decode("0a0000" + "03" + "0001" + "78" + "00000001" + "00")
    var r2 = Reader(Span(be))
    var v2 = NBT()
    nbt(r2, v2, BIG_ENDIAN)
    assert_equal(r2.remaining(), 0)


def test_rejects_malformed() raises:
    var bad_type = hex_decode("0a00" + "0d0161" + "00")
    var r = Reader(Span(bad_type))
    var v = NBT()
    with assert_raises(contains="unknown tag"):
        nbt(r, v, NETWORK_LITTLE_ENDIAN)
    var truncated = hex_decode("0a00" + "080173" + "05" + "6869")
    var r2 = Reader(Span(truncated))
    with assert_raises():
        nbt(r2, v, NETWORK_LITTLE_ENDIAN)
    var negative = hex_decode("0a00" + "070162" + "01" + "00")
    var r3 = Reader(Span(negative))
    with assert_raises(contains="invalid length"):
        nbt(r3, v, NETWORK_LITTLE_ENDIAN)
    # Nesting bomb: lists of lists far beyond the depth limit.
    var deep = List[UInt8]()
    deep.append(0x09)
    deep.append(0x00)
    for _ in range(600):
        deep.append(0x09)
        deep.append(0x02)
    var r4 = Reader(Span(deep))
    with assert_raises():
        nbt(r4, v, NETWORK_LITTLE_ENDIAN)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
