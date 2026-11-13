"""NBT values as they travel inside packets.

A packet field holding NBT keeps the encoded bytes of one complete tag in an
`NBT` value. `nbt()` and `nbt_list()` read such a tag by walking its
structure (rejecting malformed or oversized input) and write it back
byte-for-byte, so packets round-trip exactly. Decoding the bytes into a tree
of values is a separate step (`minecraft.nbt.tree`).
"""

from ..protocol.io import IO

comptime TAG_END: UInt8 = 0
"""Ends a compound; as a root tag, an empty value."""
comptime TAG_BYTE: UInt8 = 1
"""A signed byte."""
comptime TAG_SHORT: UInt8 = 2
"""A signed 16-bit integer."""
comptime TAG_INT: UInt8 = 3
"""A signed 32-bit integer."""
comptime TAG_LONG: UInt8 = 4
"""A signed 64-bit integer."""
comptime TAG_FLOAT: UInt8 = 5
"""A 32-bit float."""
comptime TAG_DOUBLE: UInt8 = 6
"""A 64-bit float."""
comptime TAG_BYTE_ARRAY: UInt8 = 7
"""A length-prefixed array of bytes."""
comptime TAG_STRING: UInt8 = 8
"""A length-prefixed UTF-8 string."""
comptime TAG_LIST: UInt8 = 9
"""A list of unnamed payloads of one tag type."""
comptime TAG_COMPOUND: UInt8 = 10
"""Named tags up to a `TAG_END`."""
comptime TAG_INT_ARRAY: UInt8 = 11
"""A length-prefixed array of 32-bit integers."""
comptime TAG_LONG_ARRAY: UInt8 = 12
"""A length-prefixed array of 64-bit integers."""

comptime NETWORK_LITTLE_ENDIAN = 0
"""Varint lengths and integers; the encoding used in packets."""
comptime LITTLE_ENDIAN = 1
"""Fixed-width little-endian; used in world storage."""
comptime BIG_ENDIAN = 2
"""Fixed-width big-endian; used by Java Edition."""

comptime _MAX_DEPTH = 512
comptime _MAX_ELEMENTS = 1 << 24
comptime _MAX_NETWORK_OFFSET = 4 * 1024 * 1024


struct NBT(Copyable, Defaultable, Writable):
    """One complete NBT tag, kept in its encoded form."""

    var raw: List[UInt8]
    """The tag type, name and payload exactly as encoded; empty for none."""
    var encoding: Int
    """Which encoding `raw` uses, one of the encoding constants."""

    def __init__(out self):
        """Creates an empty value (encoded as a single `TAG_END`)."""
        self.raw = List[UInt8]()
        self.encoding = NETWORK_LITTLE_ENDIAN

    def __init__(out self, var raw: List[UInt8], encoding: Int):
        """Wraps already encoded bytes.

        Args:
            raw: One complete encoded tag.
            encoding: The encoding of `raw`.
        """
        self.raw = raw^
        self.encoding = encoding

    @staticmethod
    def empty_compound(encoding: Int = NETWORK_LITTLE_ENDIAN) -> NBT:
        """Creates an empty root compound with an empty name.

        Args:
            encoding: The encoding to use.

        Returns:
            `{}` encoded in `encoding`.
        """
        var raw: List[UInt8] = [TAG_COMPOUND]
        if encoding == NETWORK_LITTLE_ENDIAN:
            raw.append(0)
        else:
            raw.append(0)
            raw.append(0)
        raw.append(TAG_END)
        return NBT(raw^, encoding)

    def is_empty(self) -> Bool:
        """Checks whether the value holds no tag.

        Returns:
            `True` for an empty value or a lone `TAG_END`.
        """
        return len(self.raw) == 0 or (len(self.raw) == 1 and self.raw[0] == 0)

    def root_type(self) -> UInt8:
        """Gets the type of the root tag.

        Returns:
            One of the `TAG_*` constants; `TAG_END` when empty.
        """
        if len(self.raw) == 0:
            return TAG_END
        return self.raw[0]

    def write_to(self, mut writer: Some[Writer]):
        """Writes a short description.

        Args:
            writer: The destination.
        """
        writer.write("NBT(", len(self.raw), " bytes)")


# ===----------------------------------------------------------------------=== #
# Structural walk: copies exactly one tag from the reader into `out`.
# ===----------------------------------------------------------------------=== #


def _copy_byte[I: IO](mut io: I, mut out: List[UInt8]) raises -> UInt8:
    var b = UInt8(0)
    io.uint8(b)
    out.append(b)
    return b


def _copy_n[I: IO](mut io: I, mut out: List[UInt8], n: Int) raises:
    if n < 0:
        raise Error("nbt: negative length")
    for _ in range(n):
        _ = _copy_byte(io, out)


def _copy_varuint[
    I: IO
](mut io: I, mut out: List[UInt8], max_bytes: Int) raises -> UInt64:
    var v = UInt64(0)
    for i in range(max_bytes):
        var b = _copy_byte(io, out)
        v |= UInt64(b & 0x7F) << UInt64(7 * i)
        if (b & 0x80) == 0:
            return v
    raise Error("nbt: varint overflows integer")


