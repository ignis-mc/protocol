"""Encodes a `Tree` into NBT bytes, ported from gophertunnel `nbt/encode.go`.

A tree built with the default root name `""` encodes byte-for-byte like
gophertunnel's `MarshalEncoding` of the equivalent struct (Go map entries
come out in random order; tree entries keep theirs). The encoder refuses
anything the decoder would reject: strings longer than `MAX_STRING_SIZE`,
containers nested `MAX_DEPTH` deep and arrays or lists longer than
`MAX_ELEMENTS`.
"""

from std.memory import bitcast

from .encoding import (
    MAX_DEPTH,
    MAX_ELEMENTS,
    check_encoding,
    write_float32,
    write_float64,
    write_int16,
    write_int32,
    write_int64,
    write_string,
)
from .nbt import (
    NBT,
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
)
from .tree import Tree


def encode(tree: Tree, encoding: Int) raises -> List[UInt8]:
    """Encodes a tree (gophertunnel `MarshalEncoding`).

    Args:
        tree: The value; an empty tree encodes as a single `TAG_End` byte.
        encoding: One of the encoding constants.

    Returns:
        The encoded root tag.

    Raises:
        If a value exceeds a limit.
    """
    var out = List[UInt8]()
    encode_to(tree, encoding, out)
    return out^


def encode_to(tree: Tree, encoding: Int, mut out: List[UInt8]) raises:
    """Appends the encoding of a tree to `out` (gophertunnel `Encoder.Encode`).

    Args:
        tree: The value.
        encoding: One of the encoding constants.
        out: The destination; unchanged if encoding fails.

    Raises:
        If a value exceeds a limit.
    """
    check_encoding(encoding)
    var buf = List[UInt8]()
    if tree.is_empty():
        buf.append(TAG_END)
    else:
        buf.append(tree._entries[0].tag)
        write_string(buf, tree._name_span(0), encoding)
        _encode_payload(tree, 0, encoding, buf, 0)
    out.extend(Span(buf))


def to_nbt(tree: Tree, encoding: Int) raises -> NBT:
    """Encodes a tree into a raw `NBT` value for a packet field.

    Args:
        tree: The value.
        encoding: The encoding the packet uses.

    Returns:
        The encoded value.

    Raises:
        If a value exceeds a limit.
    """
    return NBT(encode(tree, encoding), encoding)


def _check_count(n: Int) raises:
    if n > MAX_ELEMENTS:
        raise Error(t"nbt: length {n} exceeds {MAX_ELEMENTS}")


def _encode_payload(
    tree: Tree, i: Int, encoding: Int, mut out: List[UInt8], depth: Int
) raises:
    ref e = tree._entries[i]
    var tag = e.tag
    if tag == TAG_BYTE:
        out.append(UInt8(e.value))
    elif tag == TAG_SHORT:
        write_int16(out, Int16(e.value), encoding)
    elif tag == TAG_INT:
        write_int32(out, Int32(e.value), encoding)
    elif tag == TAG_LONG:
        write_int64(out, e.value, encoding)
    elif tag == TAG_FLOAT:
        write_float32(out, bitcast[DType.float32](UInt32(e.value)), encoding)
    elif tag == TAG_DOUBLE:
        write_float64(out, bitcast[DType.float64](UInt64(e.value)), encoding)
    elif tag == TAG_BYTE_ARRAY:
        _check_count(e.length)
        write_int32(out, Int32(e.length), encoding)
        out.extend(Span(tree._bytes)[e.start : e.start + e.length])
    elif tag == TAG_STRING:
        write_string(
            out, Span(tree._bytes)[e.start : e.start + e.length], encoding
        )
    elif tag == TAG_INT_ARRAY:
        _check_count(e.length)
        write_int32(out, Int32(e.length), encoding)
        for j in range(e.length):
            write_int32(out, Int32(tree._numbers[e.start + j]), encoding)
    elif tag == TAG_LONG_ARRAY:
        _check_count(e.length)
        write_int32(out, Int32(e.length), encoding)
        for j in range(e.length):
            write_int64(out, tree._numbers[e.start + j], encoding)
    elif tag == TAG_LIST:
        _check_depth(depth)
        _check_count(len(e.children))
        out.append(e.elem)
        write_int32(out, Int32(len(e.children)), encoding)
        for c in e.children:
            if tree._entries[c].tag != e.elem:
                raise Error("nbt: list element does not match the list type")
            _encode_payload(tree, c, encoding, out, depth + 1)
    elif tag == TAG_COMPOUND:
        _check_depth(depth)
        for c in e.children:
            out.append(tree._entries[c].tag)
            write_string(out, tree._name_span(c), encoding)
            _encode_payload(tree, c, encoding, out, depth + 1)
        out.append(TAG_END)
    else:
        raise Error(t"nbt: cannot encode tag type {tag}")


def _check_depth(depth: Int) raises:
    if depth + 1 >= MAX_DEPTH:
        raise Error(t"nbt: maximum nesting depth of {MAX_DEPTH} was reached")
