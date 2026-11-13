"""The `UpdateBlockSynced` packet.

This is gophertunnel `packet/update_block_synced.go`.
"""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_UPDATE_BLOCK_SYNCED
from .packet import Packet

comptime BLOCK_TO_ENTITY_TRANSITION: UInt64 = 1
"""The block becomes an entity."""
comptime ENTITY_TO_BLOCK_TRANSITION: UInt64 = 2
"""The entity becomes a block."""


struct UpdateBlockSynced(Packet):
    """Synchronises a falling block entity with its block."""

    comptime ID: UInt32 = ID_UPDATE_BLOCK_SYNCED
    """The packet ID."""
    var position: BlockPos
    """The position of the block."""
    var new_block_runtime_id: UInt32
    """The runtime ID of the new block."""
    var flags: UInt32
    """A combination of `BLOCK_UPDATE_*` flags."""
    var layer: UInt32
    """The block layer: 0 normal, 1 liquid."""
    var entity_unique_id: UInt64
    """The unique ID of the falling block entity."""
    var transition_type: UInt64
    """One of the transition values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.new_block_runtime_id = 0
        self.flags = 0
        self.layer = 0
        self.entity_unique_id = 0
        self.transition_type = 0

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
        io.varuint32(self.new_block_runtime_id)
        io.varuint32(self.flags)
        io.varuint32(self.layer)
        io.varuint64(self.entity_unique_id)
        io.varuint64(self.transition_type)
