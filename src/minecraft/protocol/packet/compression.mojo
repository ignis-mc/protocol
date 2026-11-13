"""Batch compression algorithms (gophertunnel `packet/compression.go`)."""

comptime COMPRESSION_ALGORITHM_FLATE: UInt16 = 0
"""Raw DEFLATE (RFC 1951)."""
comptime COMPRESSION_ALGORITHM_SNAPPY: UInt16 = 1
"""Snappy block format."""
comptime COMPRESSION_ALGORITHM_NONE: UInt16 = 0xFFFF
"""No compression; on the wire the batch prefix byte is `0xff`."""

comptime DEFAULT_MAX_DECOMPRESSED_LEN = 16 * 1024 * 1024
"""The largest decompressed batch accepted by default (16 MiB)."""


def is_known_compression(algorithm: UInt16) -> Bool:
    """Checks whether an algorithm ID is one this library implements.

    Args:
        algorithm: A `COMPRESSION_ALGORITHM_*` value.

    Returns:
        `True` for flate, snappy and none.
    """
    return (
        algorithm == COMPRESSION_ALGORITHM_FLATE
        or algorithm == COMPRESSION_ALGORITHM_SNAPPY
        or algorithm == COMPRESSION_ALGORITHM_NONE
    )


def compress(algorithm: UInt16, data: Span[UInt8, _]) raises -> List[UInt8]:
    """Compresses a batch body.

    Args:
        algorithm: A `COMPRESSION_ALGORITHM_*` value.
        data: The uncompressed batch body.

    Returns:
        The compressed bytes.

    Raises:
        Error: If the algorithm is unknown or not available.
    """
    if algorithm == COMPRESSION_ALGORITHM_NONE:
        return List[UInt8](data)
    raise Error(t"compression algorithm {algorithm} is not available")


def decompress(
    algorithm: UInt16, data: Span[UInt8, _], limit: Int
) raises -> List[UInt8]:
    """Decompresses a batch body, refusing to produce more than `limit` bytes.

    Args:
        algorithm: A `COMPRESSION_ALGORITHM_*` value.
        data: The compressed batch body.
        limit: The largest acceptable output size.

    Returns:
        The decompressed bytes.

    Raises:
        Error: If the algorithm is unknown, the data is malformed, or the
            output would exceed `limit`.
    """
    if algorithm == COMPRESSION_ALGORITHM_NONE:
        if len(data) > limit:
            raise Error(
                t"nop decompression: size {len(data)} exceeds limit {limit}"
            )
        return List[UInt8](data)
    raise Error(t"compression algorithm {algorithm} is not available")
