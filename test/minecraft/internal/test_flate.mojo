from minecraft.internal.flate import (
    BEST_COMPRESSION,
    DEFAULT_COMPRESSION,
    DEFAULT_MAX_DECOMPRESSED_LEN,
    HUFFMAN_ONLY,
    NO_COMPRESSION,
    deflate,
    inflate,
)
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)

comptime HELLO = "hello, hello, hello world"
comptime PARAGRAPH = (
    "The quick brown fox jumps over the lazy dog. Minecraft: Bedrock Edition"
    " compresses every batch of packets with raw DEFLATE or Snappy after"
    " NetworkSettings. The quick brown fox jumps over the lazy dog again, and"
    " again, and again: packet, chunk, entity, player, block, item stack,"
    " inventory, window, level, world, dimension, biome. The quick brown fox"
    " jumps over the lazy dog."
)


def _bytes(s: StringSpan) -> List[UInt8]:
    return List[UInt8](s.as_bytes())


def _repeated() -> List[UInt8]:
    # "abcd" * 50 + "xyz" * 30
    var out = List[UInt8]()
    for _ in range(50):
        out.extend("abcd".as_bytes())
    for _ in range(30):
        out.extend("xyz".as_bytes())
    return out^


def _same(a: Span[UInt8, _], b: Span[UInt8, _]) -> Bool:
    if len(a) != len(b):
        return False
    for i in range(len(a)):
        if a[i] != b[i]:
            return False
    return True


struct _Rng(Movable):
    var s: UInt64

    def __init__(out self, seed: UInt64):
        self.s = seed

    def next(mut self) -> UInt64:
        # xorshift64*
        self.s ^= self.s >> 12
        self.s ^= self.s << 25
        self.s ^= self.s >> 27
        return self.s * 0x2545F4914F6CDD1D


