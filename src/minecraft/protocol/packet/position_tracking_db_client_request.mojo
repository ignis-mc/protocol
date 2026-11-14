"""The `PositionTrackingDBClientRequest` packet (gophertunnel `packet/position_tracking_db_client_request.go`).
"""

from ..io import IO
from .id import ID_POSITION_TRACKING_DB_CLIENT_REQUEST
from .packet import Packet

comptime POSITION_TRACKING_DB_REQUEST_ACTION_QUERY: UInt8 = 0
"""Queries the position of a tracking ID."""


struct PositionTrackingDBClientRequest(Packet):
    """Sent by the client to ask where a tracking ID (a lodestone) is.

    The server answers with `PositionTrackingDBServerBroadcast`.
    """

    comptime ID: UInt32 = ID_POSITION_TRACKING_DB_CLIENT_REQUEST
    """The packet ID."""
    var request_action: UInt8
    """One of the `POSITION_TRACKING_DB_REQUEST_ACTION_*` values."""
    var tracking_id: Int32
    """The tracking ID, echoed in the response."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.request_action = POSITION_TRACKING_DB_REQUEST_ACTION_QUERY
        self.tracking_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.request_action)
        io.varint32(self.tracking_id)
