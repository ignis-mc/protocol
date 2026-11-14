"""The `UpdatePlayerGameType` packet.

This is gophertunnel `packet/update_player_game_type.go`.
"""

from ..io import IO, actor_unique_id
from .id import ID_UPDATE_PLAYER_GAME_TYPE
from .packet import Packet


struct UpdatePlayerGameType(Packet):
    """Sent by the server to change the game mode of a player."""

    comptime ID: UInt32 = ID_UPDATE_PLAYER_GAME_TYPE
    """The packet ID."""
    var game_type: Int32
    """One of the `GAME_TYPE_*` values."""
    var player_unique_id: Int64
    """The unique ID of the player."""
    var tick: UInt64
    """The server tick of the update, or 0."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.game_type = 0
        self.player_unique_id = 0
        self.tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.game_type)
        actor_unique_id(io, self.player_unique_id)
        io.varuint64(self.tick)
