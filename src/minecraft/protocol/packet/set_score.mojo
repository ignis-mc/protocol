"""The `SetScore` packet (gophertunnel `packet/set_score.go`)."""

from ..io import IO, slice
from ..scoreboard import ScoreboardEntry
from .id import ID_SET_SCORE
from .packet import Packet


struct SetScore(Packet):
    """Sent by the server to add, change or remove scoreboard entries."""

    comptime ID: UInt32 = ID_SET_SCORE
    """The packet ID."""
    var entries: List[ScoreboardEntry]
    """The entries to change."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entries = List[ScoreboardEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.entries)
