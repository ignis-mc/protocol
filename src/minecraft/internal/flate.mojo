"""Raw DEFLATE (RFC 1951) without a zlib or gzip wrapper.

Bedrock compresses batches with compression algorithm 0 after
NetworkSettings. gophertunnel (`minecraft/protocol/packet/compression.go`)
uses `github.com/klauspost/compress/flate`, which reads and writes the same
raw stream as Go's `compress/flate`.

`inflate` is a table-driven decoder that rejects malformed streams and stops
at a caller-supplied output limit. `deflate` is an LZ77 compressor with hash
chains (lazy matching from level 4) that emits whichever of a stored, fixed or
dynamic Huffman block is smallest.
"""

from std.bit import byte_swap, count_trailing_zeros
from std.builtin.globals import global_constant
from std.sys.info import Endian

comptime DEFAULT_MAX_DECOMPRESSED_LEN = 16 * 1024 * 1024
"""The default limit on a decompressed batch, in bytes.

Mirrors `packet.DefaultMaxDecompressedLen` in gophertunnel's `decoder.go`.
"""

comptime NO_COMPRESSION = 0
"""The level that only writes stored blocks."""
comptime BEST_SPEED = 1
"""The fastest compressing level."""
comptime BEST_COMPRESSION = 9
"""The level with the best ratio."""
comptime DEFAULT_COMPRESSION = -1
"""The default level; equivalent to 6, which gophertunnel uses."""
comptime HUFFMAN_ONLY = -2
"""The level that skips match finding and only Huffman-codes literals."""

# ===----------------------------------------------------------------------=== #
# Shared tables
# ===----------------------------------------------------------------------=== #

comptime _MAX_MATCH = 258
comptime _MIN_MATCH = 3
comptime _WINDOW = 32768
comptime _NUM_LEN_CODES = 29
comptime _NUM_DIST_CODES = 30
comptime _MAX_LIT = 286
comptime _EOB = 256


def _make_len_base() -> Array[UInt16, 29]:
    var t = Array[UInt16, 29](fill=0)
    var base = 3
    for i in range(28):
        t[i] = UInt16(base)
        base += 1 << Int(_len_extra_of(i))
    t[28] = 258
    return t^


def _len_extra_of(i: Int) -> UInt8:
    if i < 8 or i == 28:
        return 0
    return UInt8((i - 4) >> 2)


def _make_len_extra() -> Array[UInt8, 29]:
    var t = Array[UInt8, 29](fill=0)
    for i in range(29):
        t[i] = _len_extra_of(i)
    return t^


def _dist_extra_of(i: Int) -> UInt8:
    if i < 4:
        return 0
    return UInt8((i - 2) >> 1)


def _make_dist_base() -> Array[UInt16, 30]:
    var t = Array[UInt16, 30](fill=0)
    var base = 1
    for i in range(30):
        t[i] = UInt16(base)
        base += 1 << Int(_dist_extra_of(i))
    return t^


def _make_dist_extra() -> Array[UInt8, 30]:
    var t = Array[UInt8, 30](fill=0)
    for i in range(30):
        t[i] = _dist_extra_of(i)
    return t^


def _make_len_code() -> Array[UInt8, 256]:
    # Maps `length - 3` to its length code index (0..28).
    var t = Array[UInt8, 256](fill=0)
    var base = _make_len_base()
    for code in range(28):
        var lo = Int(base[code]) - 3
        var hi = lo + (1 << Int(_len_extra_of(code)))
        for j in range(lo, min(hi, 256)):
            t[j] = UInt8(code)
    t[255] = 28
    return t^


def _make_dist_code() -> Array[UInt8, 512]:
    # zlib's layout: `dist - 1` below 256 indexes directly, larger values
    # index `256 + ((dist - 1) >> 7)`.
    var t = Array[UInt8, 512](fill=0)
    var base = _make_dist_base()
    for code in range(30):
        var lo = Int(base[code]) - 1
        var hi = lo + (1 << Int(_dist_extra_of(code)))
        for d in range(lo, hi):
            if d < 256:
                t[d] = UInt8(code)
            else:
                t[256 + (d >> 7)] = UInt8(code)
    return t^


def _make_codelen_order() -> Array[UInt8, 19]:
    var t = Array[UInt8, 19](fill=0)
    var order: List[Int] = [
        16,
        17,
        18,
        0,
        8,
        7,
        9,
        6,
        10,
        5,
        11,
        4,
        12,
        3,
        13,
        2,
        14,
        1,
        15,
    ]
    for i in range(19):
        t[i] = UInt8(order[i])
    return t^


comptime _LEN_BASE = _make_len_base()
comptime _LEN_EXTRA = _make_len_extra()
comptime _DIST_BASE = _make_dist_base()
comptime _DIST_EXTRA = _make_dist_extra()
comptime _LEN_CODE = _make_len_code()
comptime _DIST_CODE = _make_dist_code()
comptime _CODELEN_ORDER = _make_codelen_order()


@inline(.always)
def _load64(p: Pointer[UInt8, _], i: Int) -> UInt64:
    # Unchecked: the caller guarantees `i + 8` bytes are readable.
    var v = (
        p.unsafe_offset(i).unsafe_bitcast[UInt64]().unsafe_load[alignment=1]()
    )
    comptime if Endian.native() == .big:
        v = byte_swap(v)
    return v


@inline(.always)
def _store64(p: MutPointer[UInt8, _], i: Int, value: UInt64):
    # Unchecked: the caller guarantees `i + 8` bytes are writable.
    var v = value
    comptime if Endian.native() == .big:
        v = byte_swap(v)
    p.unsafe_offset(i).unsafe_bitcast[UInt64]().unsafe_store[alignment=1](0, v)


@inline(.always)
def _reverse_bits(code: Int, n: Int) -> Int:
    var r = 0
    var c = code
    for _ in range(n):
        r = (r << 1) | (c & 1)
        c >>= 1
    return r


# ===----------------------------------------------------------------------=== #
# Decoder
# ===----------------------------------------------------------------------=== #

