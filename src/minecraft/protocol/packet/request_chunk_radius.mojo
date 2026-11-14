"""The `RequestChunkRadius` packet (gophertunnel `packet/request_chunk_radius.go`)."""

from ..io import IO
from .id import ID_REQUEST_CHUNK_RADIUS
from .packet import Packet


struct RequestChunkRadius(Packet):
    """Sent by the client to ask for a view distance."""

    comptime ID: UInt32 = ID_REQUEST_CHUNK_RADIUS
    """The packet ID."""
    var chunk_radius: Int32
    """The requested radius, in chunks."""
    var max_chunk_radius: UInt8
    """The largest radius the client supports."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.chunk_radius = 0
        self.max_chunk_radius = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.chunk_radius)
        io.uint8(self.max_chunk_radius)
