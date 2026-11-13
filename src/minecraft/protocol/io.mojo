"""The `IO` trait: one `marshal` function serves both reading and writing.

gophertunnel defines each packet's layout once, in `Marshal(io protocol.IO)`,
and runs it against either a `Reader` or a `Writer`. This port keeps that
design. Every field is passed by `mut` reference: a `Reader` overwrites it
with the decoded value, a `Writer` encodes its current value.

```mojo
def marshal[I: IO](mut self, mut io: I) raises:
    io.varint32(self.chunk_radius)
    io.uint8(self.max_chunk_radius)
```

Code that must behave differently when reading (allocating a list before
filling it, choosing a branch from a value that was just read) asks
`io.reads()`.
"""

from std.utils import Variant

from .block_pos import BlockPos, ChunkPos, SubChunkPos
from .color import RGBA
from .math import Vec2, Vec3
from .uuid import UUID

comptime MAX_SLICE_LENGTH: UInt32 = 1024
"""The longest list a reader accepts when limits are enabled."""


trait IO(Deinitable, Movable):
    """A reader or writer of protocol values (gophertunnel `protocol.IO`)."""

    def reads(self) -> Bool:
        """Says whether this IO decodes (`True`) or encodes (`False`).

        Returns:
            `True` for a reader.
        """
        ...

    def uint8(mut self, mut x: UInt8) raises:
        """Reads or writes an unsigned byte.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def int8(mut self, mut x: Int8) raises:
        """Reads or writes a signed byte.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def bool(mut self, mut x: Bool) raises:
        """Reads or writes a boolean as one byte.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def uint16(mut self, mut x: UInt16) raises:
        """Reads or writes a little-endian `uint16`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def int16(mut self, mut x: Int16) raises:
        """Reads or writes a little-endian `int16`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def uint32(mut self, mut x: UInt32) raises:
        """Reads or writes a little-endian `uint32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def int32(mut self, mut x: Int32) raises:
        """Reads or writes a little-endian `int32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def be_int32(mut self, mut x: Int32) raises:
        """Reads or writes a big-endian `int32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def uint64(mut self, mut x: UInt64) raises:
        """Reads or writes a little-endian `uint64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def int64(mut self, mut x: Int64) raises:
        """Reads or writes a little-endian `int64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def float32(mut self, mut x: Float32) raises:
        """Reads or writes a little-endian IEEE 754 `float32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def float64(mut self, mut x: Float64) raises:
        """Reads or writes a little-endian IEEE 754 `float64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def varint32(mut self, mut x: Int32) raises:
        """Reads or writes a zigzag-encoded variable-length `int32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def varuint32(mut self, mut x: UInt32) raises:
        """Reads or writes a variable-length `uint32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def varint64(mut self, mut x: Int64) raises:
        """Reads or writes a zigzag-encoded variable-length `int64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def varuint64(mut self, mut x: UInt64) raises:
        """Reads or writes a variable-length `uint64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def string(mut self, mut x: String) raises:
        """Reads or writes a string prefixed with its varuint32 byte length.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def string_utf(mut self, mut x: String) raises:
        """Reads or writes a string prefixed with its `int16` byte length.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def byte_slice(mut self, mut x: List[UInt8]) raises:
        """Reads or writes bytes prefixed with their varuint32 length.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def bytes(mut self, mut x: List[UInt8]) raises:
        """Reads every remaining byte, or writes the bytes without a length.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def slice_length(mut self, length: UInt32, max: UInt32) raises:
        """Checks a list length a reader is about to allocate.

        Writers accept anything.

        Args:
            length: The decoded element count.
            max: The limit to enforce when limits are enabled.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...

    def shield_id(self) -> Int32:
        """Gets the item runtime ID of the shield.

        Item stacks with this ID carry an extra field.

        Returns:
            The shield's runtime ID, 0 if unknown.
        """
        ...


def unknown_enum_option(value: Int, enum: StringSpan) raises:
    """Raises the error for an enum value a packet does not know.

    Args:
        value: The offending value.
        enum: The name of the enum.

    Raises:
        Error: Always.
    """
    raise Error(t"unknown value '{value}' for enum type '{enum}'")


def invalid_value(
    value: StringSpan, for_field: StringSpan, reason: StringSpan
) raises:
    """Raises the error for a value that is not valid for a field.

    Args:
        value: The offending value, formatted.
        for_field: The field it was read into.
        reason: Why it is invalid.

    Raises:
        Error: Always.
    """
    raise Error(t"invalid value '{value}' for {for_field}: {reason}")


# ===----------------------------------------------------------------------=== #
# Composite values
# ===----------------------------------------------------------------------=== #


def actor_runtime_id[I: IO](mut io: I, mut x: UInt64) raises:
    """Marshals an entity runtime ID (a varuint64).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.varuint64(x)


