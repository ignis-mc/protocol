"""The `ClientToServerHandshake` packet (gophertunnel `packet/client_to_server_handshake.go`)."""

from ..io import IO
from .id import ID_CLIENT_TO_SERVER_HANDSHAKE
from .packet import Packet


struct ClientToServerHandshake(Packet):
    """Sent by the client to answer `ServerToClientHandshake`."""

    comptime ID: UInt32 = ID_CLIENT_TO_SERVER_HANDSHAKE
    """The packet ID."""

    def __init__(out self):
        """Creates the packet; it has no fields."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        pass
