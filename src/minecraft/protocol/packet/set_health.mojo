"""The `SetHealth` packet (gophertunnel `packet/set_health.go`)."""

from ..io import IO
from .id import ID_SET_HEALTH
from .packet import Packet


struct SetHealth(Packet):
    """Sent by the server to set the player's health (deprecated)."""

    comptime ID: UInt32 = ID_SET_HEALTH
    """The packet ID."""
    var health: Int32
    """The new health."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.health = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.health)
