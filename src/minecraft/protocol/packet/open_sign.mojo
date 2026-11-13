"""The `OpenSign` packet (gophertunnel `packet/open_sign.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_OPEN_SIGN
from .packet import Packet


struct OpenSign(Packet):
    """Sent by the server to open a sign for editing."""

    comptime ID: UInt32 = ID_OPEN_SIGN
    """The packet ID."""
    var position: BlockPos
    """The position of the sign."""
    var front_side: Bool
    """Whether the front side is edited; otherwise the back side."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.front_side = False

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
        io.bool(self.front_side)
