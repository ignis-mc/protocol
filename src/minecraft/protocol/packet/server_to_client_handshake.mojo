"""The `ServerToClientHandshake` packet.

This is gophertunnel `packet/server_to_client_handshake.go`.
"""

from ..io import IO
from .id import ID_SERVER_TO_CLIENT_HANDSHAKE
from .packet import Packet


struct ServerToClientHandshake(Packet):
    """Sent by the server to complete the key exchange."""

    comptime ID: UInt32 = ID_SERVER_TO_CLIENT_HANDSHAKE
    """The packet ID."""
    var jwt: List[UInt8]
    """The raw JWT with the server's public key and salt."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.jwt = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.byte_slice(self.jwt)
