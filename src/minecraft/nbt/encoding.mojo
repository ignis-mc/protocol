"""The three NBT encodings and their limits.

Ported from gophertunnel `nbt/encoding.go`, `nbt/encoding_little_endian.go`,
`nbt/encoding_big_endian.go`, `nbt/tag.go` and the limits in `nbt/err.go`.
Go's `Encoding` interface becomes a runtime `encoding: Int` (one of the
constants in `nbt.mojo`) passed to free functions. The encodings differ only
in how numbers and lengths are written:

| | `NETWORK_LITTLE_ENDIAN` | `LITTLE_ENDIAN` | `BIG_ENDIAN` |
| --- | --- | --- | --- |
| `TAG_Int`, array and list lengths | zigzag varint32 | 4 bytes LE | 4 bytes BE |
| `TAG_Long` | zigzag varint64 | 8 bytes LE | 8 bytes BE |
| string lengths | varuint32 | 2 bytes LE | 2 bytes BE |
| short, float, double | LE | LE | BE |

Readers take the whole input as a `Span` and a `pos` they advance.
"""

from std.memory import bitcast

from .nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
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

comptime MAX_STRING_SIZE = 32767
"""The longest string (in bytes) that may be read or written (`math.MaxInt16`).
"""
comptime MAX_DEPTH = 512
"""Containers (compounds and lists) may nest at most `MAX_DEPTH - 1` deep."""
comptime MAX_NETWORK_OFFSET = 4 * 1024 * 1024
"""`NETWORK_LITTLE_ENDIAN` decoding stops reading tags past this many bytes."""
comptime MAX_ELEMENTS = 1 << 24
"""The longest list or array accepted; matches the raw walk in `nbt.mojo`."""


def tag_name(tag: UInt8) -> String:
    """Names a tag type the way gophertunnel's `tagType.String` does.

    Args:
        tag: One of the `TAG_*` constants.

    Returns:
        `TAG_Byte`, `TAG_List`, ...; `TAG_Unknown(n)` for invalid types.
    """
    if tag == TAG_END:
        return "TAG_End"
    if tag == TAG_BYTE:
        return "TAG_Byte"
    if tag == TAG_SHORT:
        return "TAG_Short"
    if tag == TAG_INT:
        return "TAG_Int"
    if tag == TAG_LONG:
        return "TAG_Long"
    if tag == TAG_FLOAT:
        return "TAG_Float"
    if tag == TAG_DOUBLE:
        return "TAG_Double"
    if tag == TAG_BYTE_ARRAY:
        return "TAG_ByteArray"
    if tag == TAG_STRING:
        return "TAG_String"
    if tag == TAG_LIST:
        return "TAG_List"
    if tag == TAG_COMPOUND:
        return "TAG_Compound"
    if tag == TAG_INT_ARRAY:
        return "TAG_IntArray"
    if tag == TAG_LONG_ARRAY:
        return "TAG_LongArray"
    return String(t"TAG_Unknown({tag})")


def is_valid_tag(tag: UInt8) -> Bool:
    """Checks whether a tag type is known (gophertunnel `tagType.IsValid`).

    Args:
        tag: The tag type byte.

    Returns:
        `True` for `TAG_END` through `TAG_LONG_ARRAY`.
    """
    return tag <= TAG_LONG_ARRAY


def check_encoding(encoding: Int) raises:
    """Rejects values that are not one of the three encoding constants.

    Args:
        encoding: The encoding to check.

    Raises:
        If `encoding` is unknown.
    """
    if (
        encoding != NETWORK_LITTLE_ENDIAN
        and encoding != LITTLE_ENDIAN
        and encoding != BIG_ENDIAN
    ):
        raise Error(t"nbt: unknown encoding {encoding}")


def _overrun(op: StringSpan) -> Error:
    return Error(t"nbt: unexpected buffer end during op '{op}'")


# ===----------------------------------------------------------------------=== #
# Reading
# ===----------------------------------------------------------------------=== #


def read_byte(
    data: Span[UInt8, _], mut pos: Int, op: StringSpan
) raises -> UInt8:
    """Reads one byte.

    Args:
        data: The input.
        pos: The read offset; advanced by one.
        op: The operation named in the error.

    Returns:
        The byte.

    Raises:
        If the input is exhausted.
    """
    if pos >= len(data):
        raise _overrun(op)
    var b = data[pos]
    pos += 1
    return b


