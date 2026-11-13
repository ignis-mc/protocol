"""The `UpdateSubChunkBlocks` packet.

This is gophertunnel `packet/update_sub_chunk_blocks.go`.
"""

from ..block import BlockChangeEntry
from ..block_pos import BlockPos
from ..io import IO, block_pos, slice
from .id import ID_UPDATE_SUB_CHUNK_BLOCKS
from .packet import Packet


struct UpdateSubChunkBlocks(Packet):
    """Changes several blocks of one sub-chunk."""

    comptime ID: UInt32 = ID_UPDATE_SUB_CHUNK_BLOCKS
    """The packet ID."""
    var position: BlockPos
    """The position of the sub-chunk."""
    var blocks: List[BlockChangeEntry]
    """Changes on the first layer."""
    var extra: List[BlockChangeEntry]
    """Changes on the second (liquid) layer."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.blocks = List[BlockChangeEntry]()
        self.extra = List[BlockChangeEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        block_pos(io, self.position)
        slice(io, self.blocks)
        slice(io, self.extra)
