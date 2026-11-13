"""Byte-exact checks against gophertunnel `nbt.MarshalEncoding`.

The expected hex was produced by marshalling Go structs with the same fields
in the same order with gophertunnel v1.63.0, in all three encodings.
"""

from minecraft.nbt.decode import decode
from minecraft.nbt.encode import encode, encode_to, to_nbt
from minecraft.nbt.encoding import MAX_DEPTH, MAX_STRING_SIZE
from minecraft.nbt.nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
    NETWORK_LITTLE_ENDIAN,
    TAG_BYTE,
    TAG_COMPOUND,
    TAG_DOUBLE,
    TAG_INT,
    TAG_INT_ARRAY,
    TAG_LIST,
    TAG_LONG,
    TAG_STRING,
    nbt,
)
from minecraft.nbt.tree import Tag, Tree
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime NESTED_NETWORK: StaticString = (
    "0a000a01610a0162030163d804000801640464656570000101650700"
)
comptime NESTED_LE: StaticString = (
    "0a00000a0100610a010062030100632c010000000801006404006465657000010100650700"
)
comptime NESTED_BE: StaticString = (
    "0a00000a0001610a000162030001630000012c000800016400046465657000010001650700"
)
comptime LIST_OF_COMPOUNDS_NETWORK: StaticString = (
    "0a0009016c0a0402017801000501790000003f00020178feff050179000000c10000"
)
comptime LIST_OF_COMPOUNDS_LE: StaticString = (
    "0a00000901006c0a02000000020100780100050100790000003f0002010078fe"
    "ff05010079000000c10000"
)
comptime LIST_OF_COMPOUNDS_BE: StaticString = (
    "0a00000900016c0a00000002020001780001050001793f0000000002000178ff"
    "fe05000179c10000000000"
)
comptime EMPTY_LISTS_NETWORK: StaticString = (
    "0a00090165000009016903000901630a00090173080000"
)
comptime EMPTY_LISTS_LE: StaticString = (
    "0a0000090100650000000000090100690300000000090100630a000000000901"
    "0073080000000000"
)
comptime EMPTY_LISTS_BE: StaticString = (
    "0a0000090001650000000000090001690300000000090001630a000000000900"
    "0173080000000000"
)
comptime ARRAYS_NETWORK: StaticString = (
    "0a0007016206007fff0b01690401808080010c016c04ffffffffffffffffff01"
    "8080808080400b0165000c02656c00070265620000"
)
comptime ARRAYS_LE: StaticString = (
    "0a00000701006203000000007fff0b01006902000000ffffffff000010000c01"
    "006c02000000000000000000008000000000000100000b010065000000000c02"
    "00656c0000000007020065620000000000"
)
comptime ARRAYS_BE: StaticString = (
    "0a00000700016200000003007fff0b00016900000002ffffffff001000000c00"
    "016c00000002800000000000000000000100000000000b000165000000000c00"
    "02656c0000000007000265620000000000"
)
comptime UNICODE_NETWORK: StaticString = (
    "0a000801730f68c3a96c6c6f20e29c9320f09f8e890808d0bad0bbd18ed18710"
    "d0b7d0bdd0b0d187d0b5d0bdd0b8d0b50801450000"
)
comptime UNICODE_LE: StaticString = (
    "0a0000080100730f0068c3a96c6c6f20e29c9320f09f8e89080800d0bad0bbd1"
    "8ed1871000d0b7d0bdd0b0d187d0b5d0bdd0b8d0b508010045000000"
)
comptime UNICODE_BE: StaticString = (
    "0a000008000173000f68c3a96c6c6f20e29c9320f09f8e89080008d0bad0bbd1"
    "8ed1870010d0b7d0bdd0b0d187d0b5d0bdd0b8d0b508000145000000"
)
comptime NEGATIVE_NETWORK: StaticString = (
    "0a00010162ff020173feff030169010304696d696effffffff0f0304696d6178"
    "feffffff0f04016cd70404046c6d696effffffffffffffffff0104046c6d6178"
    "feffffffffffffffff010501660000c0bf06016400000000000002c00204736d"
    "696e008000"
)
comptime NEGATIVE_LE: StaticString = (
    "0a000001010062ff02010073feff03010069ffffffff030400696d696e000000"
    "80030400696d6178ffffff7f0401006cd4feffffffffffff0404006c6d696e00"
    "000000000000800404006c6d6178ffffffffffffff7f050100660000c0bf0601"
    "006400000000000002c0020400736d696e008000"
)
comptime NEGATIVE_BE: StaticString = (
    "0a000001000162ff02000173fffe03000169ffffffff030004696d696e800000"
    "00030004696d61787fffffff0400016cfffffffffffffed40400046c6d696e80"
    "000000000000000400046c6d61787fffffffffffffff05000166bfc000000600"
    "0164c002000000000000020004736d696e800000"
)
comptime ALL_TAGS_NETWORK: StaticString = (
    "0a0001046279746501020573686f727402000303696e740604046c6f6e670805"
    "05666c6f61740000b0400606646f75626c650000000000001940070a62797465"
    "5f617272617908010203040806737472696e670373747209046c697374040601"
    "00020a08636f6d706f756e6403016b11000b09696e745f6172726179060e0f12"
    "0c0a6c6f6e675f617272617904131600"
)
comptime ALL_TAGS_LE: StaticString = (
    "0a0000010400627974650102050073686f72740200030300696e740300000004"
    "04006c6f6e670400000000000000050500666c6f61740000b040060600646f75"
    "626c650000000000001940070a00627974655f61727261790400000001020304"
    "080600737472696e6703007374720904006c6973740403000000ffffffffffff"
    "ffff000000000000000001000000000000000a0800636f6d706f756e64030100"
    "6bf7ffffff000b0900696e745f61727261790300000007000000f8ffffff0900"
    "00000c0a006c6f6e675f617272617902000000f6ffffffffffffff0b00000000"
    "00000000"
)
comptime ALL_TAGS_BE: StaticString = (
    "0a0000010004627974650102000573686f72740002030003696e740000000304"
    "00046c6f6e670000000000000004050005666c6f617440b00000060006646f75"
    "626c65401900000000000007000a627974655f61727261790000000401020304"
    "080006737472696e6700037374720900046c6973740400000003ffffffffffff"
    "ffff000000000000000000000000000000010a0008636f6d706f756e64030001"
    "6bfffffff7000b0009696e745f61727261790000000300000007fffffff80000"
    "00090c000a6c6f6e675f617272617900000002fffffffffffffff60000000000"
    "00000b00"
)
comptime LISTS_NETWORK: StaticString = (
    "0a0009026c6c090403040204030009026c730804016102626309026c62010401"
    "fe09026c640602000000000000f83f09026c610b0204020409026c6d0a040101"
    "6101000000"
)
comptime LISTS_LE: StaticString = (
    "0a00000902006c6c090200000003020000000100000002000000030000000009"
    "02006c730802000000010061020062630902006c62010200000001fe0902006c"
    "640601000000000000000000f83f0902006c610b010000000200000001000000"
    "020000000902006c6d0a020000000101006101000000"
)
comptime LISTS_BE: StaticString = (
    "0a00000900026c6c090000000203000000020000000100000002030000000009"
    "00026c730800000002000161000262630900026c62010000000201fe0900026c"
    "6406000000013ff80000000000000900026c610b000000010000000200000001"
    "000000020900026c6d0a000000020100016101000000"
)
comptime EMPTY_COMPOUND_NETWORK: StaticString = "0a0000"
comptime EMPTY_COMPOUND_LE: StaticString = "0a000000"
comptime EMPTY_COMPOUND_BE: StaticString = "0a000000"

