"""The `DimensionData` packet (gophertunnel `packet/dimension_data.go`)."""

from ..io import IO, slice
from ..world import DimensionDefinition
from .id import ID_DIMENSION_DATA
from .packet import Packet


struct DimensionData(Packet):
    """A packet sent from the server to the client containing information about
    data-driven dimensions that the server may have registered.
    """

    comptime ID: UInt32 = ID_DIMENSION_DATA
    """The packet ID."""
    var definitions: List[DimensionDefinition]
    """The data-driven dimension definitions registered on the server."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.definitions = List[DimensionDefinition]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.definitions)
