"""The `CreativeContent` packet (gophertunnel `packet/creative_content.go`)."""

from ..creative import CreativeGroup, CreativeItem
from ..io import IO, slice
from .id import ID_CREATIVE_CONTENT
from .packet import Packet


struct CreativeContent(Packet):
    """A packet sent by the server to set the creative inventory's content for a
    player.
    """

    comptime ID: UInt32 = ID_CREATIVE_CONTENT
    """The packet ID."""
    var groups: List[CreativeGroup]
    """A list of the groups that should be added to the creative inventory."""
    var items: List[CreativeItem]
    """A list of the items that should be added to the creative inventory."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.groups = List[CreativeGroup]()
        self.items = List[CreativeItem]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.groups)
        slice(io, self.items)
