"""The `UpdateBlock` packet (gophertunnel `packet/update_block.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_UPDATE_BLOCK
from .packet import Packet

comptime BLOCK_UPDATE_NEIGHBOURS: UInt32 = 1 << 0
"""Neighbouring blocks are updated."""
comptime BLOCK_UPDATE_NETWORK: UInt32 = 1 << 1
"""The update is sent over the network."""
comptime BLOCK_UPDATE_NO_GRAPHICS: UInt32 = 1 << 2
"""The block is not redrawn."""
comptime BLOCK_UPDATE_PRIORITY: UInt32 = 1 << 3
"""The update has priority."""


struct UpdateBlock(Packet):
    """Sent by the server to change one block."""

    comptime ID: UInt32 = ID_UPDATE_BLOCK
    """The packet ID."""
    var position: BlockPos
    """The position of the block."""
    var new_block_runtime_id: UInt32
    """The runtime ID of the new block."""
    var flags: UInt32
    """A combination of `BLOCK_UPDATE_*` flags."""
    var layer: UInt32
    """The block layer: 0 normal, 1 liquid."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.new_block_runtime_id = 0
        self.flags = 0
        self.layer = 0

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
