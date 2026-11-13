"""Human-readable NBT dumps, ported from gophertunnel `nbt/dump.go`.

The format is Go's: `TAG_Compound({` with one tab-indented
`'name': TAG_Type(value),` line per entry, bytes as `0x0f`, arrays space
separated. Unlike Go, compound entries keep their order and any root type
can be dumped. For compact SNBT, write the `Tree` itself.
"""

from std.memory import bitcast

from .decode import decode
from .nbt import (
    TAG_BYTE,
    TAG_BYTE_ARRAY,
    TAG_COMPOUND,
    TAG_DOUBLE,
    TAG_FLOAT,
    TAG_INT,
    TAG_INT_ARRAY,
    TAG_LIST,
    TAG_LONG,
    TAG_LONG_ARRAY,
    TAG_SHORT,
    TAG_STRING,
)
from .encoding import tag_name
from .tree import Tree


def dump(data: Span[UInt8, _], encoding: Int) raises -> String:
    """Decodes NBT and formats it for reading (gophertunnel `Dump`).

    Args:
        data: One encoded tag.
        encoding: Its encoding.

    Returns:
        The dump.

    Raises:
        If the data cannot be decoded.
    """
    var tree: Tree
    try:
        tree = decode(data, encoding)
    except e:
        raise Error(t"decode NBT: {e}")
    return dump_tree(tree)


def dump_tree(tree: Tree) -> String:
    """Formats a tree the way `dump` does.

    Args:
        tree: The value.

    Returns:
        The dump; `nil` for an empty tree.
    """
    if tree.is_empty():
        return "nil"
    var out = String()
    out.write(_type(tree, 0), "(")
    _value(tree, 0, 0, out)
    out.write(")")
    return out^


def _type(tree: Tree, i: Int) -> String:
    ref e = tree._entries[i]
    if e.tag != TAG_LIST:
        return tag_name(e.tag)
    if len(e.children) > 0:
        return "TAG_List<" + _type(tree, e.children[0]) + ">"
    # Go decodes empty lists of these into typed slices and the rest into
    # an empty `[]any`, whose element type prints as nil.
    if e.elem == TAG_BYTE or e.elem == TAG_INT or e.elem == TAG_LONG:
        return "TAG_List<" + tag_name(e.elem) + ">"
    return "TAG_List<nil>"


def _hex_byte(b: UInt8, mut out: String):
    comptime digits = "0123456789abcdef"
    out.write(
        "0x",
        digits[byte=Int(b >> 4)],
        digits[byte=Int(b & 0x0F)],
    )


def _float(text: String) -> String:
    # Go's 'g' formatting writes whole numbers without ".0".
    if text.endswith(".0"):
        return String(text.removesuffix(".0"))
    return text


def _indent(n: Int, mut out: String):
    for _ in range(n):
        out.write("\t")


def _value(tree: Tree, i: Int, indent: Int, mut out: String):
    ref e = tree._entries[i]
    var tag = e.tag
    if tag == TAG_BYTE:
        _hex_byte(UInt8(e.value), out)
    elif tag == TAG_SHORT:
        out.write(Int16(e.value))
    elif tag == TAG_INT:
        out.write(Int32(e.value))
    elif tag == TAG_LONG:
        out.write(e.value)
    elif tag == TAG_FLOAT:
        out.write(_float(String(bitcast[DType.float32](UInt32(e.value)))))
    elif tag == TAG_DOUBLE:
        out.write(_float(String(bitcast[DType.float64](UInt64(e.value)))))
    elif tag == TAG_STRING:
        out.write(
            String(
                from_utf8_lossy=Span(tree._bytes)[e.start : e.start + e.length]
            )
        )
    elif tag == TAG_BYTE_ARRAY:
        for j in range(e.length):
            if j > 0:
                out.write(" ")
            _hex_byte(tree._bytes[e.start + j], out)
    elif tag == TAG_INT_ARRAY or tag == TAG_LONG_ARRAY:
        for j in range(e.length):
            if j > 0:
                out.write(" ")
            out.write(tree._numbers[e.start + j])
    elif tag == TAG_LIST:
        out.write("{\n")
        for c in e.children:
            _indent(indent + 1, out)
            _value(tree, c, indent + 1, out)
            out.write(",\n")
        _indent(indent, out)
        out.write("}")
    elif tag == TAG_COMPOUND:
        out.write("{\n")
        for c in e.children:
            _indent(indent + 1, out)
            out.write(
                "'",
                String(from_utf8_lossy=tree._name_span(c)),
                "': ",
                _type(tree, c),
                "(",
            )
            _value(tree, c, indent + 1, out)
            out.write("),\n")
        _indent(indent, out)
        out.write("}")
