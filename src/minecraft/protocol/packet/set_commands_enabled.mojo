"""The `SetCommandsEnabled` packet.

This is gophertunnel `packet/set_commands_enabled.go`.
"""

from ..io import IO
from .id import ID_SET_COMMANDS_ENABLED
from .packet import Packet


struct SetCommandsEnabled(Packet):
    """Sent by the server to allow or forbid commands on the client."""

    comptime ID: UInt32 = ID_SET_COMMANDS_ENABLED
    """The packet ID."""
    var enabled: Bool
    """Whether commands are enabled."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.enabled = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.enabled)