comptime ENCODINGS = [NETWORK_LITTLE_ENDIAN, LITTLE_ENDIAN, BIG_ENDIAN]


def _check(
    tree: Tree,
    network: StaticString,
    le: StaticString,
    be: StaticString,
) raises:
    """Checks encode(tree) and decode-then-encode against Go's bytes."""
    var expected: List[StaticString] = [network, le, be]
    comptime for k in range(3):
        comptime enc = ENCODINGS[k]
        var want = String(expected[k])
        assert_equal(hex_encode(Span(encode(tree, enc))), want)
        var decoded = decode(Span(hex_decode(want)), enc)
        assert_equal(hex_encode(Span(encode(decoded, enc))), want)


def test_nested_compounds() raises:
    var t = Tree()
    var a = t.put_compound(t.root(), "a")
    var b = t.put_compound(a, "b")
    _ = t.put_int(b, "c", 300)
    _ = t.put_string(a, "d", "deep")
    _ = t.put_byte(t.root(), "e", 7)
    _check(t, NESTED_NETWORK, NESTED_LE, NESTED_BE)
    var d = decode(Span(hex_decode(NESTED_NETWORK)), NETWORK_LITTLE_ENDIAN)
    var da = d.get_compound(d.root(), "a")
    assert_equal(d.get_int(d.get_compound(da, "b"), "c"), 300)
    assert_equal(d.get_string(da, "d"), "deep")
    assert_equal(d.get_byte(d.root(), "e"), 7)