def _read_fixed(
    data: Span[UInt8, _], mut pos: Int, n: Int, encoding: Int, op: StringSpan
) raises -> UInt64:
    if len(data) - pos < n:
        raise _overrun(op)
    var v = UInt64(0)
    if encoding == BIG_ENDIAN:
        for i in range(n):
            v = (v << 8) | UInt64(data[pos + i])
    else:
        for i in range(n):
            v |= UInt64(data[pos + i]) << UInt64(8 * i)
    pos += n
    return v


def _read_varuint(
    data: Span[UInt8, _], mut pos: Int, max_bytes: Int, op: StringSpan
) raises -> UInt64:
    var v = UInt64(0)
    for i in range(max_bytes):
        var b = read_byte(data, pos, op)
        v |= UInt64(b & 0x7F) << UInt64(7 * i)
        if (b & 0x80) == 0:
            return v
    raise Error(t"nbt: varint did not terminate after {max_bytes} bytes")


def read_int16(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Int16:
    """Reads a `TAG_Short` payload (fixed width in every encoding).

    Args:
        data: The input.
        pos: The read offset; advanced past the value.
        encoding: The encoding.

    Returns:
        The value.

    Raises:
        If the input is exhausted.
    """
    return Int16(UInt16(_read_fixed(data, pos, 2, encoding, "Int16")))


def read_int32(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Int32:
    """Reads a `TAG_Int` payload or a length.

    Args:
        data: The input.
        pos: The read offset; advanced past the value.
        encoding: The encoding; network uses a zigzag varint32.

    Returns:
        The value.

    Raises:
        If the input is exhausted or the varint is too long.
    """
    if encoding == NETWORK_LITTLE_ENDIAN:
        var ux = UInt32(_read_varuint(data, pos, 5, "Int32"))
        var x = Int32(ux >> 1)
        if (ux & 1) != 0:
            x = ~x
        return x
    return Int32(UInt32(_read_fixed(data, pos, 4, encoding, "Int32")))


def read_int64(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Int64:
    """Reads a `TAG_Long` payload.

    Args:
        data: The input.
        pos: The read offset; advanced past the value.
        encoding: The encoding; network uses a zigzag varint64.

    Returns:
        The value.

    Raises:
        If the input is exhausted or the varint is too long.
    """
    if encoding == NETWORK_LITTLE_ENDIAN:
        var ux = _read_varuint(data, pos, 10, "Int64")
        var x = Int64(ux >> 1)
        if (ux & 1) != 0:
            x = ~x
        return x
    return Int64(_read_fixed(data, pos, 8, encoding, "Int64"))


def read_float32(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Float32:
    """Reads a `TAG_Float` payload (fixed width in every encoding).

    Args:
        data: The input.
        pos: The read offset; advanced past the value.
        encoding: The encoding.

    Returns:
        The value.

    Raises:
        If the input is exhausted.
    """
    var bits = UInt32(_read_fixed(data, pos, 4, encoding, "Float32"))
    return bitcast[DType.float32](bits)


def read_float64(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Float64:
    """Reads a `TAG_Double` payload (fixed width in every encoding).

    Args:
        data: The input.
        pos: The read offset; advanced past the value.
        encoding: The encoding.

    Returns:
        The value.

    Raises:
        If the input is exhausted.
    """
    return bitcast[DType.float64](
        _read_fixed(data, pos, 8, encoding, "Float64")
    )


def read_string_length(
    data: Span[UInt8, _], mut pos: Int, encoding: Int
) raises -> Int:
    """Reads the length prefix of a string and checks the bytes are there.

    Network strings use a varuint32 length, the others an unsigned 16-bit
    one. Lengths above `MAX_STRING_SIZE` are rejected in every encoding (Go
    accepts up to 65535 when reading big endian but never writes them).

    Args:
        data: The input.
        pos: The read offset; advanced past the prefix only.
        encoding: The encoding.

    Returns:
        The string length in bytes.

    Raises:
        If the length is too large or the input is too short.
    """
    var n: Int
    if encoding == NETWORK_LITTLE_ENDIAN:
        n = Int(UInt32(_read_varuint(data, pos, 5, "StringLength")))
    else:
        n = Int(UInt16(_read_fixed(data, pos, 2, encoding, "String")))
    if n > MAX_STRING_SIZE:
        raise Error(
            t"nbt: string is not valid: string length exceeds maximum length"
            t" (len={n})"
        )
    if len(data) - pos < n:
        raise _overrun("String")
    return n


def read_length(
    data: Span[UInt8, _],
    mut pos: Int,
    encoding: Int,
    min_width: Int,
    op: StringSpan,
) raises -> Int:
    """Reads the element count of an array or list and bounds it.

    Args:
        data: The input.
        pos: The read offset; advanced past the count.
        encoding: The encoding.
        min_width: The fewest bytes one element can take, used to reject
            counts the remaining input cannot hold before allocating.
        op: The operation named in the error.

    Returns:
        The element count.

    Raises:
        If the count is negative, above `MAX_ELEMENTS` or larger than the
        remaining input allows.
    """
    var n = Int(read_int32(data, pos, encoding))
    if n < 0:
        raise Error(t"nbt: negative length {n} during op '{op}'")
    if n > MAX_ELEMENTS:
        raise Error(t"nbt: length {n} exceeds {MAX_ELEMENTS} during op '{op}'")
    if n * min_width > len(data) - pos:
        raise _overrun(op)
    return n


# ===----------------------------------------------------------------------=== #
# Writing
# ===----------------------------------------------------------------------=== #


def _write_fixed(mut out: List[UInt8], v: UInt64, n: Int, encoding: Int):
    if encoding == BIG_ENDIAN:
        for i in range(n):
            out.append(UInt8((v >> UInt64(8 * (n - 1 - i))) & 0xFF))
    else:
        for i in range(n):
            out.append(UInt8((v >> UInt64(8 * i)) & 0xFF))


def _write_varuint(mut out: List[UInt8], v: UInt64):
    var ux = v
    while ux >= 0x80:
        out.append(UInt8(ux & 0x7F) | 0x80)
        ux >>= 7
    out.append(UInt8(ux))


def write_int16(mut out: List[UInt8], x: Int16, encoding: Int):
    """Appends a `TAG_Short` payload.

    Args:
        out: The destination.
        x: The value.
        encoding: The encoding.
    """
    _write_fixed(out, UInt64(UInt16(x)), 2, encoding)


def write_int32(mut out: List[UInt8], x: Int32, encoding: Int):
    """Appends a `TAG_Int` payload or a length.

    Args:
        out: The destination.
        x: The value.
        encoding: The encoding; network uses a zigzag varint32.
    """
    if encoding == NETWORK_LITTLE_ENDIAN:
        var ux = UInt32(x) << 1
        if x < 0:
            ux = ~ux
        _write_varuint(out, UInt64(ux))
        return
    _write_fixed(out, UInt64(UInt32(x)), 4, encoding)


def write_int64(mut out: List[UInt8], x: Int64, encoding: Int):
    """Appends a `TAG_Long` payload.

    Args:
        out: The destination.
        x: The value.
        encoding: The encoding; network uses a zigzag varint64.
    """
    if encoding == NETWORK_LITTLE_ENDIAN:
        var ux = UInt64(x) << 1
        if x < 0:
            ux = ~ux
        _write_varuint(out, ux)
        return
    _write_fixed(out, UInt64(x), 8, encoding)


def write_float32(mut out: List[UInt8], x: Float32, encoding: Int):
    """Appends a `TAG_Float` payload.

    Args:
        out: The destination.
        x: The value.
        encoding: The encoding.
    """
    _write_fixed(out, UInt64(bitcast[DType.uint32](x)), 4, encoding)


def write_float64(mut out: List[UInt8], x: Float64, encoding: Int):
    """Appends a `TAG_Double` payload.

    Args:
        out: The destination.
        x: The value.
        encoding: The encoding.
    """
    _write_fixed(out, bitcast[DType.uint64](x), 8, encoding)


def write_string(mut out: List[UInt8], s: Span[UInt8, _], encoding: Int) raises:
    """Appends a length-prefixed string (a tag name or `TAG_String` payload).

    Args:
        out: The destination.
        s: The UTF-8 bytes.
        encoding: The encoding; network uses a varuint32 length.

    Raises:
        If `s` is longer than `MAX_STRING_SIZE`.
    """
    if len(s) > MAX_STRING_SIZE:
        raise Error(
            t"nbt: string is not valid: string length exceeds maximum length"
            t" (len={len(s)})"
        )
    if encoding == NETWORK_LITTLE_ENDIAN:
        _write_varuint(out, UInt64(len(s)))
    else:
        _write_fixed(out, UInt64(len(s)), 2, encoding)
    out.extend(s)
