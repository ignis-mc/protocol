"""Generic IO helpers used by the `entities` group (gophertunnel `io.go`).

These port `FuncSlice`, `FuncSliceOfLen` and `OptionalFunc`, which take the
per-element IO function as an argument. In Mojo the function is a compile-time
parameter, so a Go call such as `FuncSlice(r, &x.Coords, r.Float32)` reads
`func_slice[I.float32](io, self.coords)` and
`OptionalFunc(r, &x.Pos, r.Vec3)` reads `optional_func[vec3[I]](io, self.pos)`.

`marshal_variant` dispatches `marshal` to whichever arm a `Variant` of
`Marshaler` structs holds; it backs the Go interfaces (`Event`, `ShapeData`)
that this group maps to `Variant`.
"""

from std.utils import Variant

from .io import IO, MAX_SLICE_LENGTH, Marshaler


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