# Decode table entry layout (UInt32):
#   bits 0-3   code length, or the subtable index width for a link
#   bit  4     link to a subtable
#   bits 5-6   kind: literal/distance, length, end of block, invalid symbol
#   bits 8-11  extra bits that follow the code
#   bits 16-31 literal byte, length or distance base, or subtable offset
# A zero entry is a bit pattern that no code maps to.
comptime _LINK: UInt32 = 1 << 4
comptime _KIND_LIT = 0
comptime _KIND_LEN = 1
comptime _KIND_EOB = 2
comptime _KIND_BAD = 3

comptime _TABLE_LITLEN = 0
comptime _TABLE_DIST = 1
comptime _TABLE_CODELEN = 2

comptime _LIT_BITS = 10
comptime _DIST_BITS = 8
comptime _CODELEN_BITS = 7

# Room kept free past the write position: one maximal match plus the 8-byte
# overrun of the wide copy.
comptime _OUT_SLACK = _MAX_MATCH + 8


def _symbol_entry(table_kind: Int, sym: Int, n: Int) -> UInt32:
    var kind: Int
    var extra = 0
    var value: Int
    if table_kind == _TABLE_LITLEN:
        if sym < 256:
            kind = _KIND_LIT
            value = sym
        elif sym == _EOB:
            kind = _KIND_EOB
            value = 0
        elif sym < 257 + _NUM_LEN_CODES:
            ref base = global_constant[_LEN_BASE]()
            ref ext = global_constant[_LEN_EXTRA]()
            kind = _KIND_LEN
            value = Int(base[sym - 257])
            extra = Int(ext[sym - 257])
        else:
            kind = _KIND_BAD
            value = 0
    elif table_kind == _TABLE_DIST:
        if sym < _NUM_DIST_CODES:
            ref base = global_constant[_DIST_BASE]()
            ref ext = global_constant[_DIST_EXTRA]()
            kind = _KIND_LIT
            value = Int(base[sym])
            extra = Int(ext[sym])
        else:
            kind = _KIND_BAD
            value = 0
    else:
        kind = _KIND_LIT
        value = sym
    return UInt32((value << 16) | (extra << 8) | (kind << 5) | n)


def _build_decode_table(
    mut table: List[UInt32],
    lengths: Span[UInt8, _],
    primary_bits: Int,
    table_kind: Int,
) raises:
    """Builds a two-level decode table for canonical code `lengths`.

    Mirrors Go's `huffmanDecoder.init`: the code must be complete, except
    that an empty code and a single one-bit code are accepted (zlib does
    the same).
    """
    var count = Array[Int, 16](fill=0)
    var max_len = 0
    for i in range(len(lengths)):
        var n = Int(lengths[i])
        if n > 15:
            raise Error("flate: code length out of range")
        if n != 0:
            count[n] += 1
            max_len = max(max_len, n)
    var primary = 1 << primary_bits
    table.resize(0, 0)
    table.resize(primary, 0)
    if max_len == 0:
        return
    var next_code = Array[Int, 16](fill=0)
    var code = 0
    for n in range(1, max_len + 1):
        code <<= 1
        next_code[n] = code
        code += count[n]
    if code != (1 << max_len) and not (code == 1 and max_len == 1):
        raise Error("flate: invalid Huffman code lengths")

    var sub_bits = max(max_len - primary_bits, 0)
    var pmask = primary - 1
    for sym in range(len(lengths)):
        var n = Int(lengths[sym])
        if n == 0:
            continue
        var rev = _reverse_bits(next_code[n], n)
        next_code[n] += 1
        var entry = _symbol_entry(table_kind, sym, n)
        if n <= primary_bits:
            var j = rev
            while j < primary:
                table[j] = entry
                j += 1 << n
        else:
            var slot = rev & pmask
            var link = table[slot]
            if link & _LINK == 0:
                var offset = len(table)
                table.resize(offset + (1 << sub_bits), 0)
                link = UInt32((offset << 16) | sub_bits) | _LINK
                table[slot] = link
            var offset = Int(link >> 16)
            var j = rev >> primary_bits
            while j < (1 << sub_bits):
                table[offset + j] = entry
                j += 1 << (n - primary_bits)


