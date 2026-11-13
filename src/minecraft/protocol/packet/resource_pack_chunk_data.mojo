"""The `ResourcePackChunkData` packet (gophertunnel `packet/resource_pack_chunk_data.go`).
"""

from ..io import IO
from .id import ID_RESOURCE_PACK_CHUNK_DATA
from .packet import Packet


struct ResourcePackChunkData(Packet):
    """Sent by the server with one chunk of a compressed resource pack."""

    comptime ID: UInt32 = ID_RESOURCE_PACK_CHUNK_DATA
    """The packet ID."""
    var uuid: String
    """The unique ID of the resource pack."""
    var chunk_index: UInt32
    """The index of the chunk, starting at 0."""
    var data_offset: UInt64
    """The byte offset of the chunk in the pack."""
    var data: List[UInt8]
    """The chunk; at most `ResourcePackDataInfo.data_chunk_size` bytes."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.uuid = String()
        self.chunk_index = 0
        self.data_offset = 0
        self.data = List[UInt8]()

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
        io.uint32(self.chunk_index)
        io.uint64(self.data_offset)
        io.byte_slice(self.data)
