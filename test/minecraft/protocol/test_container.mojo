# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.container import (
    CONTAINER_DYNAMIC,
    CONTAINER_HOT_BAR,
    CONTAINER_TYPE_CRAFTER,
    CONTAINER_TYPE_INVENTORY,
    FullContainerName,
)
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _encode[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _decode[T: Marshaler](hex: StringSpan) raises -> T:
    var data = hex_decode(hex)
    var r = Reader(Span(data))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(_encode(x), String(hex))
    return x^


def test_constants() raises:
    assert_equal(CONTAINER_DYNAMIC, 63)
    assert_equal(CONTAINER_HOT_BAR, 28)
    # ContainerTypeInventory is -1 in gophertunnel; the field is a byte.
    assert_equal(CONTAINER_TYPE_INVENTORY, 255)
    assert_equal(CONTAINER_TYPE_CRAFTER, 36)


def test_full_container_name() raises:
    var dynamic = FullContainerName(CONTAINER_DYNAMIC, UInt32(0x01020304))
    assert_equal(_encode(dynamic), "3f0104030201")
    var back = _decode[FullContainerName]("3f0104030201")
    assert_equal(back.dynamic_container_id.value(), 0x01020304)
    var plain = FullContainerName(CONTAINER_HOT_BAR, None)
    assert_equal(_encode(plain), "1c00")
    assert_true(_decode[FullContainerName]("1c00").dynamic_container_id is None)


def test_truncated_input_is_rejected() raises:
    with assert_raises():
        _ = _decode[FullContainerName]("3f01040302")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
