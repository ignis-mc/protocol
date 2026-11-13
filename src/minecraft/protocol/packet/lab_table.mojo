"""The `LabTable` packet (gophertunnel `packet/lab_table.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_LAB_TABLE
from .packet import Packet

comptime LAB_TABLE_ACTION_COMBINE: UInt8 = 0
"""The combine lab table action."""
comptime LAB_TABLE_ACTION_REACT: UInt8 = 1
"""The react lab table action."""
comptime LAB_TABLE_ACTION_RESET: UInt8 = 2
"""The reset lab table action."""


struct LabTable(Packet):
    """Sent by the client to let the server know it started a chemical reaction
    in Education Edition, and is sent by the server to other clients to show the
    effects.
    """

    comptime ID: UInt32 = ID_LAB_TABLE
    """The packet ID."""
    var action_type: UInt8
    """The type of the action that was executed."""
    var position: BlockPos
    """The position at which the lab table used was located."""
    var reaction_type: UInt8
    """The type of the reaction that took place as a result of the items put
    into the lab table.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_type = 0
        self.position = BlockPos()
        self.reaction_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.action_type)
        block_pos(io, self.position)
        io.uint8(self.reaction_type)
