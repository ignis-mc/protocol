"""The `BlockPickRequest` packet (gophertunnel `packet/block_pick_request.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_BLOCK_PICK_REQUEST
from .packet import Packet


struct BlockPickRequest(Packet):
    """Sent by the client when it picks a block to get its item."""

    comptime ID: UInt32 = ID_BLOCK_PICK_REQUEST
    """The packet ID."""
    var position: BlockPos
    """The position of the picked block."""
    var add_block_nbt: Bool
    """Whether the item should carry the NBT of the block."""
    var hot_bar_slot: UInt8
    """The held hot bar slot when picking."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.add_block_nbt = False
        self.hot_bar_slot = 0

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
        io.bool(self.add_block_nbt)
        io.uint8(self.hot_bar_slot)