def test_list_of_compounds() raises:
    var t = Tree()
    var l = t.put_list(t.root(), "l")
    var first = t.append_compound(l)
    _ = t.put_short(first, "x", 1)
    _ = t.put_float(first, "y", 0.5)
    var second = t.append_compound(l)
    _ = t.put_short(second, "x", -2)
    _ = t.put_float(second, "y", -8)
    assert_equal(t.elem_type(l), TAG_COMPOUND)
    _check(
        t, LIST_OF_COMPOUNDS_NETWORK, LIST_OF_COMPOUNDS_LE, LIST_OF_COMPOUNDS_BE
    )
    var d = decode(Span(hex_decode(LIST_OF_COMPOUNDS_BE)), BIG_ENDIAN)
    var dl = d.get_list(d.root(), "l")
    assert_equal(d.length(dl), 2)
    assert_equal(d.get_short(d.at(dl, 1), "x"), -2)
    assert_equal(d.get_float(d.at(dl, 1), "y"), -8)


def test_empty_lists() raises:
    var t = Tree()
    _ = t.put_list(t.root(), "e")
    _ = t.put_list(t.root(), "i", TAG_INT)
    _ = t.put_list(t.root(), "c", TAG_COMPOUND)
    _ = t.put_list(t.root(), "s", TAG_STRING)
    _check(t, EMPTY_LISTS_NETWORK, EMPTY_LISTS_LE, EMPTY_LISTS_BE)
    var d = decode(Span(hex_decode(EMPTY_LISTS_LE)), LITTLE_ENDIAN)
    assert_equal(d.length(d.get_list(d.root(), "c")), 0)
    assert_equal(d.elem_type(d.get_list(d.root(), "c")), TAG_COMPOUND)


def test_arrays() raises:
    var t = Tree()
    var b: List[UInt8] = [0, 0x7F, 0xFF]
    var i: List[Int32] = [-1, 1 << 20]
    var l: List[Int64] = [Int64.MIN, 1 << 40]
    var no_ints = List[Int32]()
    var no_longs = List[Int64]()
    var no_bytes = List[UInt8]()
    _ = t.put_byte_array(t.root(), "b", b)
    _ = t.put_int_array(t.root(), "i", i)
    _ = t.put_long_array(t.root(), "l", l)
    _ = t.put_int_array(t.root(), "e", no_ints)
    _ = t.put_long_array(t.root(), "el", no_longs)
    _ = t.put_byte_array(t.root(), "eb", no_bytes)
    _check(t, ARRAYS_NETWORK, ARRAYS_LE, ARRAYS_BE)
    var d = decode(Span(hex_decode(ARRAYS_NETWORK)), NETWORK_LITTLE_ENDIAN)
    assert_equal(d.get_byte_array(d.root(), "b"), b)
    assert_equal(d.get_int_array(d.root(), "i"), i)
    assert_equal(d.get_long_array(d.root(), "l"), l)
    assert_equal(len(d.get_long_array(d.root(), "el")), 0)


