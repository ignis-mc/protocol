from minecraft.protocol.packet.compression import (
    COMPRESSION_ALGORITHM_FLATE,
    COMPRESSION_ALGORITHM_NONE,
    COMPRESSION_ALGORITHM_SNAPPY,
)
from minecraft.protocol.packet.decoder import MAXIMUM_IN_BATCH, Decoder
from minecraft.protocol.packet.encoder import Encoder
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_uncompressed_framing() raises:
    var enc = Encoder()
    var packets: List[List[UInt8]] = [[0xC1, 0x01, 0, 0, 8, 0xB1], [9]]
    var batch = enc.encode(packets)
    assert_equal(hex_encode(Span(batch)), "06c101000008b10109")
    var back = Decoder().decode(Span(batch))
    assert_equal(len(back), 2)
    assert_equal(hex_encode(Span(back[0])), "c101000008b1")
    assert_equal(hex_encode(Span(back[1])), "09")


def test_below_threshold_uses_none_marker() raises:
    var enc = Encoder()
    enc.enable_compression(COMPRESSION_ALGORITHM_FLATE, 256)
    var packets: List[List[UInt8]] = [[9, 1, 2]]
    var batch = enc.encode(packets)
    assert_equal(hex_encode(Span(batch)), "ff03090102")
    var dec = Decoder()
    dec.enable_compression(COMPRESSION_ALGORITHM_FLATE)
    assert_equal(hex_encode(Span(dec.decode(Span(batch))[0])), "090102")


def test_decoder_rejections() raises:
    var dec = Decoder()
    dec.enable_compression(COMPRESSION_ALGORITHM_FLATE)
    with assert_raises(contains="unexpected compression algorithm"):
        _ = dec.decode(Span(hex_decode("01aabb")))
    with assert_raises(contains="empty packet"):
        _ = dec.decode(Span(hex_decode("ff00")))
    with assert_raises(contains="exceeds remaining"):
        _ = dec.decode(Span(hex_decode("ff0501")))
    with assert_raises(contains="did not terminate"):
        _ = dec.decode(Span(hex_decode("ffffffffffff01")))
    with assert_raises(contains="unexpected end"):
        _ = dec.decode(Span(hex_decode("ff80")))
    var many = List[UInt8]()
    many.append(0xFF)
    for _ in range(MAXIMUM_IN_BATCH + 1):
        many.append(1)
        many.append(9)
    with assert_raises(contains="exceeds max"):
        _ = dec.decode(Span(many))
    var small = Decoder()
    small.enable_compression(COMPRESSION_ALGORITHM_NONE, 2)
    with assert_raises(contains="exceeds limit"):
        _ = small.decode(Span(hex_decode("ff020901")))


def _round_trip(algorithm: UInt16) raises:
    var enc = Encoder()
    enc.enable_compression(algorithm, 256)
    var big = List[UInt8]()
    for i in range(5000):
        big.append(UInt8(i % 7))
    var packets: List[List[UInt8]] = [big.copy(), [9, 1]]
    var batch = enc.encode(packets)
    assert_equal(Int(batch[0]), Int(algorithm))
    assert_true(len(batch) < 1000)
    var dec = Decoder()
    dec.enable_compression(algorithm)
    var back = dec.decode(Span(batch))
    assert_equal(len(back), 2)
    assert_equal(len(back[0]), 5000)
    assert_equal(hex_encode(Span(back[1])), "0901")


def test_flate_and_snappy_batches_round_trip() raises:
    _round_trip(COMPRESSION_ALGORITHM_FLATE)
    _round_trip(COMPRESSION_ALGORITHM_SNAPPY)


def test_go_flate_batch_decodes() raises:
    # klauspost flate level 6 of the body 03 09 01 02 (one packet 09 01 02).
    var dec = Decoder()
    dec.enable_compression(COMPRESSION_ALGORITHM_FLATE)
    var batch = hex_decode("00" + "000400fbff030901020300")
    var back = dec.decode(Span(batch))
    assert_equal(hex_encode(Span(back[0])), "090102")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