def actor_unique_id[I: IO](mut io: I, mut x: Int64) raises:
    """Marshals an entity unique ID (a varint64).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.varint64(x)


def vec2[I: IO](mut io: I, mut x: Vec2) raises:
    """Marshals two `float32` values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.float32(x.x)
    io.float32(x.y)


def vec3[I: IO](mut io: I, mut x: Vec3) raises:
    """Marshals three `float32` values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.float32(x.x)
    io.float32(x.y)
    io.float32(x.z)


def block_pos[I: IO](mut io: I, mut x: BlockPos) raises:
    """Marshals a block position as three varint32 values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.varint32(x.x)
    io.varint32(x.y)
    io.varint32(x.z)


def ublock_pos[I: IO](mut io: I, mut x: BlockPos) raises:
    """Marshals a block position whose Y is a varuint32 (gophertunnel `UBlockPos`).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.varint32(x.x)
    var y = UInt32(x.y)
    io.varuint32(y)
    x.y = Int32(y)
    io.varint32(x.z)


def chunk_pos[I: IO](mut io: I, mut x: ChunkPos) raises:
    """Marshals a chunk position as two varint32 values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.varint32(x.x)
    io.varint32(x.z)


def sub_chunk_pos[I: IO](mut io: I, mut x: SubChunkPos) raises:
    """Marshals a sub-chunk position as three little-endian `int32` values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.int32(x.x)
    io.int32(x.y)
    io.int32(x.z)


def sound_pos[I: IO](mut io: I, mut x: Vec3) raises:
    """Marshals a position as a block position scaled by 8.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var b = BlockPos(Int32(x.x * 8), Int32(x.y * 8), Int32(x.z * 8))
    block_pos(io, b)
    if io.reads():
        x = Vec3(Float32(b.x) / 8, Float32(b.y) / 8, Float32(b.z) / 8)


def byte_float[I: IO](mut io: I, mut x: Float32) raises:
    """Marshals an angle as one byte of 1/256 turns.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The angle in degrees.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var v = UInt8(Int(x / (360.0 / 256.0)) & 0xFF)
    io.uint8(v)
    if io.reads():
        x = Float32(v) * (360.0 / 256.0)


def uuid[I: IO](mut io: I, mut x: UUID) raises:
    """Marshals a UUID as two little-endian 64-bit halves.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var hi = UInt64(0)
    var lo = UInt64(0)
    for i in range(8):
        hi = (hi << 8) | UInt64(x.bytes[i])
        lo = (lo << 8) | UInt64(x.bytes[8 + i])
    io.uint64(hi)
    io.uint64(lo)
    if io.reads():
        for i in range(8):
            x.bytes[7 - i] = UInt8((hi >> UInt64(8 * i)) & 0xFF)
            x.bytes[15 - i] = UInt8((lo >> UInt64(8 * i)) & 0xFF)


