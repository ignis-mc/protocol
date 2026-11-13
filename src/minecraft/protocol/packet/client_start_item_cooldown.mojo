"""The `ClientStartItemCooldown` packet (gophertunnel `packet/client_start_item_cooldown.go`)."""

from ..io import IO
from .id import ID_CLIENT_START_ITEM_COOLDOWN
from .packet import Packet


struct ClientStartItemCooldown(Packet):
    """Sent by the server to start a cooldown on an item category."""

    comptime ID: UInt32 = ID_CLIENT_START_ITEM_COOLDOWN
    """The packet ID."""
    var category: String
    """The item category to cool down."""
    var duration: Int32
    """The cooldown in ticks."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.category = String()
        self.duration = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.category)
        io.varint32(self.duration)
