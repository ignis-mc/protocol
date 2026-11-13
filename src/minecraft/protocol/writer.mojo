"""The `Writer`: encodes protocol values into a growing buffer."""

from std.memory import bitcast

from .io import IO


struct Writer(IO):
    """Encodes values into an owned buffer (gophertunnel `protocol.Writer`)."""

    var buf: List[UInt8]
    """The bytes written so far."""
    var _shield_id: Int32

    def __init__(out self, shield_id: Int32 = 0):
        """Creates an empty writer.

        Args:
            shield_id: The shield's item runtime ID, from the item registry.
        """
        self.buf = List[UInt8]()
        self._shield_id = shield_id

    def take(mut self) -> List[UInt8]:
        """Takes the encoded bytes, leaving the writer empty.

        Returns:
            Everything written since construction or the last `take()`.
        """
        var out = List[UInt8]()
        swap(out, self.buf)
        return out^

    def reads(self) -> Bool:
        """Says that this IO encodes.

        Returns:
            `False`.
        """
        return False

    def _le(mut self, v: UInt64, n: Int):
        for i in range(n):
            self.buf.append(UInt8((v >> UInt64(8 * i)) & 0xFF))

    def uint8(mut self, mut x: UInt8) raises:
        """Writes an unsigned byte.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.buf.append(x)

    def int8(mut self, mut x: Int8) raises:
        """Writes a signed byte.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.buf.append(UInt8(x))

    def bool(mut self, mut x: Bool) raises:
        """Writes a boolean as 0 or 1.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.buf.append(UInt8(1) if x else UInt8(0))

    def uint16(mut self, mut x: UInt16) raises:
        """Writes a little-endian `uint16`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(UInt64(x), 2)

    def int16(mut self, mut x: Int16) raises:
        """Writes a little-endian `int16`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(UInt64(UInt16(x)), 2)

    def uint32(mut self, mut x: UInt32) raises:
        """Writes a little-endian `uint32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(UInt64(x), 4)

    def int32(mut self, mut x: Int32) raises:
        """Writes a little-endian `int32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(UInt64(UInt32(x)), 4)

    def be_int32(mut self, mut x: Int32) raises:
        """Writes a big-endian `int32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var v = UInt32(x)
        for i in range(4):
            self.buf.append(UInt8((v >> UInt32(24 - 8 * i)) & 0xFF))

    def uint64(mut self, mut x: UInt64) raises:
        """Writes a little-endian `uint64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(x, 8)

    def int64(mut self, mut x: Int64) raises:
        """Writes a little-endian `int64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(UInt64(x), 8)

    def float32(mut self, mut x: Float32) raises:
        """Writes a little-endian `float32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(UInt64(bitcast[DType.uint32](x)), 4)

    def float64(mut self, mut x: Float64) raises:
        """Writes a little-endian `float64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self._le(bitcast[DType.uint64](x), 8)

    def varuint32(mut self, mut x: UInt32) raises:
        """Writes a variable-length `uint32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var v = x
        while v >= 0x80:
            self.buf.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        self.buf.append(UInt8(v))

    def varint32(mut self, mut x: Int32) raises:
        """Writes a zigzag variable-length `int32`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var u = UInt32(x) << 1
        if x < 0:
            u = ~u
        self.varuint32(u)

    def varuint64(mut self, mut x: UInt64) raises:
        """Writes a variable-length `uint64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var v = x
        while v >= 0x80:
            self.buf.append(UInt8(v & 0x7F) | 0x80)
            v >>= 7
        self.buf.append(UInt8(v))

    def varint64(mut self, mut x: Int64) raises:
        """Writes a zigzag variable-length `int64`.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var u = UInt64(x) << 1
        if x < 0:
            u = ~u
        self.varuint64(u)

    def string(mut self, mut x: String) raises:
        """Writes a string prefixed with its varuint32 byte length.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var n = UInt32(x.byte_length())
        self.varuint32(n)
        self.buf.extend(x.as_bytes())

    def string_utf(mut self, mut x: String) raises:
        """Writes a string prefixed with its `int16` byte length.

        Args:
            x: The value.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var n = Int16(x.byte_length())
        self.int16(n)
        self.buf.extend(x.as_bytes())

    def byte_slice(mut self, mut x: List[UInt8]) raises:
        """Writes bytes prefixed with their varuint32 length.

        Args:
            x: The bytes.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var n = UInt32(len(x))
        self.varuint32(n)
        self.buf.extend(Span(x))

    def bytes(mut self, mut x: List[UInt8]) raises:
        """Writes bytes without a length prefix.

        Args:
            x: The bytes.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.buf.extend(Span(x))

    def slice_length(mut self, length: UInt32, max: UInt32) raises:
        """Accepts any length: writers trust their caller.

        Args:
            length: The element count.
            max: Ignored.

        Raises:
            If the input is malformed or a value is invalid.
        """
        pass

    def shield_id(self) -> Int32:
        """Gets the shield's item runtime ID.

        Returns:
            The value given at construction.
        """
        return self._shield_id
