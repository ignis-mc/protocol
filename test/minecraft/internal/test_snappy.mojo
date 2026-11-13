from minecraft.internal.flate import DEFAULT_MAX_DECOMPRESSED_LEN
from minecraft.internal.snappy import (
    snappy_decode,
    snappy_decoded_len,
    snappy_encode,
    snappy_max_encoded_len,
)
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime HELLO = "hello, hello, hello world"
comptime PARAGRAPH = (
    "The quick brown fox jumps over the lazy dog. Minecraft: Bedrock Edition"
    " compresses every batch of packets with raw DEFLATE or Snappy after"
    " NetworkSettings. The quick brown fox jumps over the lazy dog again, and"
    " again, and again: packet, chunk, entity, player, block, item stack,"
    " inventory, window, level, world, dimension, biome. The quick brown fox"
    " jumps over the lazy dog."
)

# Encodings from github.com/golang/snappy v1.0.0 `Encode`.
comptime GOLANG_EMPTY = "00"
comptime GOLANG_HELLO = "191868656c6c6f2c202e07001420776f726c64"
comptime GOLANG_PARAGRAPH = (
    "f602f09f54686520717569636b2062726f776e20666f78206a756d7073206f7665722074"
    "6865206c617a7920646f672e204d696e6563726166743a20426564726f636b2045646974"
    "696f6e20636f6d70726573736573206576657279206261746368206f66207061636b6574"
    "73207769746820726177204445464c415445206f7220536e61707079206166746572204e"
    "6574776f726b53657474696e67732e20546865209a9c002820616761696e2c20616e6442"
    "0b00043a200983a02c206368756e6b2c20656e746974792c20706c617965722c20626c6f"
    "636b2c206974656d2073746163010cc06e76656e746f72792c2077696e646f772c206c65"
    "76656c2c20776f726c642c2064696d656e73696f6e2c2062696f6d652eaeae00002e"
)
comptime GOLANG_REPEATED = (
    "a2020c61626364fe0400fe0400fe040001040878797afe03005a0300"
)

