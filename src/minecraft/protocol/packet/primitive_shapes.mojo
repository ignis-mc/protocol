"""The `PrimitiveShapes` packet (gophertunnel `packet/primitive_shapes.go`)."""

from ..io import IO, slice
from ..shape import PrimitiveShape
from .id import ID_PRIMITIVE_SHAPES
from .packet import Packet


struct PrimitiveShapes(Packet):
    """Sent by the server to add, update or remove shapes drawn in the world."""

    comptime ID: UInt32 = ID_PRIMITIVE_SHAPES
    """The packet ID."""
    var shapes: List[PrimitiveShape]
    """The shapes to draw."""

    def __init__(out self):
        """Creates the packet with no shapes."""
        self.shapes = List[PrimitiveShape]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.shapes)
