"""The `MultiPlayerSettings` packet (gophertunnel `packet/multi_player_settings.go`).
"""

from ..io import IO
from .id import ID_MULTI_PLAYER_SETTINGS
from .packet import Packet

comptime ENABLE_MULTI_PLAYER: Int32 = 0
"""Enables multi-player."""
comptime DISABLE_MULTI_PLAYER: Int32 = 1
"""Disables multi-player."""
comptime REFRESH_JOIN_CODE: Int32 = 2
"""Refreshes the join code."""


struct MultiPlayerSettings(Packet):
    """Updates multi-player settings (Education Edition only)."""

    comptime ID: UInt32 = ID_MULTI_PLAYER_SETTINGS
    """The packet ID."""
    var action_type: Int32
    """One of `ENABLE_MULTI_PLAYER`, `DISABLE_MULTI_PLAYER` and `REFRESH_JOIN_CODE`.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.action_type)
