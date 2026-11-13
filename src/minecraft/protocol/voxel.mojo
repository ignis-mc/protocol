"""Voxel shapes (gophertunnel `protocol/voxel.go`)."""

from .entities_helpers import func_slice
from .io import IO, Marshaler


struct VoxelCells(Marshaler):
    """A 3D grid of voxel cells."""

    var x_size: UInt8
    """The size of the grid along X."""
    var y_size: UInt8
    """The size of the grid along Y."""
    var z_size: UInt8
    """The size of the grid along Z."""
    var storage: List[UInt8]
    """The raw cell data."""

    def __init__(out self):
        """Creates an empty grid."""
        self.x_size = 0
        self.y_size = 0
        self.z_size = 0
        self.storage = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the grid.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.x_size)
        io.uint8(self.y_size)
        io.uint8(self.z_size)
        func_slice[I.uint8](io, self.storage)


struct VoxelShapeNameEntry(Marshaler):
    """Maps a voxel shape name to its numeric ID."""

    var name: String
    """The name of the shape."""
    var id: UInt16
    """The numeric ID of the shape."""

    def __init__(out self):
        """Creates an empty entry."""
        self.name = String()
        self.id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        io.uint16(self.id)


struct VoxelShape(Marshaler):
    """A voxel shape: a cell grid and its coordinate axes."""

    var cells: VoxelCells
    """The grid of solid and empty cells."""
    var x_coordinates: List[Float32]
    """The X axis coordinates."""
    var y_coordinates: List[Float32]
    """The Y axis coordinates."""
    var z_coordinates: List[Float32]
    """The Z axis coordinates."""

    def __init__(out self):
        """Creates an empty shape."""
        self.cells = VoxelCells()
        self.x_coordinates = List[Float32]()
        self.y_coordinates = List[Float32]()
        self.z_coordinates = List[Float32]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.cells.marshal(io)
        func_slice[I.float32](io, self.x_coordinates)
        func_slice[I.float32](io, self.y_coordinates)
        func_slice[I.float32](io, self.z_coordinates)
