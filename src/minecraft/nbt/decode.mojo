"""Decodes NBT bytes into a `Tree`, ported from gophertunnel `nbt/decode.go`.

The limits are gophertunnel's: unknown tag types are rejected (also as the
element type of an empty list), containers nest at most `MAX_DEPTH - 1`
deep, strings are at most `MAX_STRING_SIZE` bytes, array and list lengths
must be non-negative and fit in the remaining input, and network decoding
reads no tag header past `MAX_NETWORK_OFFSET` bytes. Differences from Go:

- A root `TAG_End` decodes to an empty tree (Go's `AllowZero`), as `nbt()`
  in `nbt.mojo` accepts it.
- The root tag's name is kept.
- Lengths above `MAX_ELEMENTS` are rejected, like the raw walk in `nbt.mojo`.
- The depth limit applies to lists as well as compounds, and lists of
  bytes, ints and longs do not leak depth (Go never decrements it for them,
  so a compound with 511 such lists fails in Go).
"""

from .encoding import (
    MAX_DEPTH,
    MAX_NETWORK_OFFSET,
    check_encoding,
    is_valid_tag,
    read_byte,
    read_float32,
    read_float64,
    read_int16,
    read_int32,
    read_int64,
    read_length,
    read_string_length,
)
from .nbt import (
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
)
from .tree import Tree, _f32_bits, _f64_bits


def decode(data: Span[UInt8, _], encoding: Int) raises -> Tree:
    """Decodes exactly one named tag (gophertunnel `UnmarshalEncoding`).

    Unlike Go, trailing bytes after the tag are an error; use `decode_from`
    to read a tag from a longer buffer.

    Args:
        data: The encoded tag.
        encoding: One of the encoding constants.

    Returns:
        The decoded tree.

    Raises:
        If the input is malformed, exceeds a limit or has trailing bytes.
    """
    var pos = 0
    var tree = decode_from(data, pos, encoding)
    if pos != len(data):
        raise Error(t"nbt: {len(data) - pos} trailing bytes after the root tag")
    return tree^


def decode_from(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Tree:
    """Decodes one named tag starting at `pos` (gophertunnel `Decoder.Decode`).

    Args:
        data: The input.
        pos: The offset of the tag; advanced past it on success.
        encoding: One of the encoding constants.

    Returns:
        The decoded tree.

    Raises:
        If the input is malformed or exceeds a limit.
    """
    check_encoding(encoding)
    var start = pos
    var tree = Tree._bare()
    var tag = read_byte(data, pos, "ReadTag")
    var none = List[UInt8]()
    if tag == TAG_END:
        _ = tree._push(TAG_END, Span(none))
        return tree^
    if not is_valid_tag(tag):
        raise Error(t"nbt: unknown tag '{tag}' at offset {pos - start}")
    var n = read_string_length(data, pos, encoding)
    var root = tree._push(tag, data[pos : pos + n])
    pos += n
    _decode_payload(data, pos, start, encoding, tree, root, 0)
    return tree^


def from_nbt(x: NBT) raises -> Tree:
    """Decodes a raw `NBT` value from a packet into a tree.

    Args:
        x: The value; an empty value gives an empty tree.

    Returns:
        The decoded tree.

    Raises:
        If the bytes are malformed.
    """
    if len(x.raw) == 0:
        return Tree(TAG_END)
    return decode(Span(x.raw), x.encoding)


def _decode_payload(
    data: Span[UInt8, _],
    mut pos: Int,
    start: Int,
    encoding: Int,
    mut tree: Tree,
    i: Int,
    depth: Int,
) raises:
    """Fills entry `i`, whose type is set, from its payload.

    `depth` counts the containers enclosing the tag (0 for the root).
    """
    var tag = tree._entries[i].tag
    if tag == TAG_BYTE:
        tree._entries[i].value = Int64(read_byte(data, pos, "Byte"))
    elif tag == TAG_SHORT:
        tree._entries[i].value = Int64(read_int16(data, pos, encoding))
    elif tag == TAG_INT:
        tree._entries[i].value = Int64(read_int32(data, pos, encoding))
    elif tag == TAG_LONG:
        tree._entries[i].value = read_int64(data, pos, encoding)
    elif tag == TAG_FLOAT:
        tree._entries[i].value = _f32_bits(read_float32(data, pos, encoding))
    elif tag == TAG_DOUBLE:
        tree._entries[i].value = _f64_bits(read_float64(data, pos, encoding))
    elif tag == TAG_BYTE_ARRAY:
        var n = read_length(data, pos, encoding, 1, "ByteArray")
        tree._entries[i].start = tree._push_bytes(data[pos : pos + n])
        tree._entries[i].length = n
        pos += n
    elif tag == TAG_STRING:
        var n = read_string_length(data, pos, encoding)
        tree._entries[i].start = tree._push_bytes(data[pos : pos + n])
        tree._entries[i].length = n
        pos += n
    elif tag == TAG_INT_ARRAY or tag == TAG_LONG_ARRAY:
        var width = 1 if encoding == NETWORK_LITTLE_ENDIAN else (
            4 if tag == TAG_INT_ARRAY else 8
        )
        var n = read_length(data, pos, encoding, width, "Int32Slice")
        tree._entries[i].start = len(tree._numbers)
        tree._entries[i].length = n
        for _ in range(n):
            if tag == TAG_INT_ARRAY:
                tree._numbers.append(Int64(read_int32(data, pos, encoding)))
            else:
                tree._numbers.append(read_int64(data, pos, encoding))
    elif tag == TAG_LIST:
        _check_depth(depth)
        var elem = read_byte(data, pos, "Slice")
        if not is_valid_tag(elem):
            raise Error(
                t"nbt: unknown tag '{elem}' at offset {pos - start} during op"
                t" 'Slice'"
            )
        var n = read_length(data, pos, encoding, 1, "Slice")
        if elem == TAG_END and n > 0:
            raise Error(
                t"nbt: unexpected tag TAG_End at offset {pos - start}: tag is"
                t" not valid in its context"
            )
        tree._entries[i].elem = elem
        tree._entries[i].children.reserve(n)
        var none = List[UInt8]()
        for _ in range(n):
            var child = tree._push(elem, Span(none))
            tree._link(i, child)
            _decode_payload(data, pos, start, encoding, tree, child, depth + 1)
    elif tag == TAG_COMPOUND:
        _check_depth(depth)
        while True:
            if (
                encoding == NETWORK_LITTLE_ENDIAN
                and pos - start >= MAX_NETWORK_OFFSET
            ):
                raise Error(
                    t"nbt: limit of bytes read {MAX_NETWORK_OFFSET} with"
                    t" NetworkLittleEndian format exhausted"
                )
            var t = read_byte(data, pos, "ReadTag")
            if t == TAG_END:
                break
            if not is_valid_tag(t):
                raise Error(
                    t"nbt: unknown tag '{t}' at offset {pos - start} during op"
                    t" 'Map'"
                )
            var n = read_string_length(data, pos, encoding)
            var child = tree._push(t, data[pos : pos + n])
            pos += n
            tree._link(i, child)
            _decode_payload(data, pos, start, encoding, tree, child, depth + 1)
    else:
        raise Error(t"nbt: unknown tag '{tag}' at offset {pos - start}")


def _check_depth(depth: Int) raises:
    # A container's own nesting level is depth + 1; Go fails reading the
    # entries of a compound at level MAX_DEPTH.
    if depth + 1 >= MAX_DEPTH:
        raise Error(t"nbt: maximum nesting depth of {MAX_DEPTH} was reached")
