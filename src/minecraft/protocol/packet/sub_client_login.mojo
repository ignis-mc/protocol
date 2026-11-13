"""The `SubClientLogin` packet (gophertunnel `packet/sub_client_login.go`)."""

from ..io import IO
from .id import ID_SUB_CLIENT_LOGIN
from .packet import Packet


struct SubClientLogin(Packet):
    """Sent when a split-screen sub-client joins."""

    comptime ID: UInt32 = ID_SUB_CLIENT_LOGIN
    """The packet ID."""
    var connection_request: List[UInt8]
    """The sub-client's connection request."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.connection_request = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.byte_slice(self.connection_request)