def rgb[I: IO](mut io: I, mut x: RGBA) raises:
    """Marshals a colour as three `float32` channels in 0 to 1.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value; alpha is set to 255 when reading.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var r = Float32(x.r) / 255
    var g = Float32(x.g) / 255
    var b = Float32(x.b) / 255
    io.float32(r)
    io.float32(g)
    io.float32(b)
    if io.reads():
        x = RGBA(
            UInt8(Int(r * 255) & 0xFF),
            UInt8(Int(g * 255) & 0xFF),
            UInt8(Int(b * 255) & 0xFF),
            255,
        )


def rgba[I: IO](mut io: I, mut x: RGBA) raises:
    """Marshals a colour as a little-endian `uint32` (R in the low byte).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var v = (
        UInt32(x.r)
        | (UInt32(x.g) << 8)
        | (UInt32(x.b) << 16)
        | (UInt32(x.a) << 24)
    )
    io.uint32(v)
    if io.reads():
        x = RGBA(
            UInt8(v & 0xFF),
            UInt8((v >> 8) & 0xFF),
            UInt8((v >> 16) & 0xFF),
            UInt8(v >> 24),
        )


def be_argb[I: IO](mut io: I, mut x: RGBA) raises:
    """Marshals a colour as a big-endian `int32` in ARGB byte order.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var v = Int32(
        Int(x.a) | (Int(x.r) << 8) | (Int(x.g) << 16) | (Int(x.b) << 24)
    )
    io.be_int32(v)
    if io.reads():
        var u = UInt32(v)
        x = RGBA(
            UInt8((u >> 8) & 0xFF),
            UInt8((u >> 16) & 0xFF),
            UInt8(u >> 24),
            UInt8(u & 0xFF),
        )


# ===----------------------------------------------------------------------=== #
# Lists and optionals (gophertunnel Slice, FuncSlice, Optional)
# ===----------------------------------------------------------------------=== #


trait Marshaler(Copyable, Defaultable, Deinitable):
    """A value with a layout (gophertunnel `protocol.Marshaler`)."""

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field of the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ...


def slice_of_len[
    T: Marshaler, I: IO
](mut io: I, length: UInt32, mut x: List[T]) raises:
    """Marshals `length` elements whose count was already marshalled.

    Parameters:
        T: The element type.
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        length: The element count.
        x: The list; replaced with `length` new elements when reading.

    Raises:
        If the input is malformed or a value is invalid.
    """
    if io.reads():
        io.slice_length(length, MAX_SLICE_LENGTH)
        x = List[T](capacity=Int(length))
        for _ in range(Int(length)):
            var e = T()
            e.marshal(io)
            x.append(e^)
        return
    for i in range(len(x)):
        x[i].marshal(io)


def slice[T: Marshaler, I: IO](mut io: I, mut x: List[T]) raises:
    """Marshals a list prefixed with its varuint32 length.

    Parameters:
        T: The element type.
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var count = UInt32(len(x))
    io.varuint32(count)
    slice_of_len(io, count, x)


def slice_uint8_length[T: Marshaler, I: IO](mut io: I, mut x: List[T]) raises:
    """Marshals a list prefixed with its length as one byte.

    Parameters:
        T: The element type.
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var count = UInt8(len(x))
    io.uint8(count)
    slice_of_len(io, UInt32(count), x)


def slice_uint32_length[T: Marshaler, I: IO](mut io: I, mut x: List[T]) raises:
    """Marshals a list prefixed with its length as a little-endian `uint32`.

    Parameters:
        T: The element type.
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var count = UInt32(len(x))
    io.uint32(count)
    slice_of_len(io, count, x)


def optional_marshaler[
    T: Marshaler, I: IO
](mut io: I, mut x: Optional[T]) raises:
    """Marshals a presence flag, then the value if present.

    Parameters:
        T: The value type.
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if io.reads():
        if present:
            var v = T()
            v.marshal(io)
            x = v^
        else:
            x = None
        return
    if present:
        x.value().marshal(io)


def _count[I: IO](mut io: I, n: Int) raises -> Int:
    var count = UInt32(n)
    io.varuint32(count)
    if io.reads():
        io.slice_length(count, MAX_SLICE_LENGTH)
    return Int(count)


def string_slice[I: IO](mut io: I, mut x: List[String]) raises:
    """Marshals a varuint32-prefixed list of strings.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[String](capacity=n)
        for _ in range(n):
            var s = String()
            io.string(s)
            x.append(s^)
        return
    for i in range(n):
        io.string(x[i])


