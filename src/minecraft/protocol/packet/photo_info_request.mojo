"""The `PhotoInfoRequest` packet (gophertunnel `packet/photo_info_request.go`).

Deprecated since 1.19.80.
"""

from ..io import IO
from .id import ID_PHOTO_INFO_REQUEST
from .packet import Packet


struct PhotoInfoRequest(Packet):
    """Sent by the client to request photo information (deprecated)."""

    comptime ID: UInt32 = ID_PHOTO_INFO_REQUEST
    """The packet ID."""
    var photo_id: Int64
    """The ID of the photo."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.photo_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint64(self.photo_id)
