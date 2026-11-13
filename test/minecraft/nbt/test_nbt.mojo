from minecraft.nbt.nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
    NBT,
    NETWORK_LITTLE_ENDIAN,
    TAG_COMPOUND,
    nbt,
    nbt_list,
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
    # Go writes a nil map as an empty compound and a nil slice as an empty
    # list.
    assert_equal(hex_encode(Span(w.buf)), "0a0000")
    var wl = Writer()
    var no_list = NBT()
    nbt_list(wl, no_list, NETWORK_LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(wl.buf)), "09000000")
    var wl2 = Writer()
    nbt_list(wl2, no_list, LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(wl2.buf)), "0900000000000000")
    # A value read as a lone TAG_End is written back unchanged.
    var w3 = Writer()
    nbt(w3, v, NETWORK_LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(w3.buf)), "00")
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


def _read(data: List[UInt8], encoding: Int = NETWORK_LITTLE_ENDIAN) raises:
    var r = Reader(Span(data))
    var v = NBT()
    nbt(r, v, encoding)


def _nested_compounds(levels: Int) -> List[UInt8]:
    var out: List[UInt8] = [0x0A, 0x00]
    for _ in range(levels - 1):
        out.append(0x0A)
        out.append(0x01)
        out.append(0x63)
    for _ in range(levels):
        out.append(0x00)
    return out^


def test_depth_limit_matches_gophertunnel() raises:
    # gophertunnel fails reading the entries of a compound nested 512 deep;
    # the walk used to accept 513 levels.
    _read(_nested_compounds(511))
    with assert_raises(contains="nesting too deep"):
        _read(_nested_compounds(512))


def test_rejects_unknown_type_of_empty_list() raises:
    # gophertunnel checks the element type even when the list is empty.
    with assert_raises(contains="unknown tag"):
        _read(hex_decode("0a00" + "09016c" + "0d00" + "00"))
    _read(hex_decode("0a00" + "09016c" + "0000" + "00"))


def test_network_offset_limit() raises:
    # Root (2) + entry header (3) + 4-byte length + n bytes, then TAG_End
    # read at offset 9 + n; gophertunnel refuses tags at 4 MiB or later.
    var limit = 4 * 1024 * 1024
    comptime for over in range(2):
        var n = limit - 10 + over
        var raw: List[UInt8] = [0x0A, 0x00, 0x07, 0x01, 0x61]
        var ux = UInt32(n) << 1
        while ux >= 0x80:
            raw.append(UInt8(ux & 0x7F) | 0x80)
            ux >>= 7
        raw.append(UInt8(ux))
        for _ in range(n):
            raw.append(0)
        raw.append(0)
        comptime if over == 0:
            _read(raw)
        else:
            with assert_raises(contains="limit of bytes read"):
                _read(raw)


def test_string_length_keeps_low_32_bits() raises:
    # A 5-byte varuint length of 2^32 + 1 is 1 in Go.
    _read(hex_decode("0a00" + "0801738180808010" + "78" + "00"))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
