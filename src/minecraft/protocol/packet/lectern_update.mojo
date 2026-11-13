"""The `LecternUpdate` packet (gophertunnel `packet/lectern_update.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_LECTERN_UPDATE
from .packet import Packet


struct LecternUpdate(Packet):
    """Sent by the client to update the server on which page was opened in a
    book on a lectern, or if the book should be removed from it.
    """

    comptime ID: UInt32 = ID_LECTERN_UPDATE
    """The packet ID."""
    var page: UInt8
    """The page number in the book that was opened by the player on the lectern.
    """
    var page_count: UInt8
    """The number of pages that the book opened in the lectern has."""
    var position: BlockPos
    """The position of the lectern that was updated."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.page = 0
        self.page_count = 0
        self.position = BlockPos()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.page)
        io.uint8(self.page_count)
        block_pos(io, self.position)
