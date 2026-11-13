"""PlayerAuthInput flags (gophertunnel `protocol/input_flags.go`)."""

from .entities_helpers import func_slice_of_len
from .io import IO, invalid_value, unknown_enum_option


struct InputFlags(Copyable, Defaultable, Equatable, Sized):
    """The input flags of a PlayerAuthInput packet.

    They go on the wire as the list of the IDs that are set and are stored
    the same way, with the IDs kept unique. The zero value has no size; use
    `InputFlags(size)` before setting a flag. Decoded values are sized.
    """

    var _set: Bool
    var _size: Int
    var _ids: List[Int32]

    def __init__(out self):
        """Creates an absent value with no size."""
        self._set = False
        self._size = 0
        self._ids = List[Int32]()

    def __init__(out self, size: Int):
        """Creates flags in the range [0, size), none set (Go `NewInputFlags`).

        Args:
            size: The number of flags.
        """
        self._set = True
        self._size = size
        self._ids = List[Int32]()

    @staticmethod
    def from_ids(size: Int, ids: Span[Int32, _]) raises -> InputFlags:
        """Creates flags with the IDs given set (Go `NewInputFlagsFromIDs`).

        Duplicate IDs are ignored.

        Args:
            size: The number of flags.
            ids: The IDs to set.

        Returns:
            The flags.

        Raises:
            If an ID is outside [0, size).
        """
        var flags = InputFlags(size)
        for id in ids:
            flags.set(Int(id))
        return flags^

    def _check(self, i: Int) raises:
        if i < 0 or i >= self._size:
            raise Error(t"input flag {i} out of bounds (size {self._size})")

    def present(self) -> Bool:
        """Reports whether the value holds flags at all.

        Returns:
            `False` for the zero value, which reports every flag unset.
        """
        return self._set

    def load(self, i: Int) raises -> Bool:
        """Reports whether flag `i` is set.

        Args:
            i: The flag index.

        Returns:
            `True` if the flag is set; `False` for an absent value.

        Raises:
            If `i` is outside the range.
        """
        if not self._set:
            return False
        self._check(i)
        return Int32(i) in self._ids

    def set(mut self, i: Int) raises:
        """Sets flag `i` and marks the value present.

        Setting a flag that is already set does nothing.

        Args:
            i: The flag index.

        Raises:
            If `i` is outside the range.
        """
        self._check(i)
        self._set = True
        if Int32(i) not in self._ids:
            self._ids.append(Int32(i))

    def unset(mut self, i: Int) raises:
        """Clears flag `i`; does nothing for an absent value.

        Args:
            i: The flag index.

        Raises:
            If `i` is outside the range.
        """
        if not self._set:
            return
        self._check(i)
        for at in range(len(self._ids)):
            if self._ids[at] == Int32(i):
                _ = self._ids.pop(at)
                return

    def ids(self) -> Span[Int32, origin_of(self._ids)]:
        """Gets the set IDs in insertion (wire) order.

        Returns:
            A view of the IDs.
        """
        return Span(self._ids)

    def __len__(self) -> Int:
        """Gets the number of flags the value can hold (Go `Len`).

        Returns:
            The size.
        """
        return self._size

    def __eq__(self, other: Self) -> Bool:
        """Compares presence, size and IDs in order.

        Args:
            other: The other value.

        Returns:
            `True` if all three are equal.
        """
        return (
            self._set == other._set
            and self._size == other._size
            and self._ids == other._ids
        )


def input_flag_list[I: IO](mut io: I, mut x: InputFlags, size: Int) raises:
    """Marshals flags in [0, size) as a varuint32-prefixed list of varint32 IDs.

    This is gophertunnel `InputFlagList`. The IDs must be unique and in
    range, on both the reading and the writing side.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The flags; replaced by a sized value when reading.
        size: The number of flags.

    Raises:
        If there are more IDs than `size`, an ID is out of range or repeated,
        or the input is malformed.
    """
    # The count is checked before reading, so a peer cannot claim far more
    # flags than can legally be sent.
    var count = UInt32(len(x._ids))
    io.varuint32(count)
    if Int(count) > size:
        invalid_value(String(count), "player auth input data", "too many flags")
    var ids = x._ids.copy()
    func_slice_of_len[I.varint32](io, count, ids)
    for n in range(len(ids)):
        var id = ids[n]
        if id < 0 or Int(id) >= size:
            unknown_enum_option(Int(id), "player auth input data")
        for m in range(n):
            if ids[m] == id:
                invalid_value(
                    String(id), "player auth input data", "flags must be unique"
                )
    x._set = True
    x._size = size
    x._ids = ids^