# Encodings from klauspost/compress v1.18.1 `s2.EncodeSnappy`, which
# gophertunnel uses to compress.
comptime S2_HELLO = "196068656c6c6f2c2068656c6c6f2c2068656c6c6f20776f726c64"
comptime S2_PARAGRAPH = (
    "f602f09b54686520717569636b2062726f776e20666f78206a756d7073206f7665722074"
    "6865206c617a7920646f672e204d696e6563726166743a20426564726f636b2045646974"
    "696f6e20636f6d70726573736573206576657279206261746368206f66207061636b6574"
    "73207769746820726177204445464c415445206f7220536e61707079206166746572204e"
    "6574776f726b53657474696e67732e20aa9c002820616761696e2c20616e64420b00003a"
    "0d839c2c206368756e6b2c20656e746974792c20706c617965722c20626c6f636b2c2069"
    "74656d20737461050cc46e76656e746f72792c2077696e646f772c206c6576656c2c2077"
    "6f726c642c2064696d656e73696f6e2c2062696f6d652e20ae4a01"
)
comptime S2_REPEATED = (
    "a2020c61626364ee0400ee0400ee04003e04000878797aee03006a0300"
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


def _mixed(n: Int, seed: UInt64) -> List[UInt8]:
    # xorshift64*: words, random bytes and runs.
    var words: List[String] = ["packet ", "chunk ", "entity ", "block ", ".\n"]
    var s = seed
    var out = List[UInt8](capacity=n + 4096)
    while len(out) < n:
        s ^= s >> 12
        s ^= s << 25
        s ^= s >> 27
        var r = s * 0x2545F4914F6CDD1D
        var kind = Int(r % 4)
        var count = Int((r >> 8) % 1500)
        if kind == 0:
            for i in range(count):
                out.append(UInt8(((r >> 16) * UInt64(i + 1)) >> 13 & 0xFF))
        elif kind == 1:
            for _ in range(count % 400):
                out.append(UInt8((r >> 32) & 0xFF))
        else:
            for i in range(count // 4):
                out.extend(
                    words[(Int(r >> 20) + i * 7) % len(words)].as_bytes()
                )
    out.resize(n, 0)
    return out^


def test_encode_matches_golang_snappy() raises:
    assert_equal(
        hex_encode(Span(snappy_encode(Span(List[UInt8]())))), GOLANG_EMPTY
    )
    assert_equal(
        hex_encode(Span(snappy_encode(Span(_bytes(HELLO))))), GOLANG_HELLO
    )
    assert_equal(
        hex_encode(Span(snappy_encode(Span(_bytes(PARAGRAPH))))),
        GOLANG_PARAGRAPH,
    )
    assert_equal(
        hex_encode(Span(snappy_encode(Span(_repeated())))), GOLANG_REPEATED
    )


def test_decode_golang_snappy() raises:
    assert_equal(len(snappy_decode(Span(hex_decode(GOLANG_EMPTY)), 0)), 0)
    assert_equal(
        String(
            from_utf8=Span(snappy_decode(Span(hex_decode(GOLANG_HELLO)), 100))
        ),
        HELLO,
    )
    assert_true(
        _same(
            Span(snappy_decode(Span(hex_decode(GOLANG_PARAGRAPH)), 1000)),
            Span(_bytes(PARAGRAPH)),
        )
    )
    assert_true(
        _same(
            Span(snappy_decode(Span(hex_decode(GOLANG_REPEATED)), 1000)),
            Span(_repeated()),
        )
    )


def test_decode_s2_encode_snappy() raises:
    assert_equal(
        String(from_utf8=Span(snappy_decode(Span(hex_decode(S2_HELLO)), 100))),
        HELLO,
    )
    assert_true(
        _same(
            Span(snappy_decode(Span(hex_decode(S2_PARAGRAPH)), 1000)),
            Span(_bytes(PARAGRAPH)),
        )
    )
    assert_true(
        _same(
            Span(snappy_decode(Span(hex_decode(S2_REPEATED)), 1000)),
            Span(_repeated()),
        )
    )


def test_decoded_len() raises:
    assert_equal(snappy_decoded_len(Span(hex_decode("f602"))), 374)
    assert_equal(snappy_decoded_len(Span(hex_decode("ffffffff0f"))), 0xFFFFFFFF)
    with assert_raises():
        _ = snappy_decoded_len(Span(List[UInt8]()))
    with assert_raises():
        _ = snappy_decoded_len(Span(hex_decode("8080808010")))  # 1 << 32
    with assert_raises():
        _ = snappy_decoded_len(Span(hex_decode("ffffffffffffffffffff01")))
    with assert_raises():
        _ = snappy_decoded_len(Span(hex_decode("80")))


def test_decode_limit_checked_before_decoding() raises:
    with assert_raises(contains="exceeds limit"):
        _ = snappy_decode(
            Span(hex_decode("ffffffff0f")), DEFAULT_MAX_DECOMPRESSED_LEN
        )
    var enc = hex_decode(GOLANG_HELLO)
    assert_equal(len(snappy_decode(Span(enc), 25)), 25)
    with assert_raises(contains="exceeds limit"):
        _ = snappy_decode(Span(enc), 24)


def test_decode_valid_copy() raises:
    # 'a', then a copy-1 of length 4 at offset 1.
    assert_equal(
        String(
            from_utf8=Span(snappy_decode(Span(hex_decode("0500610101")), 5))
        ),
        "aaaaa",
    )


def test_decode_rejects_malformed() raises:
    # golang/snappy and s2 both report "corrupt input" for each of these.
    var cases: List[String] = [
        "",  # no length
        "0508616263",  # decodes to 3 bytes, header says 5
        "0500610100",  # copy offset 0
        "0500610102",  # copy offset past the output
        "051061",  # literal longer than the input
        "0200610101",  # copy past the declared length
        "05006102",  # copy-2 cut short
        "0500610301",  # copy-4 cut short
        "05f0",  # literal length byte missing
        "ffffffffffffffffffff01",  # varint overflow
        "8080808010",  # length above 0xFFFFFFFF
        "0500610400",  # 2-byte literal with 1 byte left
        "06006105000000",  # copy-1 offset 0x305 after one byte
        "0400610c",  # 4-byte literal with nothing left
    ]
    for c in cases:
        with assert_raises():
            _ = snappy_decode(Span(hex_decode(c)), 1 << 20)


def test_corrupted_blocks_raise_or_decode() raises:
    var base = snappy_encode(Span(_mixed(5000, 3)))
    var s = UInt64(77)
    for _ in range(3000):
        var b = base.copy()
        for _ in range(3):
            s ^= s >> 12
            s ^= s << 25
            s ^= s >> 27
            var r = s * 0x2545F4914F6CDD1D
            b[Int(r % UInt64(len(b)))] ^= UInt8(1 << Int((r >> 40) % 8))
        try:
            _ = snappy_decode(Span(b), 1 << 16)
        except:
            pass


def test_round_trip_small_sizes() raises:
    var src = _mixed(400, 5)
    for n in range(400):
        var data = List[UInt8](Span(src)[0:n])
        var enc = snappy_encode(Span(data))
        assert_true(len(enc) <= snappy_max_encoded_len(n))
        assert_true(_same(Span(snappy_decode(Span(enc), n)), Span(data)))


def test_round_trip_1mib() raises:
    # More than one 64 KiB block, with matches up to the block edge.
    var data = _mixed(1 << 20, 9)
    var enc = snappy_encode(Span(data))
    assert_true(len(enc) < len(data))
    var out = snappy_decode(Span(enc), DEFAULT_MAX_DECOMPRESSED_LEN)
    assert_true(_same(Span(out), Span(data)))
    var zeros = List[UInt8](length=300000, fill=0)
    var zenc = snappy_encode(Span(zeros))
    assert_true(len(zenc) < 20000)
    assert_true(_same(Span(snappy_decode(Span(zenc), 300000)), Span(zeros)))


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
