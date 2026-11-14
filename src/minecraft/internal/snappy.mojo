"""Snappy block format, without the framing format.

Bedrock uses Snappy for compression algorithm 1. gophertunnel compresses with
`s2.EncodeSnappy` and decompresses with `s2.Decode` from
`github.com/klauspost/compress`, both of which speak the plain Snappy block
format. `snappy_encode` is a port of `github.com/golang/snappy`'s portable
encoder (`encode_other.go`) and produces byte-identical output;
`snappy_decode` follows `golang/snappy`'s `Decode`.
"""

from std.bit import byte_swap
from std.sys.info import Endian

comptime _TAG_LITERAL = 0x00
comptime _TAG_COPY1 = 0x01
comptime _TAG_COPY2 = 0x02
comptime _TAG_COPY4 = 0x03

comptime _MAX_BLOCK_SIZE = 65536
comptime _INPUT_MARGIN = 16 - 1
comptime _MIN_NON_LITERAL_BLOCK_SIZE = 1 + 1 + _INPUT_MARGIN
comptime _MAX_TABLE_SIZE = 1 << 14
comptime _TABLE_MASK = _MAX_TABLE_SIZE - 1


def snappy_max_encoded_len(src_len: Int) -> Int:
    """Returns the largest encoding of `src_len` bytes."""
    return 32 + src_len + src_len // 6


def snappy_decoded_len(data: Span[UInt8, _]) raises -> Int:
    """Reads the decoded length from the start of a Snappy block."""
    return _decoded_len(data)[0]


def _decoded_len(data: Span[UInt8, _]) raises -> Tuple[Int, Int]:
    # binary.Uvarint: at most 10 bytes, the tenth may only be 0 or 1.
    var v: UInt64 = 0
    var shift: UInt64 = 0
    for i in range(min(len(data), 10)):
        var b = data[i]
        if b < 0x80:
            if i == 9 and b > 1:
                break
            v |= UInt64(b) << shift
            if v > 0xFFFFFFFF:
                break
            return (Int(v), i + 1)
        v |= UInt64(b & 0x7F) << shift
        shift += 7
    raise Error("snappy: corrupt input")


def snappy_decode(data: Span[UInt8, _], max_size: Int) raises -> List[UInt8]:
    """Decodes a Snappy block.

    The length header is checked against `max_size` before any output is
    allocated.
    """
    var header = _decoded_len(data)
    var dlen = header[0]
    if dlen > max_size:
        raise Error(t"snappy: decoded size {dlen} exceeds limit {max_size}")
    var src = data.unsafe_ptr()
    var n = len(data)
    var s = header[1]
    # 8 spare bytes let copies move a word at a time.
    var out = List[UInt8]()
    out.resize(dlen + 8, 0)
    var dst = out.unsafe_ptr()
    var d = 0
    while s < n:
        var tag = Int(src[unsafe_offset=s])
        var kind = tag & 3
        if kind == _TAG_LITERAL:
            var x = tag >> 2
            var length: Int
            if x < 60:
                s += 1
                length = x + 1
            else:
                var extra = x - 59
                s += 1 + extra
                if s > n:
                    raise Error("snappy: corrupt input")
                var v = 0
                for i in range(extra):
                    v |= Int(src[unsafe_offset=s - extra + i]) << (8 * i)
                length = v + 1
            if length > dlen - d or length > n - s:
                raise Error("snappy: corrupt input")
            for i in range(length):
                dst[unsafe_offset=d + i] = src[unsafe_offset=s + i]
            d += length
            s += length
            continue

        var length: Int
        var offset: Int
        if kind == _TAG_COPY1:
            s += 2
            if s > n:
                raise Error("snappy: corrupt input")
            length = 4 + ((tag >> 2) & 7)
            offset = ((tag & 0xE0) << 3) | Int(src[unsafe_offset=s - 1])
        elif kind == _TAG_COPY2:
            s += 3
            if s > n:
                raise Error("snappy: corrupt input")
            length = 1 + (tag >> 2)
            offset = Int(src[unsafe_offset=s - 2]) | (
                Int(src[unsafe_offset=s - 1]) << 8
            )
        else:
            s += 5
            if s > n:
                raise Error("snappy: corrupt input")
            length = 1 + (tag >> 2)
            offset = (
                Int(src[unsafe_offset=s - 4])
                | (Int(src[unsafe_offset=s - 3]) << 8)
                | (Int(src[unsafe_offset=s - 2]) << 16)
                | (Int(src[unsafe_offset=s - 1]) << 24)
            )
        if offset <= 0 or d < offset or length > dlen - d:
            raise Error("snappy: corrupt input")
        if offset >= 8:
            var i = 0
            while i < length:
                _store64(dst, d + i, _load64(dst, d - offset + i))
                i += 8
        else:
            for i in range(length):
                dst[unsafe_offset=d + i] = dst[unsafe_offset=d - offset + i]
        d += length
    if d != dlen:
        raise Error("snappy: corrupt input")
    out.resize(dlen, 0)
    return out^


