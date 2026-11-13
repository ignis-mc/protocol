"""The `PlayerArmourDamage` packet (gophertunnel `packet/player_armour_damage.go`).
"""

from ..io import IO, slice
from ..player import PlayerArmourDamageEntry
from .id import ID_PLAYER_ARMOUR_DAMAGE
from .packet import Packet

comptime PLAYER_ARMOUR_DAMAGE_FLAG_HELMET: Int32 = 0
"""The helmet slot."""
comptime PLAYER_ARMOUR_DAMAGE_FLAG_CHESTPLATE: Int32 = 1
"""The chestplate slot."""
comptime PLAYER_ARMOUR_DAMAGE_FLAG_LEGGINGS: Int32 = 2
"""The leggings slot."""
comptime PLAYER_ARMOUR_DAMAGE_FLAG_BOOTS: Int32 = 3
"""The boots slot."""
comptime PLAYER_ARMOUR_DAMAGE_FLAG_BODY: Int32 = 4
"""The body slot."""


struct PlayerArmourDamage(Packet):
    """Sent by the server to damage pieces of a player's armour."""

    comptime ID: UInt32 = ID_PLAYER_ARMOUR_DAMAGE
    """The packet ID."""
    var list: List[PlayerArmourDamageEntry]
    """The armour pieces to damage."""

    def __init__(out self):
        """Creates the packet with no entries."""
        self.list = List[PlayerArmourDamageEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.list)
