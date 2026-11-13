"""Batch decoding (gophertunnel `packet/decoder.go`)."""

from .compression import (
    COMPRESSION_ALGORITHM_NONE,
    DEFAULT_MAX_DECOMPRESSED_LEN,
    decompress,
)

comptime MAXIMUM_IN_BATCH = 812
"""The most packets one batch may hold."""


struct Decoder(Copyable, Defaultable):
    """Splits received batches into encoded packets."""

    var compression_enabled: Bool
    """Whether batches start with a compression algorithm byte."""
    var compression: UInt16
    """The algorithm the peer announced in NetworkSettings."""
    var max_decompressed_len: Int
    """The largest batch body accepted after decompression."""
    var check_packet_limit: Bool
    """Whether to enforce `MAXIMUM_IN_BATCH`."""

    def __init__(out self):
        """Creates a decoder for uncompressed batches."""
        self.compression_enabled = False
        self.compression = COMPRESSION_ALGORITHM_NONE
        self.max_decompressed_len = DEFAULT_MAX_DECOMPRESSED_LEN
        self.check_packet_limit = True

    def enable_compression(mut self, algorithm: UInt16, max_len: Int = 0):
        """Starts expecting an algorithm byte before every batch body.

        Args:
            algorithm: A `COMPRESSION_ALGORITHM_*` value.
            max_len: The decompressed size limit; 0 keeps the default.
        """
        self.compression_enabled = True
        self.compression = algorithm
        if max_len > 0:
            self.max_decompressed_len = max_len

    def decode(self, batch: Span[UInt8, _]) raises -> List[List[UInt8]]:
        """Splits one batch into its packets.

        Args:
            batch: One received NetherNet message.

        Returns:
            The encoded packets (header plus payload each), in order.

        Raises:
            Error: If the batch is malformed, uses an unexpected algorithm,
                or exceeds a limit.
        """
        var packets = List[List[UInt8]]()
        if len(batch) == 0:
            return packets^
        var body: List[UInt8]
        if self.compression_enabled:
            var algorithm = batch[0]
            if algorithm == 0xFF:
                body = List[UInt8](batch[1:])
            elif UInt16(algorithm) != self.compression:
                raise Error(
                    t"decompress batch: unexpected compression algorithm:"
                    t" got {algorithm}, expected {self.compression}"
                )
            else:
                body = decompress(
                    self.compression, batch[1:], self.max_decompressed_len
                )
        else:
            body = List[UInt8](batch)
        if len(body) > self.max_decompressed_len:
            raise Error(
                t"decode batch: size {len(body)} exceeds limit"
                t" {self.max_decompressed_len}"
            )
        var pos = 0
        while pos < len(body):
            var length = UInt32(0)
            var i = 0
            while True:
                if i >= 5:
                    raise Error(
                        "decode batch: varuint32 did not terminate after 5"
                        " bytes"
                    )
                if pos >= len(body):
                    raise Error("decode batch: unexpected end of packet length")
                var b = body[pos]
                pos += 1
                length |= UInt32(b & 0x7F) << UInt32(7 * i)
                i += 1
                if (b & 0x80) == 0:
                    break
            if length == 0:
                raise Error("decode batch: empty packet")
            if Int(length) > len(body) - pos:
                raise Error(
                    t"decode batch: packet length {length} exceeds remaining"
                    t" {len(body) - pos}"
                )
            if len(packets) >= MAXIMUM_IN_BATCH and self.check_packet_limit:
                raise Error(
                    t"decode batch: number of packets exceeds"
                    t" max={MAXIMUM_IN_BATCH}"
                )
            packets.append(List[UInt8](Span(body)[pos : pos + Int(length)]))
            pos += Int(length)
        return packets^
