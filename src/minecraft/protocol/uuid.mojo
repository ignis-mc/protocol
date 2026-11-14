"""RFC 4122 UUIDs (gophertunnel uses `github.com/google/uuid`)."""

from nethernet.wire import hex_decode


struct UUID(Defaultable, Equatable, ImplicitlyCopyable, Writable):
    """A 128-bit UUID in its canonical big-endian byte order."""

    var bytes: SIMD[DType.uint8, 16]
    """The 16 bytes, most significant first."""

    def __init__(out self):
        """Creates the nil UUID."""
        self.bytes = SIMD[DType.uint8, 16](0)

    def __init__(out self, bytes: Span[UInt8, _]) raises:
        """Creates a UUID from 16 bytes."""
        if len(bytes) != 16:
            raise Error("uuid: need exactly 16 bytes")
        self.bytes = SIMD[DType.uint8, 16](0)
        for i in range(16):
            self.bytes[i] = bytes[i]

    @staticmethod
    def parse(text: StringSpan) raises -> UUID:
        """Parses the canonical `8-4-4-4-12` hex form."""
        var raw = text.as_bytes()
        if len(raw) != 36:
            raise Error("uuid: wrong length")
        var hex = String()
        for i in range(36):
            if i == 8 or i == 13 or i == 18 or i == 23:
                if raw[i] != 0x2D:
                    raise Error("uuid: misplaced dash")
            else:
                hex += String(StringSpan(unsafe_from_utf8=raw[i : i + 1]))
        var bytes = hex_decode(hex)
        return UUID(Span(bytes))

    @staticmethod
    def from_random(random: Span[UInt8, _]) raises -> UUID:
        """Builds a version 4 UUID from 16 random bytes."""
        var id = UUID(random)
        id.bytes[6] = (id.bytes[6] & 0x0F) | 0x40
        id.bytes[8] = (id.bytes[8] & 0x3F) | 0x80
        return id

    def is_nil(self) -> Bool:
        """Checks whether every byte is zero."""
        return self.bytes.reduce_or() == 0

    def __eq__(self, other: Self) -> Bool:
        """Compares two UUIDs."""
        return self.bytes == other.bytes

    def write_to(self, mut writer: Some[Writer]):
        """Writes the canonical lowercase `8-4-4-4-12` form."""
        var digits = "0123456789abcdef".as_bytes()
        var out = List[UInt8](capacity=36)
        for i in range(16):
            if i == 4 or i == 6 or i == 8 or i == 10:
                out.append(0x2D)
            out.append(digits[Int(self.bytes[i] >> 4)])
            out.append(digits[Int(self.bytes[i] & 0xF)])
        writer.write(StringSpan(unsafe_from_utf8=Span(out)))
