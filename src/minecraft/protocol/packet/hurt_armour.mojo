"""The `HurtArmour` packet (gophertunnel `packet/hurt_armour.go`)."""

from ..io import IO
from .id import ID_HURT_ARMOUR
from .packet import Packet


struct HurtArmour(Packet):
    """Sent by the server to damage the player's armour after being hit."""

    comptime ID: UInt32 = ID_HURT_ARMOUR
    """The packet ID."""
    var cause: Int32
    """The cause of the damage dealt to the armour."""
    var damage: Int32
    """The amount of damage points that was dealt to the player."""
    var armour_slots: UInt64
    """A bitset of all armour slots affected."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.cause = 0
        self.damage = 0
        self.armour_slots = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.cause)
        io.varint32(self.damage)
        io.varuint64(self.armour_slots)
