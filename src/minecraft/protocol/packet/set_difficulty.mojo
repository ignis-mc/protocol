"""The `SetDifficulty` packet (gophertunnel `packet/set_difficulty.go`)."""

from ..io import IO
from .id import ID_SET_DIFFICULTY
from .packet import Packet


struct SetDifficulty(Packet):
    """Sent by the server to update the client-side difficulty."""

    comptime ID: UInt32 = ID_SET_DIFFICULTY
    """The packet ID."""
    var difficulty: UInt32
    """The difficulty, 0 (peaceful) to 3 (hard)."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.difficulty = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.difficulty)
