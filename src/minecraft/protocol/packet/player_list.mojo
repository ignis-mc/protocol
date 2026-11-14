"""The `PlayerList` packet (gophertunnel `packet/player_list.go`)."""

from ..io import IO, slice
from ..player import PlayerListEntry
from .id import ID_PLAYER_LIST
from .packet import Packet


struct PlayerList(Packet):
    """Sent by the server to add players to or remove them from the list.

    A player must be in the list before `AddPlayer`, since the client takes
    properties such as the skin from it.
    """

    comptime ID: UInt32 = ID_PLAYER_LIST
    """The packet ID."""
    var entries: List[PlayerListEntry]
    """The entries to add or remove, by each entry's action type."""

    def __init__(out self):
        """Creates the packet with no entries."""
        self.entries = List[PlayerListEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.entries)
