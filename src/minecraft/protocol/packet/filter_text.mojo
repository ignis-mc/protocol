"""The `FilterText` packet (gophertunnel `packet/filter_text.go`)."""

from ..io import IO
from .id import ID_FILTER_TEXT
from .packet import Packet


struct FilterText(Packet):
    """Sent by the client to have text filtered, and by the server with the
    filtered text.

    Deprecated in the protocol.
    """

    comptime ID: UInt32 = ID_FILTER_TEXT
    """The packet ID."""
    var text: String
    """Either the text from the client or the safer version of the text sent by
    the server.
    """
    var from_server: Bool
    """Whether the server sent the packet."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.text = String()
        self.from_server = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.text)
        io.bool(self.from_server)
