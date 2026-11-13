"""The `Disconnect` packet (gophertunnel `packet/disconnect.go`)."""

from ..io import IO
from .id import ID_DISCONNECT
from .packet import Packet


struct Disconnect(Packet):
    """Sent by either side before closing the connection."""

    comptime ID: UInt32 = ID_DISCONNECT
    """The packet ID."""
    var reason: Int32
    """The disconnect reason code."""
    var hide_disconnection_screen: Bool
    """Whether the client should skip the disconnection screen."""
    var message: String
    """The message shown on the disconnection screen."""
    var filtered_message: String
    """The profanity-filtered message."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.reason = 0
        self.hide_disconnection_screen = False
        self.message = String()
        self.filtered_message = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.reason)
        io.bool(self.hide_disconnection_screen)
        if not self.hide_disconnection_screen:
            io.string(self.message)
            io.string(self.filtered_message)
