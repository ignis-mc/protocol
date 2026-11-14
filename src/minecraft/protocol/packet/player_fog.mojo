"""The `PlayerFog` packet (gophertunnel `packet/player_fog.go`)."""

from ..io import IO, func_slice
from .id import ID_PLAYER_FOG
from .packet import Packet


struct PlayerFog(Packet):
    """Sent by the server to set the stack of fogs the client renders."""

    comptime ID: UInt32 = ID_PLAYER_FOG
    """The packet ID."""
    var stack: List[String]
    """Fog identifiers, such as `minecraft:fog_ocean`."""

    def __init__(out self):
        """Creates the packet with an empty stack."""
        self.stack = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        func_slice[I.string](io, self.stack)