def _mixed(n: Int, seed: UInt64) -> List[UInt8]:
    """Deterministic input mixing words, random bytes and runs."""
    var words: List[String] = [
        "packet ",
        "chunk ",
        "entity ",
        "player ",
        "block ",
        "item stack ",
        "inventory ",
        "minecraft ",
        "bedrock ",
        ".\n",
    ]
    var rng = _Rng(seed)
    var out = List[UInt8](capacity=n + 4096)
    while len(out) < n:
        var r = rng.next()
        var kind = Int(r % 8)
        var count = Int((r >> 8) % 1500)
        if kind == 0:
            for _ in range(count):
                out.append(UInt8(rng.next() >> 56))
        elif kind == 1:
            var b = UInt8((r >> 32) & 0xFF)
            for _ in range(count % 400):
                out.append(b)
        else:
            for _ in range(count // 4):
                var w = Int(rng.next() % UInt64(len(words)))
                out.extend(words[w].as_bytes())
    out.resize(n, 0)
    return out^


# ===------------------------------------------------------------------=== #
# Go interop vectors (klauspost/compress v1.18.1 flate, as pinned by
# gophertunnel v1.63.0)
# ===------------------------------------------------------------------=== #


def test_inflate_go_hello() raises:
    # Levels -2..6 store short inputs, then close with an empty fixed block.
    var stored = hex_decode(
        "001900e6ff68656c6c6f2c2068656c6c6f2c2068656c6c6f20776f726c640300"
    )
    assert_equal(String(from_utf8=Span(inflate(Span(stored), 100))), HELLO)
    var huffman = hex_decode("ca48cdc9c9d75140a614caf38b7252000300")
    assert_equal(String(from_utf8=Span(inflate(Span(huffman), 100))), HELLO)


def test_inflate_go_empty() raises:
    var out = inflate(Span(hex_decode("0300")), 0)
    assert_equal(len(out), 0)


def test_inflate_go_paragraph() raises:
    var level1 = hex_decode(
        "94d03152c3400c46e1abfc07d8c901d2c1102aa0492e20efcab1585b325ad98b393d0d"
        "1d55ba577ef36e13e36b935c31b875c568dff8dc96b5c17676c4c498e9e740b1fb09ef"
        "a29c9dc638e3998b5baeb814093145b665756e8d1b78673f3050e4093662a55c391aba"
        "c404a78e97cbebdbd3ed02735c95d6f5008dc18e0f8e6e5eaf1c217a6f273c6003dd49"
        "3481b4fccbf31f21214f9bd604d6903812d6990ef68461b65c132478410bca35417467"
        "0df323a18b16eb0933ef3c2774f3b9241459589b98260c620b9ff0c8c9df0100"
    )
    var level6 = hex_decode(
        "94ce3152eb400c06e0abfc07d8c901d2bd37840a68920bc8bb722c6c4b462b7b594ecf"
        "0c434795ee2bbfdbc4f8d825cf18dc9a62b44fbcefeb5661073b62622cf4d551ec7ec2"
        "ab2867a731cef8cfc52dcfb814093145b67573ae952bf860ef1828f2041bb1519e392a"
        "9ac404a786a7cbf3cbbfdb05e6b82a6d5b078dc18e378e663e5f3942f45e4f78e006ba"
        "93680269f9c3f36f21214fbbce09ac21d113b6853a7bc2b0589e132478450dfab11eac"
        "61de139a68b196b0f0c14b42335f4a429195b58a69c220b6f243dbd3f700"
    )
    var want = _bytes(PARAGRAPH)
    assert_true(_same(Span(inflate(Span(level1), 1000)), Span(want)))
    assert_true(_same(Span(inflate(Span(level6), 1000)), Span(want)))


def test_inflate_go_repeated() raises:
    var enc = hex_decode("4a4c4a4e190eb8a2b28a46083000")
    var want = _repeated()
    assert_true(_same(Span(inflate(Span(enc), 1000)), Span(want)))


# ===------------------------------------------------------------------=== #
# Hand-built streams; Go's flate.NewReader agrees on every verdict.
# ===------------------------------------------------------------------=== #


def test_inflate_crafted_valid() raises:
    # Fixed block: 'a', then length 3 at distance 1.
    assert_equal(
        String(from_utf8=Span(inflate(Span(hex_decode("4b040200")), 10))),
        "aaaa",
    )
    # Dynamic block, code lengths run-length encoded.
    assert_equal(
        String(
            from_utf8=Span(
                inflate(
                    Span(hex_decode("05e1dbb625499224497e2bfcff4f000002")), 10
                )
            )
        ),
        "aaa",
    )
    # A dynamic block with no distance codes at all.
    assert_equal(
        String(
            from_utf8=Span(
                inflate(
                    Span(hex_decode("05e0dbb625499224497e2bfcff4fc012")), 10
                )
            )
        ),
        "a",
    )
    # A single one-bit distance code is accepted, as zlib and Go do.
    assert_equal(
        String(
            from_utf8=Span(
                inflate(
                    Span(hex_decode("05e0dbb625499224497e2bfcff4f0008")), 10
                )
            )
        ),
        "a",
    )


def test_inflate_rejects_malformed() raises:
    var cases: List[String] = [
        "07",  # block type 3
        "0105000000",  # stored NLEN is not ~LEN
        "010500faff6162",  # stored block cut short
        "030200",  # distance 1 with no output yet
        "1b0300",  # fixed literal/length symbol 286
        "4b043e00",  # fixed distance symbol 30
        "f5000000000000",  # HLIT 287
        "051e0000000000",  # HDIST 31
        "0500920400000000",  # over-subscribed code length code
        "05e1dbb625499224495e000000000000000000",  # repeat with no previous
        "05e1dbb62549922449feffffff3f0000000000000000",  # repeat overflows
        "05e1dbb625499224497e2bc0ffff04000000000000000000",  # no EOB code
        "05e1dbb625499224497e2bfcff4f20000000000000000000",  # incomplete code
        "05e1dbb625499224497e2bc0ff7f0400000000000000000000",  # over-subscribed
    ]
    for c in cases:
        with assert_raises():
            _ = inflate(Span(hex_decode(c)), 1 << 20)


def test_inflate_rejects_empty_input() raises:
    with assert_raises(contains="end of stream"):
        _ = inflate(Span(List[UInt8]()), 100)


def test_inflate_rejects_every_truncation() raises:
    var streams = List[List[UInt8]]()
    streams.append(deflate(Span(_bytes(PARAGRAPH)), 6))
    streams.append(deflate(Span(_bytes(PARAGRAPH)), 0))
    streams.append(deflate(Span(_bytes(PARAGRAPH)), HUFFMAN_ONLY))
    streams.append(deflate(Span(_mixed(3000, 7)), 9))
    for ref s in streams:
        for cut in range(len(s)):
            with assert_raises():
                _ = inflate(Span(s)[0:cut], 1 << 20)


def test_inflate_limit() raises:
    var zeros = List[UInt8](length=1 << 20, fill=0)
    var enc = deflate(Span(zeros), 6)
    assert_true(len(enc) < 2048)
    assert_equal(len(inflate(Span(enc), 1 << 20)), 1 << 20)
    with assert_raises(contains="exceeds limit"):
        _ = inflate(Span(enc), (1 << 20) - 1)
    # Stored blocks and literals are limited too.
    var stored = deflate(Span(_bytes(HELLO)), 0)
    assert_equal(len(inflate(Span(stored), 25)), 25)
    with assert_raises(contains="exceeds limit"):
        _ = inflate(Span(stored), 24)
    var huff = deflate(Span(_bytes(HELLO)), HUFFMAN_ONLY)
    with assert_raises(contains="exceeds limit"):
        _ = inflate(Span(huff), 24)
    # A negative limit behaves as 0.
    assert_equal(len(inflate(Span(hex_decode("0300")), -5)), 0)
    with assert_raises(contains="exceeds limit"):
        _ = inflate(Span(huff), -1)


def test_default_max_decompressed_len() raises:
    assert_equal(DEFAULT_MAX_DECOMPRESSED_LEN, 16 * 1024 * 1024)


def test_inflate_ignores_trailing_bytes() raises:
    var enc = hex_decode("4b040200ffffff")
    assert_equal(String(from_utf8=Span(inflate(Span(enc), 10))), "aaaa")


def test_inflate_corrupted_streams_raise_or_decode() raises:
    # Random damage must never abort; with ASSERT=all an out-of-bounds
    # access would.
    var base = deflate(Span(_mixed(5000, 11)), 6)
    var rng = _Rng(99)
    var rejected = 0
    for _ in range(3000):
        var s = base.copy()
        for _ in range(1 + Int(rng.next() % 3)):
            var i = Int(rng.next() % UInt64(len(s)))
            s[i] ^= UInt8(1 << Int(rng.next() % 8))
        try:
            _ = inflate(Span(s), 1 << 16)
        except:
            rejected += 1
    assert_true(rejected > 1000)
    for _ in range(2000):
        var junk = List[UInt8]()
        for _ in range(Int(rng.next() % 64)):
            junk.append(UInt8(rng.next() >> 56))
        try:
            _ = inflate(Span(junk), 1 << 16)
        except:
            pass


# ===------------------------------------------------------------------=== #
# Encoder. Every stream pinned here was decoded by Go's flate.NewReader.
# ===------------------------------------------------------------------=== #


def test_deflate_empty() raises:
    var empty = List[UInt8]()
    assert_equal(hex_encode(Span(deflate(Span(empty), 0))), "010000ffff")
    for level in range(HUFFMAN_ONLY, BEST_COMPRESSION + 1):
        if level == NO_COMPRESSION:
            continue
        var enc = deflate(Span(empty), level)
        assert_equal(hex_encode(Span(enc)), "0300")
        assert_equal(len(inflate(Span(enc), 0)), 0)


def test_deflate_hello_bytes() raises:
    var data = _bytes(HELLO)
    assert_equal(
        hex_encode(Span(deflate(Span(data), 6))),
        "cb48cdc9c9d75140a614caf38b725200",
    )
    assert_equal(
        hex_encode(Span(deflate(Span(data), 0))),
        "011900e6ff68656c6c6f2c2068656c6c6f2c2068656c6c6f20776f726c64",
    )


def test_deflate_levels_clamp() raises:
    var data = _mixed(20000, 5)
    assert_true(
        _same(
            Span(deflate(Span(data), DEFAULT_COMPRESSION)),
            Span(deflate(Span(data), 6)),
        )
    )
    assert_true(
        _same(Span(deflate(Span(data), 42)), Span(deflate(Span(data), 9)))
    )
    assert_true(
        _same(
            Span(deflate(Span(data), -7)),
            Span(deflate(Span(data), HUFFMAN_ONLY)),
        )
    )


def test_deflate_stored_large() raises:
    # Level 0 splits into 65535-byte stored blocks: 5 bytes of overhead each.
    var data = _mixed(200000, 3)
    var enc = deflate(Span(data), NO_COMPRESSION)
    assert_equal(len(enc), 200000 + 4 * 5)
    assert_true(_same(Span(inflate(Span(enc), 200000)), Span(data)))


def test_deflate_ratio_ordering() raises:
    var data = _mixed(100000, 13)
    var l1 = len(deflate(Span(data), 1))
    var l6 = len(deflate(Span(data), 6))
    var l9 = len(deflate(Span(data), 9))
    var huff = len(deflate(Span(data), HUFFMAN_ONLY))
    assert_true(l9 <= l6 and l6 <= l1 and l1 < huff and huff < len(data))


def test_deflate_incompressible_falls_back_to_stored() raises:
    var rng = _Rng(1234)
    var data = List[UInt8]()
    for _ in range(4096):
        data.append(UInt8(rng.next() >> 56))
    var enc = deflate(Span(data), 6)
    assert_equal(len(enc), 4096 + 5)
    assert_true(_same(Span(inflate(Span(enc), 4096)), Span(data)))


def test_round_trip_small_sizes() raises:
    var src = _mixed(600, 21)
    var levels: List[Int] = [HUFFMAN_ONLY, 0, 1, 3, 4, 6, 9]
    for n in range(0, 600, 7):
        var data = List[UInt8](Span(src)[0:n])
        for level in levels:
            var enc = deflate(Span(data), level)
            assert_true(_same(Span(inflate(Span(enc), n)), Span(data)))


def test_round_trip_runs() raises:
    # Long runs exercise distance-1 copies and 258-byte matches.
    var data = List[UInt8]()
    for i in range(300):
        for _ in range(i % 17 + 1):
            data.append(UInt8(i % 3))
    for _ in range(70000):
        data.append(7)
    for level in range(1, 10):
        var enc = deflate(Span(data), level)
        assert_true(len(enc) < len(data) // 20)
        assert_true(_same(Span(inflate(Span(enc), len(data))), Span(data)))


def test_round_trip_1mib_all_levels() raises:
    var data = _mixed(1 << 20, 42)
    for level in range(HUFFMAN_ONLY, BEST_COMPRESSION + 1):
        var enc = deflate(Span(data), level)
        var out = inflate(Span(enc), DEFAULT_MAX_DECOMPRESSED_LEN)
        assert_true(_same(Span(out), Span(data)))
        if level != NO_COMPRESSION:
            assert_true(len(enc) < len(data))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
