"""Batch compression algorithms (gophertunnel `packet/compression.go`)."""

from ...internal.flate import deflate, inflate
from ...internal.snappy import snappy_decode, snappy_encode

comptime COMPRESSION_ALGORITHM_FLATE: UInt16 = 0
"""Raw DEFLATE (RFC 1951)."""
comptime COMPRESSION_ALGORITHM_SNAPPY: UInt16 = 1
"""Snappy block format."""
comptime COMPRESSION_ALGORITHM_NONE: UInt16 = 0xFFFF
"""No compression; on the wire the batch prefix byte is `0xff`."""

comptime DEFAULT_MAX_DECOMPRESSED_LEN = 16 * 1024 * 1024
"""The largest decompressed batch accepted by default (16 MiB)."""
comptime FLATE_LEVEL = 6
"""The flate level gophertunnel compresses batches with."""


def is_known_compression(algorithm: UInt16) -> Bool:
    """Checks whether an algorithm ID is one this library implements."""
    return (
        algorithm == COMPRESSION_ALGORITHM_FLATE
        or algorithm == COMPRESSION_ALGORITHM_SNAPPY
        or algorithm == COMPRESSION_ALGORITHM_NONE
    )


def compress(algorithm: UInt16, data: Span[UInt8, _]) raises -> List[UInt8]:
    """Compresses a batch body."""
    if algorithm == COMPRESSION_ALGORITHM_NONE:
        return List[UInt8](data)
    if algorithm == COMPRESSION_ALGORITHM_FLATE:
        return deflate(data, FLATE_LEVEL)
    if algorithm == COMPRESSION_ALGORITHM_SNAPPY:
        return snappy_encode(data)
    raise Error(t"unknown compression algorithm {algorithm}")


def decompress(
    algorithm: UInt16, data: Span[UInt8, _], limit: Int
) raises -> List[UInt8]:
    """Decompresses a batch body, refusing to produce more than `limit` bytes.
    """
    if algorithm == COMPRESSION_ALGORITHM_NONE:
        if len(data) > limit:
            raise Error(
                t"nop decompression: size {len(data)} exceeds limit {limit}"
            )
        return List[UInt8](data)
    if algorithm == COMPRESSION_ALGORITHM_FLATE:
        return inflate(data, limit)
    if algorithm == COMPRESSION_ALGORITHM_SNAPPY:
        return snappy_decode(data, limit)
    raise Error(t"unknown compression algorithm {algorithm}")
