"""The `NetworkChunkPublisherUpdate` packet (gophertunnel `packet/network_chunk_publisher_update.go`).
"""

from ..block_pos import BlockPos, ChunkPos
from ..io import IO, block_pos, chunk_pos, func_slice_of_len, invalid_value
from .id import ID_NETWORK_CHUNK_PUBLISHER_UPDATE
from .packet import Packet

comptime _MAX_SAVED_CHUNKS: UInt32 = 9216


struct NetworkChunkPublisherUpdate(Packet):
    """Sent by the server to set the point around which chunks stay loaded.

    If it is never sent, the client shows no chunks at all.
    """

    comptime ID: UInt32 = ID_NETWORK_CHUNK_PUBLISHER_UPDATE
    """The packet ID."""
    var position: BlockPos
    """The block position chunks are loaded around."""
    var radius: UInt32
    """The radius in blocks (not chunks) around `position`."""
    var saved_chunks: List[ChunkPos]
    """Saved chunks; the purpose is unknown. At most 9216."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.radius = 0
        self.saved_chunks = List[ChunkPos]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or there are more than 9216 saved
            chunks.
        """
        block_pos(io, self.position)
        io.varuint32(self.radius)
        var count = UInt32(len(self.saved_chunks))
        io.uint32(count)
        if count > _MAX_SAVED_CHUNKS:
            invalid_value(
                String(count),
                "savedChunks",
                "saved chunks exceeds maximum length of 9216 chunk positions",
            )
        func_slice_of_len[chunk_pos[I]](io, count, self.saved_chunks)
