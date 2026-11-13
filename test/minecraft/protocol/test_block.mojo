from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from minecraft.protocol.block import BlockChangeEntry, BlockEntry
from minecraft.protocol.block_pos import BlockPos
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


def test_block_change_entry() raises:
    var b = BlockChangeEntry()
    b.block_pos = BlockPos(1, -2, 3)
    b.block_runtime_id = 300
    b.flags = 3
    b.synced_update_entity_unique_id = 5
    b.synced_update_type = 1
    assert_equal(_hex(b), "020306ac02030501")
    var back = _read[BlockChangeEntry]("020306ac02030501")
    assert_true(back.block_pos == BlockPos(1, -2, 3))
    assert_equal(back.block_runtime_id, 300)


def test_block_entry_nbt() raises:
    var b = _read[BlockEntry]("03783a790a000301610200")
    assert_equal(b.name, "x:y")
    assert_equal(b.properties.encoding, NETWORK_LITTLE_ENDIAN)
    assert_equal(_hex(b), "03783a790a000301610200")
    # A compound whose int value is cut off.
    with assert_raises():
        _ = _read[BlockEntry]("03783a790a0003016102")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