def varint32_slice[I: IO](mut io: I, mut x: List[Int32]) raises:
    """Marshals a varuint32-prefixed list of varint32 values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[Int32](length=n, fill=0)
    for i in range(n):
        io.varint32(x[i])


def varuint32_slice[I: IO](mut io: I, mut x: List[UInt32]) raises:
    """Marshals a varuint32-prefixed list of varuint32 values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[UInt32](length=n, fill=0)
    for i in range(n):
        io.varuint32(x[i])


def varint64_slice[I: IO](mut io: I, mut x: List[Int64]) raises:
    """Marshals a varuint32-prefixed list of varint64 values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[Int64](length=n, fill=0)
    for i in range(n):
        io.varint64(x[i])


def varuint64_slice[I: IO](mut io: I, mut x: List[UInt64]) raises:
    """Marshals a varuint32-prefixed list of varuint64 values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[UInt64](length=n, fill=0)
    for i in range(n):
        io.varuint64(x[i])


def uint8_slice[I: IO](mut io: I, mut x: List[UInt8]) raises:
    """Marshals a varuint32-prefixed list of single bytes.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[UInt8](length=n, fill=0)
    for i in range(n):
        io.uint8(x[i])


def int32_slice[I: IO](mut io: I, mut x: List[Int32]) raises:
    """Marshals a varuint32-prefixed list of little-endian `int32` values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[Int32](length=n, fill=0)
    for i in range(n):
        io.int32(x[i])


def uuid_slice[I: IO](mut io: I, mut x: List[UUID]) raises:
    """Marshals a varuint32-prefixed list of UUIDs.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[UUID](length=n, fill=UUID())
    for i in range(n):
        uuid(io, x[i])


def block_pos_slice[I: IO](mut io: I, mut x: List[BlockPos]) raises:
    """Marshals a varuint32-prefixed list of block positions.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = _count(io, len(x))
    if io.reads():
        x = List[BlockPos](length=n, fill=BlockPos())
    for i in range(n):
        block_pos(io, x[i])


def optional_string[I: IO](mut io: I, mut x: Optional[String]) raises:
    """Marshals a presence flag, then a string if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.value().copy() if x is not None else String()
    io.string(v)
    x = v^


def optional_bool[I: IO](mut io: I, mut x: Optional[Bool]) raises:
    """Marshals a presence flag, then a boolean if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(False)
    io.bool(v)
    x = v


def optional_uint8[I: IO](mut io: I, mut x: Optional[UInt8]) raises:
    """Marshals a presence flag, then a byte if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.uint8(v)
    x = v


def optional_int32[I: IO](mut io: I, mut x: Optional[Int32]) raises:
    """Marshals a presence flag, then a little-endian `int32` if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.int32(v)
    x = v


def optional_uint32[I: IO](mut io: I, mut x: Optional[UInt32]) raises:
    """Marshals a presence flag, then a little-endian `uint32` if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.uint32(v)
    x = v


def optional_varint32[I: IO](mut io: I, mut x: Optional[Int32]) raises:
    """Marshals a presence flag, then a varint32 if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.varint32(v)
    x = v


def optional_float32[I: IO](mut io: I, mut x: Optional[Float32]) raises:
    """Marshals a presence flag, then a `float32` if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.float32(v)
    x = v


def optional_actor_unique_id[I: IO](mut io: I, mut x: Optional[Int64]) raises:
    """Marshals a presence flag, then an entity unique ID (varint64) if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    actor_unique_id(io, v)
    x = v


def optional_uint64[I: IO](mut io: I, mut x: Optional[UInt64]) raises:
    """Marshals a presence flag, then a little-endian `uint64` if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.uint64(v)
    x = v


def optional_byte_slice[I: IO](mut io: I, mut x: Optional[List[UInt8]]) raises:
    """Marshals a presence flag, then varuint32-prefixed bytes if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = List[UInt8]()
    if case .Some(ref b) = x:
        v = b.copy()
    io.byte_slice(v)
    x = v^


