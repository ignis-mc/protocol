"""The `ShowCredits` packet (gophertunnel `packet/show_credits.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_SHOW_CREDITS
from .packet import Packet

comptime SHOW_CREDITS_STATUS_START: Int32 = 0
"""Start showing the credits."""
comptime SHOW_CREDITS_STATUS_END: Int32 = 1
"""Stop showing the credits."""


struct ShowCredits(Packet):
    """Sent by the server to show the credits screen."""

    comptime ID: UInt32 = ID_SHOW_CREDITS
    """The packet ID."""
    var player_runtime_id: UInt64
    """The runtime ID of the player."""
    var status_type: Int32
    """One of the `SHOW_CREDITS_STATUS_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.player_runtime_id = 0
        self.status_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.player_runtime_id)
        io.varint32(self.status_type)
