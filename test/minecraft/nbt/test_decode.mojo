from std.math import inf, isnan, nan

from minecraft.nbt.decode import decode, decode_from, from_nbt
from minecraft.nbt.encode import encode
from minecraft.nbt.encoding import MAX_DEPTH, MAX_ELEMENTS, MAX_NETWORK_OFFSET
from minecraft.nbt.nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
    NBT,
    NETWORK_LITTLE_ENDIAN,
    TAG_BYTE,
    TAG_BYTE_ARRAY,
    TAG_COMPOUND,
    TAG_DOUBLE,
    TAG_END,
    TAG_FLOAT,
    TAG_INT,
    TAG_INT_ARRAY,
    TAG_LIST,
    TAG_LONG,
    TAG_LONG_ARRAY,
    TAG_SHORT,
    TAG_STRING,
    nbt,
)
from minecraft.nbt.tree import Tree
from minecraft.protocol.reader import Reader
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

comptime ENCODINGS = [NETWORK_LITTLE_ENDIAN, LITTLE_ENDIAN, BIG_ENDIAN]


def _every_tag() raises -> Tree:
    var t = Tree()
    var r = t.root()
    _ = t.put_byte(r, "byte", 0x80)
    _ = t.put_short(r, "short", -12345)
    _ = t.put_int(r, "int", 123456789)
    _ = t.put_long(r, "long", -1234567890123)
    _ = t.put_float(r, "float", 3.25)
    _ = t.put_double(r, "double", -1e300)
    var ba: List[UInt8] = [9, 8, 7]
    _ = t.put_byte_array(r, "byte_array", ba)
    _ = t.put_string(r, "string", "text")
    var l = t.put_list(r, "list")
    _ = t.append_string(l, "x")
    var c = t.put_compound(r, "compound")
    _ = t.put_bool(c, "flag", True)
    var ia: List[Int32] = [Int32.MIN, 0, Int32.MAX]
    _ = t.put_int_array(r, "int_array", ia)
    var la: List[Int64] = [Int64.MIN, Int64.MAX]
    _ = t.put_long_array(r, "long_array", la)
    return t^


def _check_every_tag(d: Tree) raises:
    var r = d.root()
    assert_equal(d.type_of(r), TAG_COMPOUND)
    assert_equal(d.length(r), 12)
    var types: List[UInt8] = [
        TAG_BYTE,
        TAG_SHORT,
        TAG_INT,
        TAG_LONG,
        TAG_FLOAT,
        TAG_DOUBLE,
        TAG_BYTE_ARRAY,
        TAG_STRING,
        TAG_LIST,
        TAG_COMPOUND,
        TAG_INT_ARRAY,
        TAG_LONG_ARRAY,
    ]
    var children = d.children(r)
    for i in range(len(types)):
        assert_equal(d.type_of(children[i]), types[i])
    assert_equal(d.get_byte(r, "byte"), 0x80)
    assert_equal(d.get_short(r, "short"), -12345)
    assert_equal(d.get_int(r, "int"), 123456789)
    assert_equal(d.get_long(r, "long"), -1234567890123)
    assert_equal(d.get_float(r, "float"), 3.25)
    assert_equal(d.get_double(r, "double"), -1e300)
    assert_equal(d.get_byte_array(r, "byte_array"), [9, 8, 7])
    assert_equal(d.get_string(r, "string"), "text")
    var l = d.get_list(r, "list")
    assert_equal(d.elem_type(l), TAG_STRING)
    assert_equal(d.as_string(d.at(l, 0)), "x")
    assert_true(d.get_bool(d.get_compound(r, "compound"), "flag"))
    assert_equal(
        d.get_int_array(r, "int_array"), [Int32.MIN, Int32(0), Int32.MAX]
    )
    assert_equal(d.get_long_array(r, "long_array"), [Int64.MIN, Int64.MAX])


def test_round_trip_every_tag_all_encodings() raises:
    var t = _every_tag()
    comptime for k in range(3):
        comptime enc = ENCODINGS[k]
        var raw = encode(t, enc)
        var d = decode(Span(raw), enc)
        _check_every_tag(d)
        assert_equal(hex_encode(Span(encode(d, enc))), hex_encode(Span(raw)))


def test_float_specials_keep_their_bits() raises:
    var t = Tree()
    _ = t.put_float(t.root(), "nan", nan[DType.float32]())
    _ = t.put_float(t.root(), "inf", inf[DType.float32]())
    _ = t.put_double(t.root(), "neg_zero", -0.0)
    comptime for k in range(3):
        comptime enc = ENCODINGS[k]
        var raw = encode(t, enc)
        var d = decode(Span(raw), enc)
        assert_true(isnan(d.get_float(d.root(), "nan")))
        assert_equal(d.get_float(d.root(), "inf"), inf[DType.float32]())
        assert_equal(hex_encode(Span(encode(d, enc))), hex_encode(Span(raw)))
    var le = encode(t, LITTLE_ENDIAN)
    # -0.0 as a little-endian double ends in 0x80.
    assert_equal(le[len(le) - 2], 0x80)


