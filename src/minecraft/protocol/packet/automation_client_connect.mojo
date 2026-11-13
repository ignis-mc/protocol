"""The `AutomationClientConnect` packet (gophertunnel `packet/automation_client_connect.go`)."""

from ..io import IO
from .id import ID_AUTOMATION_CLIENT_CONNECT
from .packet import Packet


struct AutomationClientConnect(Packet):
    """Makes the client connect to a websocket server that runs commands."""

    comptime ID: UInt32 = ID_AUTOMATION_CLIENT_CONNECT
    """The packet ID."""
    var server_uri: String
    """The URI to connect to, such as `localhost:8000/ws`."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.server_uri = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.server_uri)
