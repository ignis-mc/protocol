"""Fixed-size bit sets (gophertunnel `protocol/bitset.go`).

Go stores the bits in a `big.Int`; here they are 64-bit words. `bitset`
ports the Go `IO.Bitset` method: the bits go on the wire as one unsigned
LEB128 varint of arbitrary length.
"""

from .io import IO


struct Bitset(Copyable, Defaultable, Equatable, Sized, Writable):
    """A `std::bitset<size>` sent over the network; it may exceed 64 bits."""

    var _size: Int
    var _words: List[UInt64]

    def __init__(out self):
        """Creates a bit set that holds no bits."""
        self._size = 0
        self._words = List[UInt64]()

    def __init__(out self, size: Int):
        """Creates a bit set of `size` bits, all unset (Go `NewBitset`)."""
        self._size = size
        self._words = List[UInt64](length=(size + 63) // 64, fill=0)

    def _check(self, i: Int) raises:
        if i < 0 or i >= self._size:
            raise Error(t"bitset index {i} out of bounds (size {self._size})")

    def set(mut self, i: Int) raises:
        """Sets bit `i`."""
        self._check(i)
        self._words[i // 64] |= UInt64(1) << UInt64(i % 64)

    def unset(mut self, i: Int) raises:
        """Clears bit `i`."""
        self._check(i)
        self._words[i // 64] &= ~(UInt64(1) << UInt64(i % 64))

    def load(self, i: Int) raises -> Bool:
        """Reports whether bit `i` is set."""
        self._check(i)
        return (self._words[i // 64] >> UInt64(i % 64)) & 1 == 1

    def __len__(self) -> Int:
        """Gets the size of the set (Go `Len`)."""
        return self._size

    def __eq__(self, other: Self) -> Bool:
        """Compares size and bits."""
        return self._size == other._size and self._words == other._words

    def write_to(self, mut writer: Some[Writer]):
        """Writes the set bits as `Bitset(size){i, j, ...}`."""
        writer.write("Bitset(", self._size, "){")
        var first = True
        for i in range(self._size):
            if (self._words[i // 64] >> UInt64(i % 64)) & 1 == 1:
                if not first:
                    writer.write(", ")
                writer.write(i)
                first = False
        writer.write("}")


def _bit_len8(b: UInt8) -> Int:
    var n = 0
    var v = b
    while v != 0:
        n += 1
        v >>= 1
    return n


def bitset[I: IO](mut io: I, mut x: Bitset, size: Int) raises:
    """Marshals a bit set of `size` bits as one LEB128 varint.

    This is gophertunnel `IO.Bitset`, including its reader's overflow rule:
    a byte may not reach past `size` counting its continuation bit.
    """
    if io.reads():
        x = Bitset(size)
        var i = 0
        while i < size:
            var b = UInt8(0)
            io.uint8(b)
            if i + _bit_len8(b) > size:
                raise Error("bitset overflows size")
            # Bits i..i+6; the check above keeps them below `size`.
            var low = UInt64(b & 0x7F)
            x._words[i // 64] |= low << UInt64(i % 64)
            if i % 64 > 57 and i // 64 + 1 < len(x._words):
                x._words[i // 64 + 1] |= low >> UInt64(64 - i % 64)
            if b & 0x80 == 0:
                return
            i += 7
        raise Error("bitset overflows size")
    if len(x) != size:
        raise Error(t"bitset size mismatch: expected {size}, got {len(x)}")
    var words = x._words.copy()
    while True:
        var rest_zero = True
        for w in range(1, len(words)):
            if words[w] != 0:
                rest_zero = False
                break
        var low = words[0] if len(words) > 0 else UInt64(0)
        if rest_zero and low < 0x80:
            var last = UInt8(low)
            io.uint8(last)
            return
        var byte = UInt8(low & 0x7F) | 0x80
        io.uint8(byte)
        for w in range(len(words)):
            var carry = words[w + 1] << 57 if w + 1 < len(words) else UInt64(0)
            words[w] = (words[w] >> 7) | carry