def test_root_end_is_empty_tree() raises:
    var d = decode(Span(hex_decode("00")), NETWORK_LITTLE_ENDIAN)
    assert_true(d.is_empty())
    assert_equal(hex_encode(Span(encode(d, NETWORK_LITTLE_ENDIAN))), "00")
    assert_true(from_nbt(NBT()).is_empty())


def test_root_name_is_kept() raises:
    var d = decode(Span(hex_decode("0a0004726f6f7400")), BIG_ENDIAN)
    assert_equal(d.name(d.root()), "root")
    var prim = decode(Span(hex_decode("03000a")), NETWORK_LITTLE_ENDIAN)
    assert_equal(d.type_of(d.root()), TAG_COMPOUND)
    assert_equal(prim.as_int(prim.root()), 5)


def test_trailing_bytes_and_decode_from() raises:
    var raw = hex_decode("0a0000" + "ff" + "0a0000")
    with assert_raises(contains="trailing"):
        _ = decode(Span(raw), NETWORK_LITTLE_ENDIAN)
    var pos = 0
    _ = decode_from(Span(raw), pos, NETWORK_LITTLE_ENDIAN)
    assert_equal(pos, 3)
    pos = 4
    var second = decode_from(Span(raw), pos, NETWORK_LITTLE_ENDIAN)
    assert_equal(pos, 7)
    assert_equal(second.length(second.root()), 0)


def test_duplicate_names_keep_order_last_wins() raises:
    # {"a": byte 1, "a": byte 2}
    var raw = hex_decode("0a00" + "01016101" + "01016102" + "00")
    var d = decode(Span(raw), NETWORK_LITTLE_ENDIAN)
    assert_equal(d.length(d.root()), 2)
    assert_equal(d.get_byte(d.root(), "a"), 2)
    assert_equal(
        hex_encode(Span(encode(d, NETWORK_LITTLE_ENDIAN))),
        hex_encode(Span(raw)),
    )


def test_invalid_utf8_is_kept_raw() raises:
    var raw = hex_decode("0a00" + "080173" + "02c328" + "00")
    var d = decode(Span(raw), NETWORK_LITTLE_ENDIAN)
    with assert_raises():
        _ = d.get_string(d.root(), "s")
    assert_equal(d.as_string_bytes(d.require(d.root(), "s")), [0xC3, 0x28])
    assert_equal(
        hex_encode(Span(encode(d, NETWORK_LITTLE_ENDIAN))),
        hex_encode(Span(raw)),
    )


def test_from_nbt_reads_packet_field() raises:
    var raw = hex_decode("0a00" + "03016e" + "05" + "080173" + "026869" + "00")
    var r = Reader(Span(raw))
    var v = NBT()
    nbt(r, v, NETWORK_LITTLE_ENDIAN)
    var d = from_nbt(v)
    assert_equal(d.get_int(d.root(), "n"), -3)
    assert_equal(d.get_string(d.root(), "s"), "hi")


# ===----------------------------------------------------------------------=== #
# Rejections
# ===----------------------------------------------------------------------=== #


def _nested_compounds(levels: Int) -> List[UInt8]:
    """Network bytes of `levels` compounds nested in one another."""
    var out: List[UInt8] = [0x0A, 0x00]
    for _ in range(levels - 1):
        out.append(0x0A)
        out.append(0x01)
        out.append(0x63)
    for _ in range(levels):
        out.append(0x00)
    return out^


def _lists_of_lists(levels: Int) -> List[UInt8]:
    var out: List[UInt8] = [0x09, 0x00]
    for _ in range(levels - 1):
        out.append(0x09)
        out.append(0x02)
    out.append(0x00)
    out.append(0x00)
    return out^


def test_rejects_depth_bombs() raises:
    var ok = decode(
        Span(_nested_compounds(MAX_DEPTH - 1)), NETWORK_LITTLE_ENDIAN
    )
    assert_equal(ok.length(ok.root()), 1)
    with assert_raises(contains="maximum nesting depth"):
        _ = decode(Span(_nested_compounds(MAX_DEPTH)), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="maximum nesting depth"):
        _ = decode(Span(_nested_compounds(100000)), NETWORK_LITTLE_ENDIAN)
    _ = decode(Span(_lists_of_lists(MAX_DEPTH - 1)), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="maximum nesting depth"):
        _ = decode(Span(_lists_of_lists(MAX_DEPTH)), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="maximum nesting depth"):
        _ = decode(Span(_lists_of_lists(100000)), NETWORK_LITTLE_ENDIAN)


