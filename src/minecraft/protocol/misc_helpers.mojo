"""Optional-value and list helpers (gophertunnel `OptionalFunc`, `FuncSlice`).

These complement the helpers in `io.mojo` for the value types the `misc`
group's structures need.
"""

from .block_pos import BlockPos
from .io import (
    IO,
    MAX_SLICE_LENGTH,
    actor_unique_id,
    block_pos,
    uuid,
    vec2,
    vec3,
)
from .math import Vec2, Vec3
from .uuid import UUID


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
