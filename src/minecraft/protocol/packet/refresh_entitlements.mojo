"""The `RefreshEntitlements` packet (gophertunnel `packet/refresh_entitlements.go`).
"""

from ..io import IO
from .id import ID_REFRESH_ENTITLEMENTS
from .packet import Packet


struct RefreshEntitlements(Packet):
    """Sent by the client to refresh the player's entitlements. No fields."""

    comptime ID: UInt32 = ID_REFRESH_ENTITLEMENTS
    """The packet ID."""

    def __init__(out self):
        """Creates the packet."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the packet has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never.
        """
        pass
