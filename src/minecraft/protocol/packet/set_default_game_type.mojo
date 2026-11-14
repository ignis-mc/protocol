"""The `SetDefaultGameType` packet.

This is gophertunnel `packet/set_default_game_type.go`.
"""

from ..io import IO
from .id import ID_SET_DEFAULT_GAME_TYPE
from .packet import Packet


struct SetDefaultGameType(Packet):
    """Sent by either side when the default game type changes."""

    comptime ID: UInt32 = ID_SET_DEFAULT_GAME_TYPE
    """The packet ID."""
    var game_type: Int32
    """The new default game type."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.game_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.game_type)
