from minecraft.protocol.blob_cache import CacheBlob
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
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


def test_cache_blob() raises:
    var b = CacheBlob()
    b.hash = 0x0102030405060708
    b.payload = [0xAA, 0xBB]
    assert_equal(_hex(b), "0807060504030201" + "02aabb")
    var back = _read[CacheBlob]("080706050403020102aabb")
    assert_equal(back.hash, 0x0102030405060708)
    assert_equal(back.payload[1], 0xBB)
    with assert_raises():
        _ = _read[CacheBlob]("080706050403020103aabb")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
