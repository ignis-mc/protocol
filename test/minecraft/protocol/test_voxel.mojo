from minecraft.protocol.reader import Reader
from minecraft.protocol.voxel import VoxelCells, VoxelShape, VoxelShapeNameEntry
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises

comptime _SHAPE = "01020102010002000000000000803f03000000000000003f0000803f00"


def test_voxel_shape_matches_gophertunnel() raises:
    var s = VoxelShape()
    s.cells.x_size = 1
    s.cells.y_size = 2
    s.cells.z_size = 1
    s.cells.storage = [1, 0]
    s.x_coordinates = [0, 1]
    s.y_coordinates = [0, 0.5, 1]
    var w = Writer()
    s.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _SHAPE)
    var raw = hex_decode(_SHAPE)
    var r = Reader(Span(raw))
    var back = VoxelShape()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(len(back.y_coordinates), 3)
    assert_equal(back.cells.storage[0], 1)


def test_voxel_name_entry_matches_gophertunnel() raises:
    var e = VoxelShapeNameEntry()
    e.name = "minecraft:full"
    e.id = 513
    var w = Writer()
    e.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), "0e6d696e6563726166743a66756c6c0102")


def test_overlong_storage_is_rejected() raises:
    var raw = hex_decode("010101" + "05" + "0102")
    var r = Reader(Span(raw))
    var c = VoxelCells()
    with assert_raises(contains="slice length"):
        c.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
