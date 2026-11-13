"""The `RequestPermissions` packet (gophertunnel `packet/request_permissions.go`).
"""

from ..io import IO
from .id import ID_REQUEST_PERMISSIONS
from .packet import Packet


struct RequestPermissions(Packet):
    """Sent by the client to request permissions it does not have.

    In vanilla only operators and the host can send it.
    """

    comptime ID: UInt32 = ID_REQUEST_PERMISSIONS
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the player, sent as a fixed-width `int64`."""
    var permission_level: Int32
    """The player's current permission level."""
    var requested_permissions: UInt16
    """The requested permission flags."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.permission_level = 0
        self.requested_permissions = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int64(self.entity_unique_id)  # Go: ActorUniqueIDInt64
        io.varint32(self.permission_level)
        io.uint16(self.requested_permissions)
