"""The `ResourcePackChunkRequest` packet (gophertunnel `packet/resource_pack_chunk_request.go`).
"""

from ..io import IO
from .id import ID_RESOURCE_PACK_CHUNK_REQUEST
from .packet import Packet


struct ResourcePackChunkRequest(Packet):
    """Sent by the client to request one chunk of a resource pack."""

    comptime ID: UInt32 = ID_RESOURCE_PACK_CHUNK_REQUEST
    """The packet ID."""
    var uuid: String
    """The unique ID of the resource pack."""
    var chunk_index: Int32
    """The index of the requested chunk, starting at 0."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.uuid = String()
        self.chunk_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.uuid)
        io.int32(self.chunk_index)
