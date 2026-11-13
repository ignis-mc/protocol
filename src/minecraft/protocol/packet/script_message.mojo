"""The `ScriptMessage` packet (gophertunnel `packet/script_message.go`)."""

from ..io import IO
from .id import ID_SCRIPT_MESSAGE
from .packet import Packet


struct ScriptMessage(Packet):
    """Carries a custom message between client and server (likely GameTest)."""

    comptime ID: UInt32 = ID_SCRIPT_MESSAGE
    """The packet ID."""
    var identifier: String
    """The identifier of the message."""
    var data: List[UInt8]
    """The message data."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.identifier = String()
        self.data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.identifier)
        io.byte_slice(self.data)
