"""The `TrimData` packet (gophertunnel `packet/trim_data.go`)."""

from ..io import IO, slice
from ..trim import TrimMaterial, TrimPattern
from .id import ID_TRIM_DATA
from .packet import Packet


struct TrimData(Packet):
    """Sent by the server with every armour trim pattern and material."""

    comptime ID: UInt32 = ID_TRIM_DATA
    """The packet ID."""
    var patterns: List[TrimPattern]
    """The trim patterns."""
    var materials: List[TrimMaterial]
    """The trim materials."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.patterns = List[TrimPattern]()
        self.materials = List[TrimMaterial]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.patterns)
        slice(io, self.materials)
