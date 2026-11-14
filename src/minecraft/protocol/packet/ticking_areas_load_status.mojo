"""The `TickingAreasLoadStatus` packet.

This is gophertunnel `packet/ticking_areas_load_status.go`.
"""

from ..io import IO
from .id import ID_TICKING_AREAS_LOAD_STATUS
from .packet import Packet


struct TickingAreasLoadStatus(Packet):
    """Sent by the server with the loading status of ticking areas."""

    comptime ID: UInt32 = ID_TICKING_AREAS_LOAD_STATUS
    """The packet ID."""
    var preload: Bool
    """Whether ticking areas are still preloading."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.preload = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.bool(self.preload)
