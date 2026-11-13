"""The `UpdateAbilities` packet (gophertunnel `packet/update_abilities.go`)."""

from ..ability import AbilityData
from ..io import IO
from .id import ID_UPDATE_ABILITIES
from .packet import Packet


struct UpdateAbilities(Packet):
    """Sent by the server to update the abilities of a player."""

    comptime ID: UInt32 = ID_UPDATE_ABILITIES
    """The packet ID."""
    var ability_data: AbilityData
    """The abilities."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.ability_data = AbilityData()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.ability_data.marshal(io)
