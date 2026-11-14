"""The `ServerboundMatchmakingCancel` packet.

This is gophertunnel `packet/serverbound_matchmaking_cancel.go`.
"""

from ..io import IO
from .id import ID_SERVERBOUND_MATCHMAKING_CANCEL
from .packet import Packet


struct ServerboundMatchmakingCancel(Packet):
    """Sent by the client to cancel its matchmaking ticket."""

    comptime ID: UInt32 = ID_SERVERBOUND_MATCHMAKING_CANCEL
    """The packet ID."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        pass
