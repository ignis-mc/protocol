"""The `SetScoreboardIdentity` packet.

This is gophertunnel `packet/set_scoreboard_identity.go`.
"""

from ..io import IO, slice, unknown_enum_option
from ..scoreboard import ScoreboardIdentityEntry
from .id import ID_SET_SCOREBOARD_IDENTITY
from .packet import Packet

comptime SCOREBOARD_IDENTITY_ACTION_REGISTER: UInt8 = 0
"""Register the identities."""
comptime SCOREBOARD_IDENTITY_ACTION_CLEAR: UInt8 = 1
"""Clear the identities."""


struct SetScoreboardIdentity(Packet):
    """Sent by the server to change the identity of scoreboard entries."""

    comptime ID: UInt32 = ID_SET_SCOREBOARD_IDENTITY
    """The packet ID."""
    var action_type: UInt8
    """One of the `SCOREBOARD_IDENTITY_ACTION_*` values."""
    var entries: List[ScoreboardIdentityEntry]
    """The entries to change."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_type = 0
        self.entries = List[ScoreboardIdentityEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.action_type)
        if (
            self.action_type != SCOREBOARD_IDENTITY_ACTION_REGISTER
            and self.action_type != SCOREBOARD_IDENTITY_ACTION_CLEAR
        ):
            unknown_enum_option(
                Int(self.action_type), "scoreboard identity action type"
            )
        slice(io, self.entries)