def test_unicode_strings() raises:
    var t = Tree()
    _ = t.put_string(t.root(), "s", "héllo ✓ 🎉")
    _ = t.put_string(t.root(), "ключ", "значение")
    _ = t.put_string(t.root(), "E", "")
    _check(t, UNICODE_NETWORK, UNICODE_LE, UNICODE_BE)
    var d = decode(Span(hex_decode(UNICODE_BE)), BIG_ENDIAN)
    assert_equal(d.get_string(d.root(), "s"), "héllo ✓ 🎉")
    assert_equal(d.get_string(d.root(), "ключ"), "значение")
    assert_equal(d.name(d.at(d.root(), 1)), "ключ")


def test_negative_numbers() raises:
    var t = Tree()
    var r = t.root()
    _ = t.put_byte(r, "b", 0xFF)
    _ = t.put_short(r, "s", -2)
    _ = t.put_int(r, "i", -1)
    _ = t.put_int(r, "imin", Int32.MIN)
    _ = t.put_int(r, "imax", Int32.MAX)
    _ = t.put_long(r, "l", -300)
    _ = t.put_long(r, "lmin", Int64.MIN)
    _ = t.put_long(r, "lmax", Int64.MAX)
    _ = t.put_float(r, "f", -1.5)
    _ = t.put_double(r, "d", -2.25)
    _ = t.put_short(r, "smin", Int16.MIN)
    _check(t, NEGATIVE_NETWORK, NEGATIVE_LE, NEGATIVE_BE)
    comptime for k in range(3):
        comptime enc = ENCODINGS[k]
        var d = decode(Span(encode(t, enc)), enc)
        var dr = d.root()
        assert_equal(d.get_byte(dr, "b"), 0xFF)
        assert_equal(d.get_short(dr, "s"), -2)
        assert_equal(d.get_int(dr, "imin"), Int32.MIN)
        assert_equal(d.get_int(dr, "imax"), Int32.MAX)
        assert_equal(d.get_long(dr, "l"), -300)
        assert_equal(d.get_long(dr, "lmin"), Int64.MIN)
        assert_equal(d.get_long(dr, "lmax"), Int64.MAX)
        assert_equal(d.get_float(dr, "f"), -1.5)
        assert_equal(d.get_double(dr, "d"), -2.25)
        assert_equal(d.get_short(dr, "smin"), Int16.MIN)


def _all_tags() raises -> Tree:
    var t = Tree()
    var r = t.root()
    _ = t.put_byte(r, "byte", 1)
    _ = t.put_short(r, "short", 2)
    _ = t.put_int(r, "int", 3)
    _ = t.put_long(r, "long", 4)
    _ = t.put_float(r, "float", 5.5)
    _ = t.put_double(r, "double", 6.25)
    var ba: List[UInt8] = [1, 2, 3, 4]
    _ = t.put_byte_array(r, "byte_array", ba)
    _ = t.put_string(r, "string", "str")
    var l = t.put_list(r, "list", TAG_LONG)
    _ = t.append_long(l, -1)
    _ = t.append_long(l, 0)
    _ = t.append_long(l, 1)
    var c = t.put_compound(r, "compound")
    _ = t.put_int(c, "k", -9)
    var ia: List[Int32] = [7, -8, 9]
    _ = t.put_int_array(r, "int_array", ia)
    var la: List[Int64] = [-10, 11]
    _ = t.put_long_array(r, "long_array", la)
    return t^


def test_all_tags() raises:
    _check(_all_tags(), ALL_TAGS_NETWORK, ALL_TAGS_LE, ALL_TAGS_BE)


