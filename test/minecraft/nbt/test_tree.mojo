from minecraft.nbt.encode import encode
from minecraft.nbt.nbt import (
    NETWORK_LITTLE_ENDIAN,
    TAG_BYTE,
    TAG_COMPOUND,
    TAG_END,
    TAG_INT,
    TAG_LIST,
    TAG_STRING,
)
from minecraft.nbt.tree import Tag, Tree
from nethernet.wire import hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _block() raises -> Tree:
    """A block state as a Bedrock server sends it."""
    var t = Tree()
    var r = t.root()
    _ = t.put_string(r, "name", "minecraft:stone")
    var states = t.put_compound(r, "states")
    _ = t.put_string(states, "stone_type", "granite")
    _ = t.put_bool(states, "lit", False)
    _ = t.put_int(r, "version", 18100737)
    return t^


def test_build_and_read() raises:
    var t = _block()
    var r = t.root()
    assert_equal(t.type_of(r), TAG_COMPOUND)
    assert_equal(t.length(r), 3)
    assert_equal(t.get_string(r, "name"), "minecraft:stone")
    var states = t.get_compound(r, "states")
    assert_equal(t.get_string(states, "stone_type"), "granite")
    assert_false(t.get_bool(states, "lit"))
    assert_equal(t.get_byte(states, "lit"), 0)
    assert_equal(t.get_int(r, "version"), 18100737)
    assert_true(t.has(r, "states"))
    assert_false(t.has(r, "missing"))
    assert_false(Bool(t.get(r, "missing")))
    # `get` on a non-compound is None, not an error.
    assert_false(Bool(t.get(t.require(r, "name"), "x")))
    var names = List[String]()
    for c in t.children(r):
        names.append(t.name(c))
    assert_equal(names, ["name", "states", "version"])
    assert_equal(t.name(t.at(r, 1)), "states")
    if case .Some(found) = t.get(r, "version"):
        assert_equal(t.as_int(found), 18100737)
    else:
        raise Error("version missing")


def test_type_mismatch_and_missing_raise() raises:
    var t = _block()
    var r = t.root()
    with assert_raises(contains="is a TAG_Int, not a TAG_String"):
        _ = t.get_string(r, "version")
    with assert_raises(contains="is a TAG_String, not a TAG_Compound"):
        _ = t.get_compound(r, "name")
    with assert_raises(contains="not a TAG_List"):
        _ = t.get_list(r, "states")
    with assert_raises(contains="has no entry 'nope'"):
        _ = t.get_int(r, "nope")
    with assert_raises(contains="not a TAG_Long"):
        _ = t.as_long(t.require(r, "version"))
    with assert_raises(contains="index 3 out of range"):
        _ = t.at(r, 3)
    with assert_raises(contains="no entries"):
        _ = t.children(t.require(r, "version"))
    with assert_raises(contains="not in this tree"):
        _ = t.type_of(Tag(999))
    assert_equal(t.name(Tag(-1)), "")


def test_put_replaces_in_place() raises:
    var t = Tree()
    var r = t.root()
    _ = t.put_int(r, "a", 1)
    _ = t.put_string(r, "b", "x")
    _ = t.put_string(r, "a", "now a string")
    assert_equal(t.length(r), 2)
    assert_equal(t.name(t.at(r, 0)), "a")
    assert_equal(t.get_string(r, "a"), "now a string")
    assert_equal(
        hex_encode(Span(encode(t, NETWORK_LITTLE_ENDIAN))),
        "0a00" + "0801610c6e6f77206120737472696e67" + "08016201" + "78" + "00",
    )