def _copy_int32[
    I: IO
](mut io: I, mut out: List[UInt8], encoding: Int) raises -> Int:
    """Copies an int32 and returns it; used for lengths.

    Raises:
        If the input is malformed or a value is invalid.
    """
    if encoding == NETWORK_LITTLE_ENDIAN:
        var u = UInt32(_copy_varuint(io, out, 5))
        var v = Int32(u >> 1)
        if (u & 1) != 0:
            v = ~v
        return Int(v)
    var b0 = UInt32(_copy_byte(io, out))
    var b1 = UInt32(_copy_byte(io, out))
    var b2 = UInt32(_copy_byte(io, out))
    var b3 = UInt32(_copy_byte(io, out))
    if encoding == LITTLE_ENDIAN:
        return Int(Int32(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)))
    return Int(Int32(b3 | (b2 << 8) | (b1 << 16) | (b0 << 24)))


def _copy_int64[I: IO](mut io: I, mut out: List[UInt8], encoding: Int) raises:
    if encoding == NETWORK_LITTLE_ENDIAN:
        _ = _copy_varuint(io, out, 10)
    else:
        _copy_n(io, out, 8)


def _copy_string[I: IO](mut io: I, mut out: List[UInt8], encoding: Int) raises:
    var n: Int
    if encoding == NETWORK_LITTLE_ENDIAN:
        n = Int(UInt32(_copy_varuint(io, out, 5)))
    else:
        var b0 = Int(_copy_byte(io, out))
        var b1 = Int(_copy_byte(io, out))
        n = (b0 | (b1 << 8)) if encoding == LITTLE_ENDIAN else ((b0 << 8) | b1)
    if n > 32767:
        raise Error("nbt: string too long")
    _copy_n(io, out, n)


def _copy_length[
    I: IO
](mut io: I, mut out: List[UInt8], encoding: Int) raises -> Int:
    var n = _copy_int32(io, out, encoding)
    if n < 0 or n > _MAX_ELEMENTS:
        raise Error(t"nbt: invalid length {n}")
    return n


def _check_depth(depth: Int) raises:
    # `depth` counts the containers around this one, so its own level is
    # depth + 1. gophertunnel fails reading the entries of a compound at
    # level 512.
    if depth + 1 >= _MAX_DEPTH:
        raise Error("nbt: nesting too deep")


def _copy_payload[
    I: IO
](
    mut io: I, mut out: List[UInt8], tag: UInt8, encoding: Int, depth: Int
) raises:
    if tag == TAG_BYTE:
        _copy_n(io, out, 1)
    elif tag == TAG_SHORT:
        _copy_n(io, out, 2)
    elif tag == TAG_INT:
        _ = _copy_int32(io, out, encoding)
    elif tag == TAG_LONG:
        _copy_int64(io, out, encoding)
    elif tag == TAG_FLOAT:
        _copy_n(io, out, 4)
    elif tag == TAG_DOUBLE:
        _copy_n(io, out, 8)
    elif tag == TAG_BYTE_ARRAY:
        var n = _copy_length(io, out, encoding)
        _copy_n(io, out, n)
    elif tag == TAG_STRING:
        _copy_string(io, out, encoding)
    elif tag == TAG_LIST:
        _check_depth(depth)
        var elem = _copy_byte(io, out)
        if elem > TAG_LONG_ARRAY:
            raise Error(t"nbt: unknown tag type {elem}")
        var n = _copy_length(io, out, encoding)
        if elem == TAG_END and n > 0:
            raise Error("nbt: non-empty list of TAG_End")
        for _ in range(n):
            _copy_payload(io, out, elem, encoding, depth + 1)
    elif tag == TAG_COMPOUND:
        _check_depth(depth)
        while True:
            # gophertunnel stops reading network tags past 4 MiB.
            if (
                encoding == NETWORK_LITTLE_ENDIAN
                and len(out) >= _MAX_NETWORK_OFFSET
            ):
                raise Error("nbt: limit of bytes read exhausted")
            var t = _copy_byte(io, out)
            if t == TAG_END:
                break
            _copy_string(io, out, encoding)
            _copy_payload(io, out, t, encoding, depth + 1)
    elif tag == TAG_INT_ARRAY:
        var n = _copy_length(io, out, encoding)
        for _ in range(n):
            _ = _copy_int32(io, out, encoding)
    elif tag == TAG_LONG_ARRAY:
        var n = _copy_length(io, out, encoding)
        for _ in range(n):
            _copy_int64(io, out, encoding)
    else:
        raise Error(t"nbt: unknown tag type {tag}")


def nbt[I: IO](mut io: I, mut x: NBT, encoding: Int) raises:
    """Marshals one named root tag (gophertunnel `IO.NBT`).

    A root `TAG_END` is accepted and means "no value".

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.
        encoding: The encoding on the wire.

    Raises:
        If the input is malformed or a value is invalid.
    """
    if not io.reads():
        if len(x.raw) == 0:
            var end = TAG_END
            io.uint8(end)
            return
        if x.encoding != encoding:
            raise Error("nbt: value is in a different encoding")
        io.bytes(x.raw)
        return
    var out = List[UInt8]()
    var tag = _copy_byte(io, out)
    if tag != TAG_END:
        _copy_string(io, out, encoding)
        _copy_payload(io, out, tag, encoding, 0)
    x = NBT(out^, encoding)


def nbt_list[I: IO](mut io: I, mut x: NBT, encoding: Int) raises:
    """Marshals a root list tag (gophertunnel `IO.NBTList`).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value; its root tag must be a list.
        encoding: The encoding on the wire.

    Raises:
        If the input is malformed or a value is invalid.
    """
    nbt(io, x, encoding)
    if io.reads() and x.root_type() != TAG_LIST and not x.is_empty():
        raise Error("nbt: expected a list tag")
