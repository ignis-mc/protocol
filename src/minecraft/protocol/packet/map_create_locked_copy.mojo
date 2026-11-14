"""The `MapCreateLockedCopy` packet (gophertunnel `packet/map_create_locked_copy.go`).
"""

from ..io import IO
from .id import ID_MAP_CREATE_LOCKED_COPY
from .packet import Packet


struct MapCreateLockedCopy(Packet):
    """Sent by the client to create a locked copy of one map into another.

    In vanilla, the cartography table uses it to create a map that cannot be
    modified.
    """

    comptime ID: UInt32 = ID_MAP_CREATE_LOCKED_COPY
    """The packet ID."""
    var original_map_id: Int64
    """The ID of the map being copied."""
    var new_map_id: Int64
    """The ID of the map that holds the locked copy."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.original_map_id = 0
        self.new_map_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint64(self.original_map_id)
        io.varint64(self.new_map_id)
