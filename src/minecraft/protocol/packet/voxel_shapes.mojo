"""The `VoxelShapes` packet (gophertunnel `packet/voxel_shapes.go`)."""

from ..io import IO, slice
from ..voxel import VoxelShape, VoxelShapeNameEntry
from .id import ID_VOXEL_SHAPES
from .packet import Packet


struct VoxelShapes(Packet):
    """Sent by the server with voxel shape data."""

    comptime ID: UInt32 = ID_VOXEL_SHAPES
    """The packet ID."""
    var shapes: List[VoxelShape]
    """The shapes."""
    var name_map: List[VoxelShapeNameEntry]
    """Shape names and their IDs."""
    var custom_shape_count: UInt16
    """The number of custom shapes."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.shapes = List[VoxelShape]()
        self.name_map = List[VoxelShapeNameEntry]()
        self.custom_shape_count = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.shapes)
        slice(io, self.name_map)
        io.uint16(self.custom_shape_count)