def snappy_encode(data: Span[UInt8, _]) -> List[UInt8]:
    """Encodes `data` as a Snappy block.

    The output is byte-identical to golang/snappy's `Encode`.
    """
    var out = List[UInt8](capacity=snappy_max_encoded_len(len(data)))
    var v = UInt64(len(data))
    while v >= 0x80:
        out.append(UInt8(v & 0x7F) | 0x80)
        v >>= 7
    out.append(UInt8(v))
    var table = List[UInt16](length=_MAX_TABLE_SIZE, fill=0)
    var pos = 0
    while pos < len(data):
        var end = min(pos + _MAX_BLOCK_SIZE, len(data))
        var block = data[pos:end]
        if len(block) < _MIN_NON_LITERAL_BLOCK_SIZE:
            _emit_literal(out, block)
        else:
            _encode_block(out, block, table)
        pos = end
    return out^


@inline(.always)
def _load32(p: Pointer[UInt8, _], i: Int) -> UInt32:
    var v = (
        p.unsafe_offset(i).unsafe_bitcast[UInt32]().unsafe_load[alignment=1]()
    )
    comptime if Endian.native() == .big:
        v = byte_swap(v)
    return v


@inline(.always)
def _load64(p: Pointer[UInt8, _], i: Int) -> UInt64:
    var v = (
        p.unsafe_offset(i).unsafe_bitcast[UInt64]().unsafe_load[alignment=1]()
    )
    comptime if Endian.native() == .big:
        v = byte_swap(v)
    return v


@inline(.always)
def _store64(p: MutPointer[UInt8, _], i: Int, value: UInt64):
    var v = value
    comptime if Endian.native() == .big:
        v = byte_swap(v)
    p.unsafe_offset(i).unsafe_bitcast[UInt64]().unsafe_store[alignment=1](0, v)


@inline(.always)
def _hash(u: UInt32, shift: UInt32) -> Int:
    return Int((u * 0x1E35A7BD) >> shift)


def _emit_literal(mut out: List[UInt8], lit: Span[UInt8, _]):
    var n = len(lit) - 1
    if n < 60:
        out.append(UInt8(n << 2) | _TAG_LITERAL)
    elif n < 1 << 8:
        out.append(UInt8(60 << 2) | _TAG_LITERAL)
        out.append(UInt8(n))
    else:
        out.append(UInt8(61 << 2) | _TAG_LITERAL)
        out.append(UInt8(n & 0xFF))
        out.append(UInt8((n >> 8) & 0xFF))
    out.extend(lit)


def _emit_copy(mut out: List[UInt8], offset: Int, length: Int):
    var rem = length
    var lo = UInt8(offset & 0xFF)
    var hi = UInt8((offset >> 8) & 0xFF)
    while rem >= 68:
        out.append(UInt8(63 << 2) | _TAG_COPY2)
        out.append(lo)
        out.append(hi)
        rem -= 64
    if rem > 64:
        out.append(UInt8(59 << 2) | _TAG_COPY2)
        out.append(lo)
        out.append(hi)
        rem -= 60
    if rem >= 12 or offset >= 2048:
        out.append(UInt8((rem - 1) << 2) | _TAG_COPY2)
        out.append(lo)
        out.append(hi)
        return
    out.append(UInt8(((offset >> 8) << 5) | ((rem - 4) << 2)) | _TAG_COPY1)
    out.append(lo)


def _encode_block(
    mut out: List[UInt8], block: Span[UInt8, _], mut table: List[UInt16]
):
    # A port of golang/snappy's encodeBlock; the gotos become flags.
    var n = len(block)
    var src = block.unsafe_ptr()
    var shift = UInt32(32 - 8)
    var table_size = 1 << 8
    while table_size < _MAX_TABLE_SIZE and table_size < n:
        shift -= 1
        table_size *= 2
    var tp = table.unsafe_ptr()
    for i in range(_MAX_TABLE_SIZE):
        tp[unsafe_offset=i] = 0

    var s_limit = n - _INPUT_MARGIN
    var next_emit = 0
    var s = 1
    var next_hash = _hash(_load32(src, s), shift)

    while True:
        var skip = 32
        var next_s = s
        var candidate = 0
        var done = False
        while True:
            s = next_s
            var between = skip >> 5
            next_s = s + between
            skip += between
            if next_s > s_limit:
                done = True
                break
            candidate = Int(tp[unsafe_offset=next_hash & _TABLE_MASK])
            tp[unsafe_offset=next_hash & _TABLE_MASK] = UInt16(s)
            next_hash = _hash(_load32(src, next_s), shift)
            if _load32(src, s) == _load32(src, candidate):
                break
        if done:
            break

        _emit_literal(out, block[next_emit:s])

        while True:
            var base = s
            s += 4
            var i = candidate + 4
            while s < n and src[unsafe_offset=i] == src[unsafe_offset=s]:
                i += 1
                s += 1
            _emit_copy(out, base - candidate, s - base)
            next_emit = s
            if s >= s_limit:
                done = True
                break
            var x = _load64(src, s - 1)
            var prev_hash = _hash(UInt32(x & 0xFFFFFFFF), shift)
            tp[unsafe_offset=prev_hash & _TABLE_MASK] = UInt16(s - 1)
            var cur_hash = _hash(UInt32((x >> 8) & 0xFFFFFFFF), shift)
            candidate = Int(tp[unsafe_offset=cur_hash & _TABLE_MASK])
            tp[unsafe_offset=cur_hash & _TABLE_MASK] = UInt16(s)
            if UInt32((x >> 8) & 0xFFFFFFFF) != _load32(src, candidate):
                next_hash = _hash(UInt32((x >> 16) & 0xFFFFFFFF), shift)
                s += 1
                break
        if done:
            break

    if next_emit < n:
        _emit_literal(out, block[next_emit:n])
