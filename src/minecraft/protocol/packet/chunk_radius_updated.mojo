"""The `ChunkRadiusUpdated` packet (gophertunnel `packet/chunk_radius_updated.go`)."""

from ..io import IO
from .id import ID_CHUNK_RADIUS_UPDATED
from .packet import Packet


struct ChunkRadiusUpdated(Packet):
    """Sent by the server with the view distance it allows."""

    comptime ID: UInt32 = ID_CHUNK_RADIUS_UPDATED
    """The packet ID."""
    var chunk_radius: Int32
    """The radius, in chunks."""

    def __init__(out self):
        """Creates the packet with radius 0."""
        self.chunk_radius = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.chunk_radius)
