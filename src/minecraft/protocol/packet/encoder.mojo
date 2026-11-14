"""Batch encoding (gophertunnel `packet/encoder.go`).

NetherNet sends one batch per data-channel message with no `0xfe` header and
no encryption, so the encoder only frames and compresses.
"""

from .compression import COMPRESSION_ALGORITHM_NONE, compress


def _put_varuint32(mut out: List[UInt8], value: UInt32):
    var v = value
    while v >= 0x80:
        out.append(UInt8(v & 0x7F) | 0x80)
        v >>= 7
    out.append(UInt8(v))


struct Encoder(Copyable, Defaultable):
    """Frames encoded packets into batches."""

    var compression_enabled: Bool
    """Whether batches start with a compression algorithm byte."""
    var compression: UInt16
    """The algorithm used for batches at or above the threshold."""
    var compression_threshold: Int
    """Batch bodies shorter than this are sent uncompressed."""

    def __init__(out self):
        """Creates an encoder that does not compress (before NetworkSettings).
        """
        self.compression_enabled = False
        self.compression = COMPRESSION_ALGORITHM_NONE
        self.compression_threshold = 0

    def enable_compression(mut self, algorithm: UInt16, threshold: Int):
        """Starts prefixing batches with an algorithm byte."""
        self.compression_enabled = True
        self.compression = algorithm
        self.compression_threshold = threshold

    def encode(self, packets: List[List[UInt8]]) raises -> List[UInt8]:
        """Builds one batch from encoded packets (header plus payload each)."""
        var body = List[UInt8]()
        for i in range(len(packets)):
            _put_varuint32(body, UInt32(len(packets[i])))
            body.extend(Span(packets[i]))
        if not self.compression_enabled:
            return body^
        var out = List[UInt8](capacity=len(body) + 1)
        if (
            self.compression == COMPRESSION_ALGORITHM_NONE
            or len(body) < self.compression_threshold
        ):
            out.append(0xFF)
            out.extend(Span(body))
            return out^
        out.append(UInt8(self.compression))
        out.extend(Span(compress(self.compression, Span(body))))
        return out^
