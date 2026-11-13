"""The `SetPlayerGameType` packet.

This is gophertunnel `packet/set_player_game_type.go`.
"""

from ..io import IO
from .id import ID_SET_PLAYER_GAME_TYPE
from .packet import Packet

comptime GAME_TYPE_SURVIVAL: Int32 = 0
"""Survival mode."""
comptime GAME_TYPE_CREATIVE: Int32 = 1
"""Creative mode."""
comptime GAME_TYPE_ADVENTURE: Int32 = 2
"""Adventure mode."""
comptime GAME_TYPE_DEFAULT: Int32 = 5
"""The world's default game mode."""
comptime GAME_TYPE_SPECTATOR: Int32 = 6
"""Spectator mode."""


struct SetPlayerGameType(Packet):
    """Sent by the server to update the game mode of a player."""

    comptime ID: UInt32 = ID_SET_PLAYER_GAME_TYPE
    """The packet ID."""
    var game_type: Int32
    """One of the `GAME_TYPE_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.game_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.game_type)
