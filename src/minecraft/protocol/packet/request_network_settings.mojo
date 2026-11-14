"""The `RequestNetworkSettings` packet (gophertunnel `packet/request_network_settings.go`)."""

from ..io import IO
from .id import ID_REQUEST_NETWORK_SETTINGS
from .packet import Packet


struct RequestNetworkSettings(Packet):
    """Sent by the client first, to ask for compression settings."""

    comptime ID: UInt32 = ID_REQUEST_NETWORK_SETTINGS
    """The packet ID."""
    var client_protocol: Int32
    """The client's protocol version."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.client_protocol = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.be_int32(self.client_protocol)
