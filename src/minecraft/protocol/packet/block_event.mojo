"""The `BlockEvent` packet (gophertunnel `packet/block_event.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_BLOCK_EVENT
from .packet import Packet

comptime BLOCK_EVENT_CHANGE_CHEST_STATE: Int32 = 1
"""Go `BlockEventChangeChestState`."""


struct BlockEvent(Packet):
    """Sent by the server to start a block event, such as opening a chest."""

    comptime ID: UInt32 = ID_BLOCK_EVENT
    """The packet ID."""
    var position: BlockPos
    """The position of the block."""
    var event_type: Int32
    """One of the `BLOCK_EVENT_*` values."""
    var event_data: Int32
    """Event-specific data; for chests 1 opens and 0 closes."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.event_type = 0
        self.event_data = 0

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
        io.varint32(self.event_type)
        io.varint32(self.event_data)