struct _Inflater[origin: ImmOrigin](Movable):
    var data: Span[UInt8, Self.origin]
    var pos: Int
    var bitbuf: UInt64
    var bitcnt: Int
    var out: List[UInt8]
    var out_len: Int
    var limit: Int

    def __init__(out self, data: Span[UInt8, Self.origin], limit: Int):
        self.data = data
        self.pos = 0
        self.bitbuf = 0
        self.bitcnt = 0
        self.limit = limit
        # Same initial size as gophertunnel's DecompressAppend hint.
        var hint = max(len(data) * 2, 32 * 1024)
        hint = min(hint, limit + 1)
        self.out = List[UInt8]()
        self.out.resize(hint + _OUT_SLACK, 0)
        self.out_len = 0

    @inline(.always)
    def refill(mut self):
        var n = len(self.data)
        var src = self.data.unsafe_ptr()
        if self.pos + 8 <= n:
            # Branch-free refill: bits above `bitcnt` always hold the next
            # stream bits, so loading overlapping bytes again is harmless.
            self.bitbuf |= _load64(src, self.pos) << UInt64(self.bitcnt)
            self.pos += (63 - self.bitcnt) >> 3
            self.bitcnt |= 56
        else:
            while self.bitcnt <= 56 and self.pos < n:
                self.bitbuf |= UInt64(src[unsafe_offset=self.pos]) << UInt64(
                    self.bitcnt
                )
                self.pos += 1
                self.bitcnt += 8

    def bits(mut self, n: Int) raises -> Int:
        if self.bitcnt < n:
            self.refill()
            if self.bitcnt < n:
                raise Error("flate: unexpected end of stream")
        var v = Int(self.bitbuf & ((UInt64(1) << UInt64(n)) - 1))
        self.bitbuf >>= UInt64(n)
        self.bitcnt -= n
        return v

    def decode_symbol(
        mut self, table: Span[UInt32, _], bits: Int
    ) raises -> Int:
        if self.bitcnt < 15:
            self.refill()
        var e = table[Int(self.bitbuf) & ((1 << bits) - 1)]
        if e & _LINK != 0:
            var sub = Int(self.bitbuf >> UInt64(bits)) & (
                (1 << Int(e & 15)) - 1
            )
            e = table[Int(e >> 16) + sub]
        var n = Int(e & 15)
        if n == 0 or n > self.bitcnt:
            raise Error("flate: invalid or truncated Huffman code")
        self.bitbuf >>= UInt64(n)
        self.bitcnt -= n
        return Int(e >> 16)

    def grow(mut self, need: Int):
        """Makes room for `need` more bytes plus the copy slack."""
        var want = self.out_len + need + _OUT_SLACK
        if want <= len(self.out):
            return
        var size = max(len(self.out) * 2, 64 * 1024)
        size = min(size, self.limit + _OUT_SLACK)
        self.out.resize(max(size, want), 0)

    def stored_block(mut self) raises:
        # Drop the partial byte, then step back over whole buffered bytes.
        self.bitcnt -= self.bitcnt & 7
        self.pos -= self.bitcnt >> 3
        self.bitbuf = 0
        self.bitcnt = 0
        var n = len(self.data)
        if self.pos + 4 > n:
            raise Error("flate: unexpected end of stream")
        var length = Int(self.data[self.pos]) | (
            Int(self.data[self.pos + 1]) << 8
        )
        var nlength = Int(self.data[self.pos + 2]) | (
            Int(self.data[self.pos + 3]) << 8
        )
        self.pos += 4
        if length != (~nlength & 0xFFFF):
            raise Error("flate: stored block length check failed")
        if self.pos + length > n:
            raise Error("flate: unexpected end of stream")
        if self.out_len + length > self.limit:
            raise Error(t"flate: size exceeds limit {self.limit}")
        self.grow(length)
        var dst = self.out.unsafe_ptr().unsafe_offset(self.out_len)
        var src = self.data.unsafe_ptr().unsafe_offset(self.pos)
        var i = 0
        while i + 8 <= length:
            _store64(dst, i, _load64(src, i))
            i += 8
        while i < length:
            dst[unsafe_offset=i] = src[unsafe_offset=i]
            i += 1
        self.pos += length
        self.out_len += length

    def dynamic_header(
        mut self,
        mut lit: List[UInt32],
        mut dist: List[UInt32],
        mut codelen: List[UInt32],
    ) raises:
        var hlit = self.bits(5) + 257
        var hdist = self.bits(5) + 1
        var hclen = self.bits(4) + 4
        if hlit > _MAX_LIT or hdist > _NUM_DIST_CODES:
            raise Error("flate: too many literal or distance codes")
        ref order = global_constant[_CODELEN_ORDER]()
        var cl_lengths = Array[UInt8, 19](fill=0)
        for i in range(hclen):
            cl_lengths[Int(order[i])] = UInt8(self.bits(3))
        _build_decode_table(
            codelen, Span(cl_lengths), _CODELEN_BITS, _TABLE_CODELEN
        )

        var total = hlit + hdist
        var lengths = Array[UInt8, _MAX_LIT + _NUM_DIST_CODES](fill=0)
        var i = 0
        while i < total:
            var sym = self.decode_symbol(Span(codelen), _CODELEN_BITS)
            if sym < 16:
                lengths[i] = UInt8(sym)
                i += 1
                continue
            var rep: Int
            var value: UInt8 = 0
            if sym == 16:
                if i == 0:
                    raise Error("flate: repeat code with no previous length")
                value = lengths[i - 1]
                rep = 3 + self.bits(2)
            elif sym == 17:
                rep = 3 + self.bits(3)
            else:
                rep = 11 + self.bits(7)
            if i + rep > total:
                raise Error("flate: code length repeat overflows")
            for _ in range(rep):
                lengths[i] = value
                i += 1
        if lengths[_EOB] == 0:
            raise Error("flate: missing end-of-block code")
        var all_lengths = Span(lengths)
        _build_decode_table(lit, all_lengths[0:hlit], _LIT_BITS, _TABLE_LITLEN)
        _build_decode_table(
            dist, all_lengths[hlit:total], _DIST_BITS, _TABLE_DIST
        )

    def huffman_block(
        mut self,
        lit_table: Span[UInt32, _],
        dist_table: Span[UInt32, _],
    ) raises:
        # The hot loop keeps the stream state in locals.
        var src = self.data.unsafe_ptr()
        var n_in = len(self.data)
        var pos = self.pos
        var bitbuf = self.bitbuf
        var bitcnt = self.bitcnt
        var o = self.out_len
        var limit = self.limit
        var lt = lit_table.unsafe_ptr()
        var dt = dist_table.unsafe_ptr()
        comptime LMASK = (1 << _LIT_BITS) - 1
        comptime DMASK = (1 << _DIST_BITS) - 1
        var op = self.out.unsafe_ptr()
        var cap = len(self.out)

        while True:
            if o + _OUT_SLACK > cap:
                self.out_len = o
                self.grow(_MAX_MATCH)
                op = self.out.unsafe_ptr()
                cap = len(self.out)

            # Refill to at least 56 bits while input lasts: one symbol needs
            # at most 15 + 5 + 15 + 13 = 48.
            if pos + 8 <= n_in:
                bitbuf |= _load64(src, pos) << UInt64(bitcnt)
                pos += (63 - bitcnt) >> 3
                bitcnt |= 56
            else:
                while bitcnt <= 56 and pos < n_in:
                    bitbuf |= UInt64(src[unsafe_offset=pos]) << UInt64(bitcnt)
                    pos += 1
                    bitcnt += 8

            var e = lt[unsafe_offset=Int(bitbuf) & LMASK]
            if e & _LINK != 0:
                var sub = Int(bitbuf >> UInt64(_LIT_BITS)) & (
                    (1 << Int(e & 15)) - 1
                )
                e = lt[unsafe_offset=Int(e >> 16) + sub]
            var n = Int(e & 15)
            if n == 0 or n > bitcnt:
                raise Error("flate: invalid or truncated literal/length code")
            bitbuf >>= UInt64(n)
            bitcnt -= n
            var kind = Int(e >> 5) & 3

            if kind == _KIND_LIT:
                if o >= limit:
                    raise Error(t"flate: size exceeds limit {limit}")
                op[unsafe_offset=o] = UInt8(e >> 16)
                o += 1
                continue
            if kind == _KIND_EOB:
                break
            if kind == _KIND_BAD:
                raise Error("flate: invalid literal/length symbol")

            var extra = Int(e >> 8) & 15
            if extra > bitcnt:
                raise Error("flate: unexpected end of stream")
            var length = Int(e >> 16) + (Int(bitbuf) & ((1 << extra) - 1))
            bitbuf >>= UInt64(extra)
            bitcnt -= extra

            var d = dt[unsafe_offset=Int(bitbuf) & DMASK]
            if d & _LINK != 0:
                var sub = Int(bitbuf >> UInt64(_DIST_BITS)) & (
                    (1 << Int(d & 15)) - 1
                )
                d = dt[unsafe_offset=Int(d >> 16) + sub]
            var dn = Int(d & 15)
            if dn == 0 or dn > bitcnt:
                raise Error("flate: invalid or truncated distance code")
            bitbuf >>= UInt64(dn)
            bitcnt -= dn
            if (Int(d >> 5) & 3) == _KIND_BAD:
                raise Error("flate: invalid distance symbol")
            var dextra = Int(d >> 8) & 15
            if dextra > bitcnt:
                raise Error("flate: unexpected end of stream")
            var distance = Int(d >> 16) + (Int(bitbuf) & ((1 << dextra) - 1))
            bitbuf >>= UInt64(dextra)
            bitcnt -= dextra

            if distance > o:
                raise Error("flate: distance points before the start")
            if o + length > limit:
                raise Error(t"flate: size exceeds limit {limit}")

            # `cap - o >= _OUT_SLACK`, so the wide copy may overrun by 7.
            if distance >= 8:
                var i = 0
                while i < length:
                    _store64(op, o + i, _load64(op, o - distance + i))
                    i += 8
            elif distance == 1:
                var b = op[unsafe_offset=o - 1]
                var w = UInt64(b) * 0x0101010101010101
                var i = 0
                while i < length:
                    _store64(op, o + i, w)
                    i += 8
            else:
                for i in range(length):
                    op[unsafe_offset=o + i] = op[unsafe_offset=o - distance + i]
            o += length

        self.pos = pos
        self.bitbuf = bitbuf
        self.bitcnt = bitcnt
        self.out_len = o

    def into_output(deinit self) -> List[UInt8]:
        var out = self.out^
        out.resize(self.out_len, 0)
        return out^


