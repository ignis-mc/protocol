"""The `PositionTrackingDBServerBroadcast` packet (gophertunnel `packet/position_tracking_db_server_broadcast.go`).
"""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..io import IO
from .id import ID_POSITION_TRACKING_DB_SERVER_BROADCAST
from .packet import Packet

comptime POSITION_TRACKING_DB_BROADCAST_ACTION_UPDATE: UInt8 = 0
"""Sets the position a lodestone compass points to."""
comptime POSITION_TRACKING_DB_BROADCAST_ACTION_DESTROY: UInt8 = 1
"""The lodestone was destroyed."""
comptime POSITION_TRACKING_DB_BROADCAST_ACTION_NOT_FOUND: UInt8 = 2
"""The tracking ID was not found."""


struct PositionTrackingDBServerBroadcast(Packet):
    """Sent by the server in response to `PositionTrackingDBClientRequest`.

    As of 1.16 it is only used for lodestone compasses.
    """

    comptime ID: UInt32 = ID_POSITION_TRACKING_DB_SERVER_BROADCAST
    """The packet ID."""
    var broadcast_action: UInt8
    """One of the `POSITION_TRACKING_DB_BROADCAST_ACTION_*` values."""
    var tracking_id: Int32
    """The tracking ID from the request."""
    var payload: NBT
    """A network little endian compound with `version`, `dim`, `id`, `pos`
    and `status`."""

    def __init__(out self):
        """Creates the packet with an empty compound payload (as Go writes)."""
        self.broadcast_action = POSITION_TRACKING_DB_BROADCAST_ACTION_UPDATE
        self.tracking_id = 0
        self.payload = NBT.empty_compound(NETWORK_LITTLE_ENDIAN)

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.broadcast_action)
        io.varint32(self.tracking_id)
        nbt(io, self.payload, NETWORK_LITTLE_ENDIAN)