def test_lists_of_every_shape() raises:
    var t = Tree()
    var r = t.root()
    var ll = t.put_list(r, "ll")
    var inner = t.append_list(ll, TAG_INT)
    _ = t.append_int(inner, 1)
    _ = t.append_int(inner, 2)
    _ = t.append_list(ll, TAG_INT)
    var ls = t.put_list(r, "ls")
    _ = t.append_string(ls, "a")
    _ = t.append_string(ls, "bc")
    var lb = t.put_list(r, "lb")
    _ = t.append_byte(lb, 1)
    _ = t.append_byte(lb, 0xFE)
    var ld = t.put_list(r, "ld")
    _ = t.append_double(ld, 1.5)
    var la = t.put_list(r, "la")
    var pair: List[Int32] = [1, 2]
    _ = t.append_int_array(la, pair)
    var lm = t.put_list(r, "lm")
    var m = t.append_compound(lm)
    _ = t.put_byte(m, "a", 1)
    _ = t.append_compound(lm)
    _check(t, LISTS_NETWORK, LISTS_LE, LISTS_BE)
    assert_equal(t.elem_type(ll), TAG_LIST)
    assert_equal(t.elem_type(la), TAG_INT_ARRAY)
    assert_equal(t.elem_type(ld), TAG_DOUBLE)


def test_empty_compound() raises:
    _check(Tree(), EMPTY_COMPOUND_NETWORK, EMPTY_COMPOUND_LE, EMPTY_COMPOUND_BE)


def test_root_name_and_empty_tree() raises:
    var named = Tree(TAG_COMPOUND, "root")
    assert_equal(
        hex_encode(Span(encode(named, NETWORK_LITTLE_ENDIAN))), "0a04726f6f7400"
    )
    assert_equal(
        hex_encode(Span(encode(named, BIG_ENDIAN))), "0a0004726f6f7400"
    )
    var empty = Tree(0)
    assert_true(empty.is_empty())
    assert_equal(hex_encode(Span(encode(empty, LITTLE_ENDIAN))), "00")
    var list_root = Tree(TAG_LIST)
    _ = list_root.append_int(list_root.root(), -1)
    assert_equal(
        hex_encode(Span(encode(list_root, NETWORK_LITTLE_ENDIAN))),
        "0900030201",
    )


def test_encode_to_appends() raises:
    var out: List[UInt8] = [0xAA]
    encode_to(Tree(), NETWORK_LITTLE_ENDIAN, out)
    assert_equal(hex_encode(Span(out)), "aa0a0000")


def test_to_nbt_writes_through_packet_io() raises:
    var nv = to_nbt(_all_tags(), NETWORK_LITTLE_ENDIAN)
    assert_equal(nv.encoding, NETWORK_LITTLE_ENDIAN)
    var w = Writer()
    nbt(w, nv, NETWORK_LITTLE_ENDIAN)
    assert_equal(hex_encode(Span(w.buf)), String(ALL_TAGS_NETWORK))


def test_encode_limits() raises:
    var long_text = String()
    for _ in range(MAX_STRING_SIZE + 1):
        long_text += "a"
    var t = Tree()
    _ = t.put_string(t.root(), "s", long_text)
    with assert_raises(contains="exceeds maximum length"):
        _ = encode(t, NETWORK_LITTLE_ENDIAN)
    var t2 = Tree()
    _ = t2.put_byte(t2.root(), long_text, 1)
    with assert_raises(contains="exceeds maximum length"):
        _ = encode(t2, LITTLE_ENDIAN)
    # Exactly MAX_STRING_SIZE is fine.
    var t3 = Tree()
    _ = t3.put_string(t3.root(), "s", String(long_text[byte=1:]))
    _ = encode(t3, BIG_ENDIAN)
    with assert_raises(contains="unknown encoding"):
        _ = encode(t3, 7)


def _nested(levels: Int) raises -> Tree:
    """A root compound with `levels - 1` compounds nested inside."""
    var t = Tree()
    var cur = t.root()
    for _ in range(levels - 1):
        cur = t.put_compound(cur, "c")
    return t^


def test_encode_depth_limit() raises:
    # gophertunnel rejects a compound nested 512 deep; 511 is the most.
    var ok = encode(_nested(MAX_DEPTH - 1), NETWORK_LITTLE_ENDIAN)
    _ = decode(Span(ok), NETWORK_LITTLE_ENDIAN)
    with assert_raises(contains="maximum nesting depth"):
        _ = encode(_nested(MAX_DEPTH), NETWORK_LITTLE_ENDIAN)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
