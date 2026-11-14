"""The `Reader`: decodes protocol values from a packet payload."""

from std.memory import bitcast

from .io import IO


struct Reader(IO):
    """Decodes values from a borrowed payload (gophertunnel `protocol.Reader`).

    Every read checks the remaining length and raises on truncated input, so
    a hostile packet can never read past its end or allocate unbounded lists.
    """

    var _data: List[UInt8]
    var _pos: Int
    var _shield_id: Int32
    var _limits: Bool

    def __init__(
        out self,
        data: Span[UInt8, _],
        shield_id: Int32 = 0,
        limits: Bool = True,
    ):
        """Creates a reader over a copy of `data`."""
        self._data = List[UInt8](data)
        self._pos = 0
        self._shield_id = shield_id
        self._limits = limits

    def reads(self) -> Bool:
        """Says that this IO decodes."""
        return True

    def remaining(self) -> Int:
        """Counts the unread bytes."""
        return len(self._data) - self._pos

    def offset(self) -> Int:
        """Gets the cursor position."""
        return self._pos

    def _need(self, n: Int, what: StringSpan) raises:
        if n < 0 or self._pos + n > len(self._data):
            raise Error(
                t"{what} length {n} exceeds remaining packet payload"
                t" {len(self._data) - self._pos}"
            )

    def _byte(mut self) raises -> UInt8:
        if self._pos >= len(self._data):
            raise Error("unexpected end of packet payload")
        var b = self._data[self._pos]
        self._pos += 1
        return b

    def _le(mut self, n: Int) raises -> UInt64:
        self._need(n, "integer")
        var v = UInt64(0)
        for i in range(n):
            v |= UInt64(self._data[self._pos + i]) << UInt64(8 * i)
        self._pos += n
        return v

    def uint8(mut self, mut x: UInt8) raises:
        """Reads an unsigned byte."""
        x = self._byte()

    def int8(mut self, mut x: Int8) raises:
        """Reads a signed byte."""
        x = Int8(self._byte())

    def bool(mut self, mut x: Bool) raises:
        """Reads a boolean; any non-zero byte is `True`."""
        x = self._byte() != 0

    def uint16(mut self, mut x: UInt16) raises:
        """Reads a little-endian `uint16`."""
        x = UInt16(self._le(2))

    def int16(mut self, mut x: Int16) raises:
        """Reads a little-endian `int16`."""
        x = Int16(UInt16(self._le(2)))

    def uint32(mut self, mut x: UInt32) raises:
        """Reads a little-endian `uint32`."""
        x = UInt32(self._le(4))

    def int32(mut self, mut x: Int32) raises:
        """Reads a little-endian `int32`."""
        x = Int32(UInt32(self._le(4)))

    def be_int32(mut self, mut x: Int32) raises:
        """Reads a big-endian `int32`."""
        self._need(4, "integer")
        var v = UInt32(0)
        for i in range(4):
            v = (v << 8) | UInt32(self._data[self._pos + i])
        self._pos += 4
        x = Int32(v)

    def uint64(mut self, mut x: UInt64) raises:
        """Reads a little-endian `uint64`."""
        x = self._le(8)

    def int64(mut self, mut x: Int64) raises:
        """Reads a little-endian `int64`."""
        x = Int64(self._le(8))

    def float32(mut self, mut x: Float32) raises:
        """Reads a little-endian `float32`."""
        x = bitcast[DType.float32](UInt32(self._le(4)))

    def float64(mut self, mut x: Float64) raises:
        """Reads a little-endian `float64`."""
        x = bitcast[DType.float64](self._le(8))

    def varuint32(mut self, mut x: UInt32) raises:
        """Reads a variable-length `uint32` of at most 5 bytes."""
        var v = UInt32(0)
        for i in range(5):
            var b = self._byte()
            v |= UInt32(b & 0x7F) << UInt32(7 * i)
            if (b & 0x80) == 0:
                x = v
                return
        raise Error("varint overflows integer")

    def varint32(mut self, mut x: Int32) raises:
        """Reads a zigzag variable-length `int32`."""
        var u = UInt32(0)
        self.varuint32(u)
        var v = Int32(u >> 1)
        if (u & 1) != 0:
            v = ~v
        x = v

    def varuint64(mut self, mut x: UInt64) raises:
        """Reads a variable-length `uint64` of at most 10 bytes."""
        var v = UInt64(0)
        for i in range(10):
            var b = self._byte()
            v |= UInt64(b & 0x7F) << UInt64(7 * i)
            if (b & 0x80) == 0:
                x = v
                return
        raise Error("varint overflows integer")

    def varint64(mut self, mut x: Int64) raises:
        """Reads a zigzag variable-length `int64`."""
        var u = UInt64(0)
        self.varuint64(u)
        var v = Int64(u >> 1)
        if (u & 1) != 0:
            v = ~v
        x = v

    def _text(mut self, n: Int) raises -> String:
        self._need(n, "string")
        var s = String(
            from_utf8_lossy=Span(self._data)[self._pos : self._pos + n]
        )
        self._pos += n
        return s^

    def string(mut self, mut x: String) raises:
        """Reads a string prefixed with its varuint32 byte length.

        Invalid UTF-8 is replaced with U+FFFD rather than rejected, as the
        game sends arbitrary bytes in some string fields.
        """
        var n = UInt32(0)
        self.varuint32(n)
        x = self._text(Int(n))

    def string_utf(mut self, mut x: String) raises:
        """Reads a string prefixed with its `int16` byte length."""
        var n = Int16(0)
        self.int16(n)
        x = self._text(Int(n))

    def byte_slice(mut self, mut x: List[UInt8]) raises:
        """Reads bytes prefixed with their varuint32 length."""
        var n = UInt32(0)
        self.varuint32(n)
        self._need(Int(n), "byte slice")
        x = List[UInt8](Span(self._data)[self._pos : self._pos + Int(n)])
        self._pos += Int(n)

    def bytes(mut self, mut x: List[UInt8]) raises:
        """Reads every remaining byte."""
        x = List[UInt8](Span(self._data)[self._pos : len(self._data)])
        self._pos = len(self._data)

    def slice_length(mut self, length: UInt32, max: UInt32) raises:
        """Rejects list lengths over `max` (when limits are on) or the payload.
        """
        if length > max and self._limits:
            raise Error(
                t"slice length was too long: length of {length} (max {max})"
            )
        if Int(length) > self.remaining():
            raise Error(
                t"slice length {length} exceeds remaining packet payload"
                t" {self.remaining()}"
            )

    def shield_id(self) -> Int32:
        """Gets the shield's item runtime ID."""
        return self._shield_id