def test_rejects_huge_lengths() raises:
    # Lengths of 2^31 - 1 must fail before allocating anything.
    with assert_raises(contains="unexpected buffer end"):
        _ = decode(
            Span(hex_decode("0a00" + "070162" + "d00f")), NETWORK_LITTLE_ENDIAN
        )
    var cases: List[String] = [
        "0a00" + "070162" + "feffffff0f",  # byte array
        "0a00" + "0b0169" + "feffffff0f",  # int array
        "0a00" + "0c016c" + "feffffff0f",  # long array
        "0a00" + "09016c" + "03" + "feffffff0f",  # list of int
        "0a00" + "09016c" + "0a" + "feffffff0f",  # list of compound
    ]
    for c in cases:
        with assert_raises():
            _ = decode(Span(hex_decode(c)), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="unexpected buffer end"):
        _ = decode(
            Span(hex_decode("0a0000" + "070100" + "6200000100")), LITTLE_ENDIAN
        )
    with assert_raises(contains="unexpected buffer end"):
        _ = decode(
            Span(hex_decode("0a0000" + "0b0001" + "6900100000")), BIG_ENDIAN
        )
    # Above MAX_ELEMENTS (2^24 + 1, zigzag 0x2000002).
    with assert_raises(contains="exceeds"):
        _ = decode(
            Span(hex_decode("0a00" + "070162" + "82808010")),
            NETWORK_LITTLE_ENDIAN,
        )
    _ = MAX_ELEMENTS
    # Negative lengths.
    with assert_raises(contains="negative length"):
        _ = decode(
            Span(hex_decode("0a00" + "070162" + "01" + "00")),
            NETWORK_LITTLE_ENDIAN,
        )
    with assert_raises(contains="negative length"):
        _ = decode(
            Span(hex_decode("0a0000" + "090100" + "6c03ffffffff00")),
            LITTLE_ENDIAN,
        )
    # Strings above 32767 bytes: network 40000, LE 0x8000, BE 0xffff.
    with assert_raises(contains="exceeds maximum length"):
        _ = decode(
            Span(hex_decode("0a00" + "080173" + "c0b802")),
            NETWORK_LITTLE_ENDIAN,
        )
    with assert_raises(contains="exceeds maximum length"):
        _ = decode(
            Span(hex_decode("0a0000" + "08010073" + "0080")), LITTLE_ENDIAN
        )
    with assert_raises(contains="exceeds maximum length"):
        _ = decode(Span(hex_decode("0a0000" + "08000173" + "ffff")), BIG_ENDIAN)
    with assert_raises(contains="exceeds maximum length"):
        _ = decode(Span(hex_decode("08" + "ffff")), BIG_ENDIAN)


def test_rejects_truncated_input() raises:
    var t = _every_tag()
    comptime for k in range(3):
        comptime enc = ENCODINGS[k]
        var raw = encode(t, enc)
        for n in range(len(raw)):
            var prefix = List[UInt8](Span(raw)[0:n])
            with assert_raises():
                _ = decode(Span(prefix), enc)


def test_rejects_unknown_tags() raises:
    with assert_raises(contains="unknown tag"):
        _ = decode(Span(hex_decode("0d00")), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="unknown tag"):
        _ = decode(
            Span(hex_decode("0a00" + "0d0161" + "00")), NETWORK_LITTLE_ENDIAN
        )
    # Unknown list element types fail even for an empty list, as in Go.
    with assert_raises(contains="unknown tag"):
        _ = decode(
            Span(hex_decode("0a00" + "09016c" + "0d00" + "00")),
            NETWORK_LITTLE_ENDIAN,
        )
    with assert_raises(contains="unknown tag"):
        _ = decode(
            Span(hex_decode("0a00" + "09016c" + "ff02" + "00")),
            NETWORK_LITTLE_ENDIAN,
        )


def test_list_of_end() raises:
    var empty = decode(
        Span(hex_decode("0a00" + "09016c" + "0000" + "00")),
        NETWORK_LITTLE_ENDIAN,
    )
    assert_equal(empty.elem_type(empty.get_list(empty.root(), "l")), TAG_END)
    with assert_raises(contains="unexpected tag TAG_End"):
        _ = decode(
            Span(hex_decode("0a00" + "09016c" + "0002" + "00")),
            NETWORK_LITTLE_ENDIAN,
        )


def test_rejects_overlong_varint() raises:
    with assert_raises(contains="did not terminate"):
        _ = decode(
            Span(hex_decode("0a00" + "030169" + "ffffffffff01" + "00")),
            NETWORK_LITTLE_ENDIAN,
        )
    with assert_raises(contains="did not terminate"):
        _ = decode(
            Span(
                hex_decode("0a00" + "040169" + "ffffffffffffffffffff01" + "00")
            ),
            NETWORK_LITTLE_ENDIAN,
        )


