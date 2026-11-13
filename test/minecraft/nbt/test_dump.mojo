from minecraft.nbt.dump import dump, dump_tree
from minecraft.nbt.nbt import BIG_ENDIAN, NETWORK_LITTLE_ENDIAN, TAG_END
from minecraft.nbt.tree import Tree
from nethernet.wire import hex_decode
from std.testing import TestSuite, assert_equal, assert_raises


def test_dump_matches_go_format() raises:
    var t = Tree()
    var r = t.root()
    _ = t.put_byte(r, "b", 0x0F)
    _ = t.put_float(r, "f", 2)
    _ = t.put_double(r, "d", 0.5)
    _ = t.put_string(r, "s", "hi")
    var ba: List[UInt8] = [1, 0xAB]
    _ = t.put_byte_array(r, "ba", ba)
    var ia: List[Int32] = [1, -2]
    _ = t.put_int_array(r, "ia", ia)
    var l = t.put_list(r, "l")
    var c = t.append_compound(l)
    _ = t.put_short(c, "x", -1)
    _ = t.put_list(r, "empty")
    _ = t.put_list(r, "ints", 3)
    assert_equal(
        dump_tree(t),
        "TAG_Compound({\n"
        + "\t'b': TAG_Byte(0x0f),\n"
        + "\t'f': TAG_Float(2),\n"
        + "\t'd': TAG_Double(0.5),\n"
        + "\t's': TAG_String(hi),\n"
        + "\t'ba': TAG_ByteArray(0x01 0xab),\n"
        + "\t'ia': TAG_IntArray(1 -2),\n"
        + "\t'l': TAG_List<TAG_Compound>({\n"
        + "\t\t{\n"
        + "\t\t\t'x': TAG_Short(-1),\n"
        + "\t\t},\n"
        + "\t}),\n"
        + "\t'empty': TAG_List<nil>({\n"
        + "\t}),\n"
        + "\t'ints': TAG_List<TAG_Int>({\n"
        + "\t}),\n"
        + "})",
    )
    assert_equal(dump_tree(Tree(TAG_END)), "nil")


def test_dump_bytes() raises:
    # gophertunnel's NESTED vector in big endian.
    var raw = hex_decode(
        "0a00000a0001610a000162030001630000012c0008000164000464656570"
        + "00010001650700"
    )
    assert_equal(
        dump(Span(raw), BIG_ENDIAN),
        "TAG_Compound({\n"
        + "\t'a': TAG_Compound({\n"
        + "\t\t'b': TAG_Compound({\n"
        + "\t\t\t'c': TAG_Int(300),\n"
        + "\t\t}),\n"
        + "\t\t'd': TAG_String(deep),\n"
        + "\t}),\n"
        + "\t'e': TAG_Byte(0x07),\n"
        + "})",
    )
    with assert_raises(contains="decode NBT: nbt: unknown tag"):
        _ = dump(Span(hex_decode("0d00")), NETWORK_LITTLE_ENDIAN)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
