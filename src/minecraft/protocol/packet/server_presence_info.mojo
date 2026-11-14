"""The `ServerPresenceInfo` packet (gophertunnel `packet/server_presence_info.go`).
"""

from ..io import IO, optional_marshaler
from ..server_join_information import PresenceInfo
from .id import ID_SERVER_PRESENCE_INFO
from .packet import Packet


struct ServerPresenceInfo(Packet):
    """Sent by the server to provide the client with presence info."""

    comptime ID: UInt32 = ID_SERVER_PRESENCE_INFO
    """The packet ID."""
    var presence_info: Optional[PresenceInfo]
    """The presence info, or nothing to fall back to the default."""

    def __init__(out self):
        """Creates the packet with no presence info."""
        self.presence_info = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        optional_marshaler(io, self.presence_info)