def _big_compound(n: Int, enc: Int) raises -> List[UInt8]:
    """A root compound holding one byte array of `n` bytes."""
    var t = Tree()
    var payload = List[UInt8](length=n, fill=0)
    _ = t.put_byte_array(t.root(), "a", payload)
    return encode(t, enc)


def test_network_offset_limit() raises:
    # Root header (2) + entry header (3) + 4-byte varint length + payload:
    # the closing TAG_End is read at offset 9 + n.
    var ok = _big_compound(MAX_NETWORK_OFFSET - 10, NETWORK_LITTLE_ENDIAN)
    _ = decode(Span(ok), NETWORK_LITTLE_ENDIAN)
    var over = _big_compound(MAX_NETWORK_OFFSET - 9, NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="limit of bytes read"):
        _ = decode(Span(over), NETWORK_LITTLE_ENDIAN)
    # The fixed-width encodings have no such limit.
    _ = decode(
        Span(_big_compound(MAX_NETWORK_OFFSET, LITTLE_ENDIAN)), LITTLE_ENDIAN
    )


def test_rejects_unknown_encoding() raises:
    with assert_raises(contains="unknown encoding"):
        _ = decode(Span(hex_decode("0a0000")), 3)


# ===----------------------------------------------------------------------=== #
# Agreement with the raw walk in nbt.mojo
# ===----------------------------------------------------------------------=== #


def _agree(data: List[UInt8], enc: Int) raises -> Bool:
    """Runs nbt() and decode_from() on `data` and checks they agree.

    Returns:
        Whether both accepted the input.
    """
    var raw_ok = True
    var raw = NBT()
    var consumed = 0
    try:
        var r = Reader(Span(data))
        nbt(r, raw, enc)
        consumed = len(data) - r.remaining()
    except:
        raw_ok = False
    var tree_ok = True
    var pos = 0
    var re = List[UInt8]()
    try:
        var t = decode_from(Span(data), pos, enc)
        re = encode(t, enc)
    except:
        tree_ok = False
    assert_equal(
        raw_ok,
        tree_ok,
        String(t"accept/reject differs for {hex_encode(Span(data))}"),
    )
    if raw_ok:
        assert_equal(pos, consumed)
        assert_equal(hex_encode(Span(re)), hex_encode(Span(raw.raw)))
    return raw_ok


def test_raw_walk_and_decoder_agree() raises:
    var t = _every_tag()
    comptime for k in range(3):
        comptime enc = ENCODINGS[k]
        var raw = encode(t, enc)
        assert_true(_agree(raw, enc))
        var trailing = raw.copy()
        trailing.append(0xFF)
        assert_true(_agree(trailing, enc))
        for n in range(len(raw)):
            assert_false(_agree(List[UInt8](Span(raw)[0:n]), enc))
    var accepted: List[String] = [
        "00",
        "0a0000",
        "0a00" + "09016c" + "0000" + "00",
        "0a00" + "01016101" + "01016102" + "00",
        "0a00" + "080173" + "02c328" + "00",
        "03000a",
    ]
    for c in accepted:
        assert_true(_agree(hex_decode(c), NETWORK_LITTLE_ENDIAN))
    var rejected: List[String] = [
        "0d00",
        "0a00" + "0d0161" + "00",
        "0a00" + "09016c" + "0d00" + "00",
        "0a00" + "09016c" + "0002" + "00",
        "0a00" + "070162" + "feffffff0f",
        "0a00" + "070162" + "01" + "00",
        "0a00" + "080173" + "c0b802",
        "0a00" + "030169" + "ffffffffff01" + "00",
        "0a00" + "09016c" + "03" + "feffffff0f",
    ]
    for c in rejected:
        assert_false(_agree(hex_decode(c), NETWORK_LITTLE_ENDIAN))
    assert_true(_agree(_nested_compounds(MAX_DEPTH - 1), NETWORK_LITTLE_ENDIAN))
    assert_false(_agree(_nested_compounds(MAX_DEPTH), NETWORK_LITTLE_ENDIAN))
    assert_true(_agree(_lists_of_lists(MAX_DEPTH - 1), NETWORK_LITTLE_ENDIAN))
    assert_false(_agree(_lists_of_lists(MAX_DEPTH), NETWORK_LITTLE_ENDIAN))
    assert_true(
        _agree(
            _big_compound(MAX_NETWORK_OFFSET - 10, NETWORK_LITTLE_ENDIAN),
            NETWORK_LITTLE_ENDIAN,
        )
    )
    assert_false(
        _agree(
            _big_compound(MAX_NETWORK_OFFSET - 9, NETWORK_LITTLE_ENDIAN),
            NETWORK_LITTLE_ENDIAN,
        )
    )


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
