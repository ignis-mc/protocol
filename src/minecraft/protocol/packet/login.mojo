"""The `Login` packet (gophertunnel `packet/login.go`)."""

from ..io import IO
from .id import ID_LOGIN
from .packet import Packet


struct Login(Packet):
    """Sent by the client with its identity and client data."""

    comptime ID: UInt32 = ID_LOGIN
    """The packet ID."""
    var client_protocol: Int32
    """The client's protocol version."""
    var connection_request: List[UInt8]
    """The encoded login request (`minecraft.protocol.login`)."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.client_protocol = 0
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
        io.be_int32(self.client_protocol)
        io.byte_slice(self.connection_request)
