from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.sub_chunk import (
    HEIGHT_MAP_DATA_HAS_DATA,
    HEIGHT_MAP_DATA_NONE,
    HEIGHT_MAP_DATA_TOO_HIGH,
    SUB_CHUNK_RESULT_SUCCESS,
    SUB_CHUNK_RESULT_SUCCESS_ALL_AIR,
    HeightMap,
    SubChunkEntry,
    SubChunkOffset,
)
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def test_sub_chunk_entry_without_height_maps() raises:
    var e = SubChunkEntry()
    e.offset = SubChunkOffset(1, -1, 0)
    e.result = SUB_CHUNK_RESULT_SUCCESS
    var payload: List[UInt8] = [0xDE, 0xAD]
    e.raw_payload = payload^
    e.height_map_type = HEIGHT_MAP_DATA_TOO_HIGH
    e.render_height_map_type = HEIGHT_MAP_DATA_NONE
    var expected = "01ff00010102dead0200000000"
    assert_equal(_hex(e), expected)
    var back = _read[SubChunkEntry](expected)
    assert_true(back.offset == SubChunkOffset(1, -1, 0))
    assert_equal(back.raw_payload.value()[1], 0xAD)
    assert_true(back.height_map_data is None)
    assert_true(back.blob_hash is None)
    assert_equal(_hex(back), expected)


def test_sub_chunk_entry_with_height_maps() raises:
    var hm = HeightMap()
    var rhm = HeightMap()
    for z in range(16):
        for x in range(16):
            hm[z, x] = Int8(z * 16 + x)
            rhm[z, x] = Int8(-x)
    var e = SubChunkEntry()
    e.offset = SubChunkOffset(0, 2, -3)
    e.result = SUB_CHUNK_RESULT_SUCCESS_ALL_AIR
    e.height_map_type = HEIGHT_MAP_DATA_HAS_DATA
    e.height_map_data = hm^
    e.render_height_map_type = HEIGHT_MAP_DATA_HAS_DATA
    e.render_height_map_data = rhm^
    e.blob_hash = UInt64(0x0102030405060708)
    var expected = (
        "0002fd0600010110000102030405060708090a0b0c0d0e0f1010111213141516"
        "1718191a1b1c1d1e1f10202122232425262728292a2b2c2d2e2f103031323334"
        "35363738393a3b3c3d3e3f10404142434445464748494a4b4c4d4e4f10505152"
        "535455565758595a5b5c5d5e5f10606162636465666768696a6b6c6d6e6f1070"
        "7172737475767778797a7b7c7d7e7f10808182838485868788898a8b8c8d8e8f"
        "10909192939495969798999a9b9c9d9e9f10a0a1a2a3a4a5a6a7a8a9aaabacad"
        "aeaf10b0b1b2b3b4b5b6b7b8b9babbbcbdbebf10c0c1c2c3c4c5c6c7c8c9cacb"
        "cccdcecf10d0d1d2d3d4d5d6d7d8d9dadbdcdddedf10e0e1e2e3e4e5e6e7e8e9"
        "eaebecedeeef10f0f1f2f3f4f5f6f7f8f9fafbfcfdfeff01011000fffefdfcfb"
        "faf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefd"
        "fcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f11000ff"
        "fefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f110"
        "00fffefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2"
        "f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4"
        "f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6"
        "f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfaf9f8"
        "f7f6f5f4f3f2f11000fffefdfcfbfaf9f8f7f6f5f4f3f2f11000fffefdfcfbfa"
        "f9f8f7f6f5f4f3f2f1010807060504030201"
    )
    assert_equal(_hex(e), expected)
    var back = _read[SubChunkEntry](expected)
    assert_equal(back.height_map_data.value()[15, 15], -1)
    assert_equal(back.height_map_data.value()[2, 3], 35)
    assert_equal(back.render_height_map_data.value()[7, 9], -9)
    assert_equal(back.blob_hash.value(), 0x0102030405060708)
    assert_equal(_hex(back), expected)


def test_height_map_rejects_short_rows() raises:
    # A row claiming 15 heights.
    with assert_raises(contains="must hold 16 heights"):
        _ = _read[HeightMap]("0f" + "00" * 15)
    with assert_raises():
        _ = _read[HeightMap]("10" + "00" * 15)
    var wrong = HeightMap()
    wrong.heights = [1, 2, 3]
    with assert_raises(contains="must hold 256 heights"):
        _ = _hex(wrong)


def test_sub_chunk_entry_rejects_truncated_input() raises:
    with assert_raises():
        _ = _read[SubChunkEntry]("0102")
    # Payload length 5 with only 2 bytes left.
    with assert_raises():
        _ = _read[SubChunkEntry]("000000010105dead")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