def inflate(data: Span[UInt8, _], max_size: Int) raises -> List[UInt8]:
    """Decompresses a raw DEFLATE stream.

    Decoding stops after the final block; trailing bytes are ignored, as
    with Go's `flate.NewReader`.

    Args:
        data: The compressed stream.
        max_size: The largest decompressed size accepted, in bytes. Negative
            values are treated as 0.

    Returns:
        The decompressed bytes.

    Raises:
        Error: If the stream is malformed or truncated, or if the output
            would exceed `max_size`.
    """
    var inf = _Inflater(data, max(max_size, 0))
    var lit = List[UInt32]()
    var dist = List[UInt32]()
    var codelen = List[UInt32]()
    var fixed_lit = List[UInt32]()
    var fixed_dist = List[UInt32]()
    var final = False
    while not final:
        var header = inf.bits(3)
        final = header & 1 == 1
        var btype = header >> 1
        if btype == 0:
            inf.stored_block()
        elif btype == 1:
            if len(fixed_lit) == 0:
                var lengths = Array[UInt8, 288](fill=8)
                for i in range(144, 256):
                    lengths[i] = 9
                for i in range(256, 280):
                    lengths[i] = 7
                _build_decode_table(
                    fixed_lit, Span(lengths), _LIT_BITS, _TABLE_LITLEN
                )
                var dlengths = Array[UInt8, 32](fill=5)
                _build_decode_table(
                    fixed_dist, Span(dlengths), _DIST_BITS, _TABLE_DIST
                )
            inf.huffman_block(Span(fixed_lit), Span(fixed_dist))
        elif btype == 2:
            inf.dynamic_header(lit, dist, codelen)
            inf.huffman_block(Span(lit), Span(dist))
        else:
            raise Error("flate: invalid block type")
    return inf^.into_output()


# ===----------------------------------------------------------------------=== #
# Encoder
# ===----------------------------------------------------------------------=== #


struct _BitWriter(Movable):
    var out: List[UInt8]
    var acc: UInt64
    var cnt: Int

    def __init__(out self, capacity: Int):
        self.out = List[UInt8](capacity=capacity)
        self.acc = 0
        self.cnt = 0

    @inline(.always)
    def put(mut self, bits: UInt64, n: Int):
        # `n` is at most 32 and `cnt` stays below 32 between calls.
        self.acc |= bits << UInt64(self.cnt)
        self.cnt += n
        if self.cnt >= 32:
            var a = self.acc
            self.out.append(UInt8(a & 0xFF))
            self.out.append(UInt8((a >> 8) & 0xFF))
            self.out.append(UInt8((a >> 16) & 0xFF))
            self.out.append(UInt8((a >> 24) & 0xFF))
            self.acc >>= 32
            self.cnt -= 32

    def align(mut self):
        while self.cnt > 0:
            self.out.append(UInt8(self.acc & 0xFF))
            self.acc >>= 8
            self.cnt = max(self.cnt - 8, 0)
        self.acc = 0

    def into_bytes(deinit self) -> List[UInt8]:
        return self.out^