def optional_block_pos[I: IO](mut io: I, mut x: Optional[BlockPos]) raises:
    """Marshals a presence flag, then a block position if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(BlockPos())
    block_pos(io, v)
    x = v


def optional_vec2[I: IO](mut io: I, mut x: Optional[Vec2]) raises:
    """Marshals a presence flag, then two `float32` values if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(Vec2())
    vec2(io, v)
    x = v


def optional_vec3[I: IO](mut io: I, mut x: Optional[Vec3]) raises:
    """Marshals a presence flag, then three `float32` values if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(Vec3())
    vec3(io, v)
    x = v


def optional_uuid[I: IO](mut io: I, mut x: Optional[UUID]) raises:
    """Marshals a presence flag, then a UUID if present.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(UUID())
    uuid(io, v)
    x = v


def uint32_slice[I: IO](mut io: I, mut x: List[UInt32]) raises:
    """Marshals a varuint32-prefixed list of little-endian `uint32` values.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var n = UInt32(len(x))
    io.varuint32(n)
    if io.reads():
        io.slice_length(n, MAX_SLICE_LENGTH)
        x = List[UInt32](length=Int(n), fill=0)
    for i in range(Int(n)):
        io.uint32(x[i])


def func_slice_of_len[
    T: Copyable & Defaultable & Deinitable,
    I: IO,
    //,
    f: def(mut I, mut T) thin raises -> None,
](mut io: I, length: UInt32, mut x: List[T]) raises:
    """Marshals `length` elements with `f` (gophertunnel `FuncSliceOfLen`).

    Parameters:
        T: The element type.
        I: The reader or writer type.
        f: The IO function for one element, such as `I.float32`.

    Args:
        io: The reader or writer.
        length: The element count, already marshalled by the caller.
        x: The list; replaced with `length` new elements when reading.

    Raises:
        If the input is malformed or a value is invalid.
    """
    if io.reads():
        io.slice_length(length, MAX_SLICE_LENGTH)
        x = List[T](capacity=Int(length))
        for _ in range(Int(length)):
            var e = T()
            f(io, e)
            x.append(e^)
        return
    for i in range(len(x)):
        f(io, x[i])


def func_slice[
    T: Copyable & Defaultable & Deinitable,
    I: IO,
    //,
    f: def(mut I, mut T) thin raises -> None,
](mut io: I, mut x: List[T]) raises:
    """Marshals a varuint32-prefixed list with `f` (gophertunnel `FuncSlice`).

    Parameters:
        T: The element type.
        I: The reader or writer type.
        f: The IO function for one element, such as `I.float32`.

    Args:
        io: The reader or writer.
        x: The list.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var count = UInt32(len(x))
    io.varuint32(count)
    func_slice_of_len[f](io, count, x)


def optional_func[
    T: Copyable & Defaultable & Deinitable,
    I: IO,
    //,
    f: def(mut I, mut T) thin raises -> None,
](mut io: I, mut x: Optional[T]) raises:
    """Marshals a presence flag, then the value with `f` if present.

    This is gophertunnel `OptionalFunc`.

    Parameters:
        T: The value type.
        I: The reader or writer type.
        f: The IO function for the value, such as `vec3[I]`.

    Args:
        io: The reader or writer.
        x: The optional value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.value().copy() if x is not None else T()
    f(io, v)
    x = v^


def marshal_variant[
    I: IO, *Ts: Marshaler
](mut io: I, mut x: Variant[*Ts]) raises:
    """Marshals the arm a variant of `Marshaler` structs currently holds.

    Parameters:
        I: The reader or writer type.
        Ts: The arm types.

    Args:
        io: The reader or writer.
        x: The variant.

    Raises:
        If the input is malformed or a value is invalid.
    """
    comptime for i in range(len(Ts)):
        if x.isa[Ts[i]]():
            x[Ts[i]].marshal(io)
            return