def test_list_element_types() raises:
    var t = Tree()
    var r = t.root()
    var l = t.put_list(r, "l")
    assert_equal(t.elem_type(l), TAG_END)
    _ = t.append_int(l, 1)
    assert_equal(t.elem_type(l), TAG_INT)
    with assert_raises(contains="cannot add TAG_String to a list of TAG_Int"):
        _ = t.append_string(l, "x")
    var typed = t.put_list(r, "typed", TAG_STRING)
    with assert_raises(contains="list of TAG_String"):
        _ = t.append_byte(typed, 1)
    _ = t.append_string(typed, "ok")
    # List builders need a list, compound builders a compound.
    with assert_raises(contains="not a TAG_List"):
        _ = t.append_int(r, 1)
    with assert_raises(contains="not a TAG_Compound"):
        _ = t.put_int(l, "k", 1)
    with assert_raises(contains="unknown tag type"):
        _ = t.put_list(r, "bad", 13)
    var nested = t.put_list(r, "nested")
    var inner = t.append_list(nested, TAG_BYTE)
    _ = t.append_byte(inner, 7)
    assert_equal(t.elem_type(nested), TAG_LIST)
    assert_equal(t.as_byte(t.at(t.at(nested, 0), 0)), 7)
    assert_equal(t.name(t.at(l, 0)), "")


def test_list_root() raises:
    var t = Tree(TAG_LIST, "items")
    var c = t.append_compound(t.root())
    _ = t.put_short(c, "Count", 64)
    assert_equal(t.name(t.root()), "items")
    assert_equal(t.get_short(t.at(t.root(), 0), "Count"), 64)
    with assert_raises(contains="unknown tag type"):
        _ = Tree(13)


def test_copy_between_trees() raises:
    var src = _block()
    var dst = Tree()
    var copy = dst.put_tree(dst.root(), "block", src, src.root())
    var arr: List[Int32] = [1, 2, 3]
    _ = src.put_int_array(src.root(), "later", arr)
    _ = src.put_string(src.get_compound(src.root(), "states"), "x", "y")
    assert_equal(dst.name(copy), "block")
    assert_equal(dst.length(copy), 3)
    assert_equal(
        dst.get_string(dst.get_compound(copy, "states"), "stone_type"),
        "granite",
    )
    assert_equal(dst.length(dst.get_compound(copy, "states")), 2)
    var list = dst.put_list(dst.root(), "palette")
    _ = dst.append_tree(list, src, src.root())
    _ = dst.append_tree(list, src, src.root())
    assert_equal(dst.length(list), 2)
    assert_equal(dst.get_int_array(dst.at(list, 1), "later"), [Int32(1), 2, 3])
    assert_equal(dst.name(dst.at(list, 0)), "")
    var empty = Tree(TAG_END)
    with assert_raises(contains="TAG_End cannot be an entry"):
        _ = dst.put_tree(dst.root(), "e", empty, empty.root())


def test_remove() raises:
    var t = _block()
    assert_true(t.remove(t.root(), "states"))
    assert_false(t.remove(t.root(), "states"))
    assert_equal(t.length(t.root()), 2)
    assert_false(t.has(t.root(), "states"))


def test_snbt() raises:
    var t = Tree()
    var r = t.root()
    _ = t.put_byte(r, "b", 0xFF)
    _ = t.put_short(r, "s", 2)
    _ = t.put_int(r, "i", -3)
    _ = t.put_long(r, "l", 4)
    _ = t.put_float(r, "f", 1.5)
    _ = t.put_double(r, "d", 0.25)
    _ = t.put_string(r, "str", 'say "hi" \\ ok')
    var ba: List[UInt8] = [1, 0x80]
    _ = t.put_byte_array(r, "ba", ba)
    var ia: List[Int32] = [1, -2]
    _ = t.put_int_array(r, "ia", ia)
    var la: List[Int64] = [3]
    _ = t.put_long_array(r, "la", la)
    var l = t.put_list(r, "list")
    _ = t.append_compound(l)
    _ = t.put_compound(r, "minecraft:key with space")
    _ = t.put_list(r, "")
    assert_equal(
        String(t),
        (
            '{b: -1b, s: 2s, i: -3, l: 4L, f: 1.5f, d: 0.25d, str: "say'
            ' \\"hi\\" \\\\ ok", ba: [B; 1b, -128b], ia: [I; 1, -2], la: [L;'
            ' 3L], list: [{}], "minecraft:key with space": {}, "": []}'
        ),
    )
    assert_equal(String(Tree(TAG_END)), "")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