def _code_lengths(
    freq: Span[UInt32, _], max_bits: Int, mut lengths: List[UInt8]
):
    """Computes length-limited Huffman code lengths.

    Builds an unrestricted Huffman tree with the two-queue method, then
    shortens over-long codes with miniz's Kraft-sum repair. Symbols with
    zero frequency get length 0; a single used symbol is paired with a
    dummy so the code stays complete.
    """
    var n_sym = len(freq)
    lengths.resize(0, 0)
    lengths.resize(n_sym, 0)
    # Leaves sorted by (frequency, symbol); n_sym is at most 288.
    var keys = List[UInt64](capacity=n_sym)
    for s in range(n_sym):
        if freq[s] != 0:
            keys.append((UInt64(freq[s]) << 16) | UInt64(s))
    var n = len(keys)
    if n == 0:
        return
    if n <= 2:
        var s0 = Int(keys[0] & 0xFFFF)
        lengths[s0] = 1
        if n == 2:
            lengths[Int(keys[1] & 0xFFFF)] = 1
        else:
            lengths[1 if s0 == 0 else 0] = 1
        return
    sort(keys)

    # Nodes 0..n-1 are leaves, n..2n-2 internal nodes in creation order;
    # internal weights never decrease, so they form the second queue.
    var weight = Array[UInt64, 576](fill=0)
    var parent = Array[Int16, 576](fill=0)
    for i in range(n):
        weight[i] = keys[i] >> 16
    var leaf = 0
    var node = n
    var next = n
    for _ in range(n - 1):
        var pick = Array[Int, 2](fill=0)
        for k in range(2):
            if leaf < n and (node >= next or weight[leaf] <= weight[node]):
                pick[k] = leaf
                leaf += 1
            else:
                pick[k] = node
                node += 1
        weight[next] = weight[pick[0]] + weight[pick[1]]
        parent[pick[0]] = Int16(next)
        parent[pick[1]] = Int16(next)
        next += 1

    var depth = Array[Int16, 576](fill=0)
    var count = Array[Int, 16](fill=0)
    var root = 2 * n - 2
    var i = root - 1
    while i >= 0:
        depth[i] = depth[Int(parent[i])] + 1
        if i < n:
            count[min(Int(depth[i]), max_bits)] += 1
        i -= 1

    var total = 0
    for b in range(1, max_bits + 1):
        total += count[b] << (max_bits - b)
    while total != (1 << max_bits):
        # Drop a leaf from the deepest level and split a shallower leaf in
        # two: the Kraft sum falls by one each round, the leaf count stays.
        count[max_bits] -= 1
        var b = max_bits - 1
        while b > 0:
            if count[b] != 0:
                count[b] -= 1
                count[b + 1] += 2
                break
            b -= 1
        total -= 1

    # Longest codes go to the rarest symbols.
    var k = 0
    var bits = max_bits
    while bits > 0:
        for _ in range(count[bits]):
            lengths[Int(keys[k] & 0xFFFF)] = UInt8(bits)
            k += 1
        bits -= 1


def _canonical_codes(lengths: Span[UInt8, _], mut codes: List[UInt16]):
    """Assigns bit-reversed canonical codes for an LSB-first writer."""
    var count = Array[Int, 16](fill=0)
    for i in range(len(lengths)):
        count[Int(lengths[i])] += 1
    count[0] = 0
    var next_code = Array[Int, 16](fill=0)
    var code = 0
    for n in range(1, 16):
        code = (code + count[n - 1]) << 1
        next_code[n] = code
    codes.resize(0, 0)
    codes.resize(len(lengths), 0)
    for s in range(len(lengths)):
        var n = Int(lengths[s])
        if n != 0:
            codes[s] = UInt16(_reverse_bits(next_code[n], n))
            next_code[n] += 1


def _rle_lengths(lengths: Span[UInt8, _], mut items: List[UInt16]):
    """Run-length encodes code lengths into code-length alphabet symbols.

    Each item is `symbol | extra_value << 8`.
    """
    items.resize(0, 0)
    var total = len(lengths)
    var i = 0
    while i < total:
        var v = lengths[i]
        var run = 1
        while i + run < total and lengths[i + run] == v:
            run += 1
        var r = run
        if v == 0:
            while r >= 11:
                var k = min(r, 138)
                items.append(UInt16(18 | ((k - 11) << 8)))
                r -= k
            if r >= 3:
                items.append(UInt16(17 | ((r - 3) << 8)))
                r = 0
            for _ in range(r):
                items.append(0)
        else:
            items.append(UInt16(v))
            r -= 1
            while r >= 3:
                var k = min(r, 6)
                items.append(UInt16(16 | ((k - 3) << 8)))
                r -= k
            for _ in range(r):
                items.append(UInt16(v))
        i += run


@inline(.always)
def _codelen_extra_bits(sym: Int) -> Int:
    if sym == 16:
        return 2
    if sym == 17:
        return 3
    if sym == 18:
        return 7
    return 0


struct _Block(Movable):
    """Token buffer and frequencies for one block."""

    var tokens: List[UInt32]
    var lit_freq: List[UInt32]
    var dist_freq: List[UInt32]
    # Scratch reused across blocks.
    var lit_len: List[UInt8]
    var lit_code: List[UInt16]
    var dist_len: List[UInt8]
    var dist_code: List[UInt16]
    var cl_len: List[UInt8]
    var cl_code: List[UInt16]
    var rle: List[UInt16]
    var fixed_lit_len: List[UInt8]
    var fixed_lit_code: List[UInt16]
    var fixed_dist_len: List[UInt8]
    var fixed_dist_code: List[UInt16]

    def __init__(out self, capacity: Int):
        self.tokens = List[UInt32](capacity=capacity)
        self.lit_freq = List[UInt32](length=_MAX_LIT, fill=0)
        self.dist_freq = List[UInt32](length=_NUM_DIST_CODES, fill=0)
        self.lit_len = List[UInt8]()
        self.lit_code = List[UInt16]()
        self.dist_len = List[UInt8]()
        self.dist_code = List[UInt16]()
        self.cl_len = List[UInt8]()
        self.cl_code = List[UInt16]()
        self.rle = List[UInt16]()
        self.fixed_lit_len = List[UInt8](length=288, fill=8)
        for i in range(144, 256):
            self.fixed_lit_len[i] = 9
        for i in range(256, 280):
            self.fixed_lit_len[i] = 7
        self.fixed_lit_code = List[UInt16]()
        self.fixed_dist_len = List[UInt8](length=30, fill=5)
        self.fixed_dist_code = List[UInt16]()

    @inline(.always)
    def literal(mut self, b: UInt8):
        self.tokens.append(UInt32(b))
        self.lit_freq.unsafe_ptr()[unsafe_offset=Int(b)] += 1

    @inline(.always)
    def match(mut self, length: Int, distance: Int):
        ref lc = global_constant[_LEN_CODE]()
        ref dc = global_constant[_DIST_CODE]()
        self.tokens.append(
            UInt32(0x8000_0000 | ((length - 3) << 16) | (distance - 1))
        )
        var l = Int(lc[length - 3])
        self.lit_freq.unsafe_ptr()[unsafe_offset=257 + l] += 1
        var d = distance - 1
        var dcode = Int(dc[d]) if d < 256 else Int(dc[256 + (d >> 7)])
        self.dist_freq.unsafe_ptr()[unsafe_offset=dcode] += 1

    def reset(mut self):
        self.tokens.resize(0, 0)
        for i in range(_MAX_LIT):
            self.lit_freq[i] = 0
        for i in range(_NUM_DIST_CODES):
            self.dist_freq[i] = 0

    def write(
        mut self,
        mut w: _BitWriter,
        raw: Span[UInt8, _],
        final: Bool,
    ):
        """Writes the buffered tokens as the cheapest block type and resets."""
        self.lit_freq[_EOB] += 1
        ref len_extra = global_constant[_LEN_EXTRA]()
        ref dist_extra = global_constant[_DIST_EXTRA]()

        var extra_bits = 0
        for i in range(_NUM_LEN_CODES):
            extra_bits += Int(self.lit_freq[257 + i]) * Int(len_extra[i])
        for i in range(_NUM_DIST_CODES):
            extra_bits += Int(self.dist_freq[i]) * Int(dist_extra[i])

        var fixed_bits = 3 + extra_bits
        for i in range(_MAX_LIT):
            fixed_bits += Int(self.lit_freq[i]) * Int(self.fixed_lit_len[i])
        for i in range(_NUM_DIST_CODES):
            fixed_bits += Int(self.dist_freq[i]) * 5

        # Dynamic code. Make sure the distance code has a used symbol.
        var has_dist = False
        for i in range(_NUM_DIST_CODES):
            if self.dist_freq[i] != 0:
                has_dist = True
        if not has_dist:
            self.dist_freq[0] = 1
        _code_lengths(Span(self.lit_freq), 15, self.lit_len)
        _code_lengths(Span(self.dist_freq), 15, self.dist_len)
        if not has_dist:
            self.dist_freq[0] = 0
        var hlit = 257
        for i in range(257, _MAX_LIT):
            if self.lit_len[i] != 0:
                hlit = i + 1
        var hdist = 1
        for i in range(_NUM_DIST_CODES):
            if self.dist_len[i] != 0:
                hdist = i + 1
        var all_len = List[UInt8](capacity=hlit + hdist)
        for i in range(hlit):
            all_len.append(self.lit_len[i])
        for i in range(hdist):
            all_len.append(self.dist_len[i])
        _rle_lengths(Span(all_len), self.rle)
        var cl_freq = List[UInt32](length=19, fill=0)
        for i in range(len(self.rle)):
            cl_freq[Int(self.rle[i] & 0xFF)] += 1
        _code_lengths(Span(cl_freq), 7, self.cl_len)
        ref order = global_constant[_CODELEN_ORDER]()
        var hclen = 4
        for i in range(19):
            if self.cl_len[Int(order[i])] != 0:
                hclen = max(hclen, i + 1)
        var dyn_bits = 3 + 14 + 3 * hclen + extra_bits
        for i in range(19):
            dyn_bits += Int(cl_freq[i]) * (
                Int(self.cl_len[i]) + _codelen_extra_bits(i)
            )
        for i in range(_MAX_LIT):
            dyn_bits += Int(self.lit_freq[i]) * Int(self.lit_len[i])
        for i in range(_NUM_DIST_CODES):
            dyn_bits += Int(self.dist_freq[i]) * Int(self.dist_len[i])

        # Alignment padding, then a 3-bit header and LEN/NLEN per chunk.
        var n_chunks = max((len(raw) + 65534) // 65535, 1)
        var stored_bits = 7 + 8 * len(raw) + n_chunks * 35

        if stored_bits < fixed_bits and stored_bits < dyn_bits:
            _write_stored(w, raw, final)
        elif fixed_bits <= dyn_bits:
            w.put(UInt64(1 if final else 0) | (1 << 1), 3)
            if len(self.fixed_lit_code) == 0:
                _canonical_codes(Span(self.fixed_lit_len), self.fixed_lit_code)
                _canonical_codes(
                    Span(self.fixed_dist_len), self.fixed_dist_code
                )
            _write_tokens(
                w,
                Span(self.tokens),
                Span(self.fixed_lit_code),
                Span(self.fixed_lit_len),
                Span(self.fixed_dist_code),
                Span(self.fixed_dist_len),
            )
        else:
            w.put(UInt64(1 if final else 0) | (2 << 1), 3)
            w.put(UInt64(hlit - 257), 5)
            w.put(UInt64(hdist - 1), 5)
            w.put(UInt64(hclen - 4), 4)
            for i in range(hclen):
                w.put(UInt64(self.cl_len[Int(order[i])]), 3)
            _canonical_codes(Span(self.cl_len), self.cl_code)
            for i in range(len(self.rle)):
                var item = Int(self.rle[i])
                var sym = item & 0xFF
                w.put(UInt64(self.cl_code[sym]), Int(self.cl_len[sym]))
                var eb = _codelen_extra_bits(sym)
                if eb != 0:
                    w.put(UInt64(item >> 8), eb)
            _canonical_codes(Span(self.lit_len), self.lit_code)
            _canonical_codes(Span(self.dist_len), self.dist_code)
            _write_tokens(
                w,
                Span(self.tokens),
                Span(self.lit_code),
                Span(self.lit_len),
                Span(self.dist_code),
                Span(self.dist_len),
            )
        self.reset()


def _write_tokens(
    mut w: _BitWriter,
    tokens: Span[UInt32, _],
    lit_code: Span[UInt16, _],
    lit_len: Span[UInt8, _],
    dist_code: Span[UInt16, _],
    dist_len: Span[UInt8, _],
):
    ref lc = global_constant[_LEN_CODE]()
    ref dc = global_constant[_DIST_CODE]()
    ref len_base = global_constant[_LEN_BASE]()
    ref len_extra = global_constant[_LEN_EXTRA]()
    ref dist_base = global_constant[_DIST_BASE]()
    ref dist_extra = global_constant[_DIST_EXTRA]()
    var lcode = lit_code.unsafe_ptr()
    var llen = lit_len.unsafe_ptr()
    var dcode = dist_code.unsafe_ptr()
    var dlen = dist_len.unsafe_ptr()
    var tp = tokens.unsafe_ptr()
    for t in range(len(tokens)):
        var tok = Int(tp[unsafe_offset=t])
        if tok < 256:
            w.put(
                UInt64(lcode[unsafe_offset=tok]), Int(llen[unsafe_offset=tok])
            )
            continue
        var lm3 = (tok >> 16) & 0xFF
        var d = tok & 0x7FFF
        var l = Int(lc[lm3])
        var sym = 257 + l
        var n = Int(llen[unsafe_offset=sym])
        var code = UInt64(lcode[unsafe_offset=sym]) | (
            UInt64(lm3 + 3 - Int(len_base[l])) << UInt64(n)
        )
        w.put(code, n + Int(len_extra[l]))
        var dsym = Int(dc[d]) if d < 256 else Int(dc[256 + (d >> 7)])
        var dn = Int(dlen[unsafe_offset=dsym])
        var dcd = UInt64(dcode[unsafe_offset=dsym]) | (
            UInt64(d + 1 - Int(dist_base[dsym])) << UInt64(dn)
        )
        w.put(dcd, dn + Int(dist_extra[dsym]))
    w.put(UInt64(lcode[unsafe_offset=_EOB]), Int(llen[unsafe_offset=_EOB]))


def _write_stored(mut w: _BitWriter, raw: Span[UInt8, _], final: Bool):
    """Writes `raw` as stored blocks of at most 65535 bytes."""
    var pos = 0
    while True:
        var n = min(len(raw) - pos, 65535)
        var last = pos + n == len(raw)
        w.put(UInt64(1 if final and last else 0), 3)
        w.align()
        w.out.append(UInt8(n & 0xFF))
        w.out.append(UInt8(n >> 8))
        w.out.append(UInt8(~n & 0xFF))
        w.out.append(UInt8((~n >> 8) & 0xFF))
        w.out.extend(raw[pos : pos + n])
        pos += n
        if last:
            return


@fieldwise_init
struct _Config(ImplicitlyCopyable):
    var good: Int
    """Match length above which the chain search is cut to a quarter."""
    var lazy: Int
    """Lazy levels: no lazy search past this length. Greedy levels: the
    longest match whose positions are all inserted into the hash chains."""
    var nice: Int
    """Stop searching once a match this long is found."""
    var chain: Int
    """Maximum hash chain steps per search."""
    var lazy_matching: Bool


def _config(level: Int) -> _Config:
    # zlib's configuration table, except that level 6 (gophertunnel's
    # level) walks 48 chain links instead of 128: over twice as fast for
    # about 3% more output.
    if level == 1:
        return _Config(4, 4, 8, 4, False)
    if level == 2:
        return _Config(4, 5, 16, 8, False)
    if level == 3:
        return _Config(4, 6, 32, 32, False)
    if level == 4:
        return _Config(4, 4, 16, 16, True)
    if level == 5:
        return _Config(8, 16, 32, 32, True)
    if level == 6:
        return _Config(8, 16, 128, 48, True)
    if level == 7:
        return _Config(8, 32, 128, 256, True)
    if level == 8:
        return _Config(32, 128, 258, 1024, True)
    return _Config(32, 258, 258, 4096, True)


comptime _HASH_BITS = 15
comptime _BLOCK_TOKENS = 1 << 14
# zlib's TOO_FAR: a 3-byte match this far back rarely pays for itself.
comptime _TOO_FAR = 4096


struct _Matcher[origin: ImmOrigin](Movable):
    var data: Span[UInt8, Self.origin]
    var head: List[Int32]
    var prev: List[Int32]
    var hash_shift: UInt32
    var mask: Int

    def __init__(out self, data: Span[UInt8, Self.origin]):
        self.data = data
        # Small inputs get small tables: clearing 256 KiB would dominate
        # the cost of compressing a typical batch.
        var bits = 8
        while bits < _HASH_BITS and (1 << bits) < len(data):
            bits += 1
        self.hash_shift = UInt32(32 - bits)
        self.head = List[Int32](length=1 << bits, fill=-1)
        # Positions below `1 << bits` never share a `prev` slot.
        var size = min(1 << bits, _WINDOW) if bits < _HASH_BITS else _WINDOW
        self.mask = size - 1
        self.prev = List[Int32](length=size, fill=-1)

    @inline(.always)
    def insert(mut self, pos: Int) -> Int:
        """Inserts `pos` (which needs 3 readable bytes) into its chain.

        Returns:
            The previous chain head, or -1.
        """
        var p = self.data.unsafe_ptr().unsafe_offset(pos)
        var v = (
            UInt32(p[unsafe_offset=0])
            | (UInt32(p[unsafe_offset=1]) << 8)
            | (UInt32(p[unsafe_offset=2]) << 16)
        )
        var h = Int((v * 0x9E3779B1) >> self.hash_shift)
        var hp = self.head.unsafe_ptr()
        var old = Int(hp[unsafe_offset=h])
        self.prev.unsafe_ptr()[unsafe_offset=pos & self.mask] = Int32(old)
        hp[unsafe_offset=h] = Int32(pos)
        return old

    @inline(.always)
    def longest(
        self, pos: Int, candidate: Int, prev_len: Int, chain: Int, nice: Int
    ) -> Tuple[Int, Int]:
        """Searches the chain from `candidate` for a match longer than
        `prev_len`.

        Returns:
            The best length (or `prev_len`) and its distance (or 0).
        """
        var n = len(self.data)
        var src = self.data.unsafe_ptr()
        var limit = min(_MAX_MATCH, n - pos)
        var best = prev_len
        var best_dist = 0
        if limit <= best:
            return (best, 0)
        var nice_len = min(nice, limit)
        var cur = candidate
        var steps = chain
        var pp = self.prev.unsafe_ptr()
        while cur >= 0 and pos - cur <= _WINDOW and steps > 0:
            if (
                src[unsafe_offset=cur + best] == src[unsafe_offset=pos + best]
                and src[unsafe_offset=cur] == src[unsafe_offset=pos]
            ):
                var l = 0
                while l + 8 <= limit:
                    var x = _load64(src, cur + l) ^ _load64(src, pos + l)
                    if x != 0:
                        l += Int(count_trailing_zeros(x)) >> 3
                        break
                    l += 8
                else:
                    while (
                        l < limit
                        and src[unsafe_offset=cur + l]
                        == src[unsafe_offset=pos + l]
                    ):
                        l += 1
                if l > best:
                    best = l
                    best_dist = pos - cur
                    if l >= nice_len:
                        break
            var nxt = Int(pp[unsafe_offset=cur & self.mask])
            if nxt >= cur:
                break
            cur = nxt
            steps -= 1
        return (best, best_dist)


def deflate(data: Span[UInt8, _], level: Int) -> List[UInt8]:
    """Compresses `data` into a raw DEFLATE stream.

    Levels follow Go's `compress/flate`: 0 writes stored blocks only, 1 is
    the fastest and 9 the smallest, -1 means 6 and -2 Huffman-codes
    literals without matching. Other values are clamped into that range.

    Args:
        data: The bytes to compress.
        level: The compression level.

    Returns:
        A complete stream ending with a final block.
    """
    var n = len(data)
    var w = _BitWriter(n // 2 + 64)
    var lvl = level
    if lvl == DEFAULT_COMPRESSION:
        lvl = 6
    elif lvl < HUFFMAN_ONLY:
        lvl = HUFFMAN_ONLY
    elif lvl > BEST_COMPRESSION:
        lvl = BEST_COMPRESSION
    if lvl == NO_COMPRESSION:
        _write_stored(w, data, True)
        return w^.into_bytes()

    var block = _Block(_BLOCK_TOKENS + 1)
    var block_start = 0
    if lvl == HUFFMAN_ONLY:
        for i in range(n):
            block.literal(data[i])
            if len(block.tokens) >= _BLOCK_TOKENS and i + 1 < n:
                block.write(w, data[block_start : i + 1], False)
                block_start = i + 1
        block.write(w, data[block_start:n], True)
        w.align()
        return w^.into_bytes()

    var cfg = _config(lvl)
    var m = _Matcher(data)
    var src = data.unsafe_ptr()
    var pos = 0
    if not cfg.lazy_matching:
        while pos < n:
            var mlen = 0
            var mdist = 0
            if pos + _MIN_MATCH <= n:
                var cand = m.insert(pos)
                if cand >= 0 and pos - cand <= _WINDOW:
                    var found = m.longest(
                        pos, cand, _MIN_MATCH - 1, cfg.chain, cfg.nice
                    )
                    mlen = found[0]
                    mdist = found[1]
            if mlen >= _MIN_MATCH and mdist != 0:
                block.match(mlen, mdist)
                if mlen <= cfg.lazy:
                    for p in range(pos + 1, min(pos + mlen, n - 2)):
                        _ = m.insert(p)
                pos += mlen
            else:
                block.literal(src[unsafe_offset=pos])
                pos += 1
            if len(block.tokens) >= _BLOCK_TOKENS and pos < n:
                block.write(w, data[block_start:pos], False)
                block_start = pos
    else:
        var prev_len = _MIN_MATCH - 1
        var prev_dist = 0
        var pending = False
        while pos < n:
            var cur_len = _MIN_MATCH - 1
            var cur_dist = 0
            if pos + _MIN_MATCH <= n:
                var cand = m.insert(pos)
                if cand >= 0 and pos - cand <= _WINDOW and prev_len < cfg.lazy:
                    var chain = cfg.chain
                    if prev_len >= cfg.good:
                        chain >>= 2
                    var found = m.longest(pos, cand, prev_len, chain, cfg.nice)
                    if found[1] != 0:
                        cur_len = found[0]
                        cur_dist = found[1]
                        if cur_len == _MIN_MATCH and cur_dist > _TOO_FAR:
                            cur_len = _MIN_MATCH - 1
            if prev_len >= _MIN_MATCH and cur_len <= prev_len:
                # The match found at pos - 1 wins.
                block.match(prev_len, prev_dist)
                var end = pos - 1 + prev_len
                for p in range(pos + 1, min(end, n - 2)):
                    _ = m.insert(p)
                pos = end
                pending = False
                prev_len = _MIN_MATCH - 1
                prev_dist = 0
            elif pending:
                block.literal(src[unsafe_offset=pos - 1])
                prev_len = cur_len
                prev_dist = cur_dist
                pos += 1
            else:
                pending = True
                prev_len = cur_len
                prev_dist = cur_dist
                pos += 1
            # Tokens cover data[block_start : pos - 1] while a byte is
            # pending, else data[block_start : pos].
            if len(block.tokens) >= _BLOCK_TOKENS:
                var covered = pos - 1 if pending else pos
                if covered < n:
                    block.write(w, data[block_start:covered], False)
                    block_start = covered
        if pending:
            block.literal(src[unsafe_offset=n - 1])
    block.write(w, data[block_start:n], True)
    w.align()
    return w^.into_bytes()
