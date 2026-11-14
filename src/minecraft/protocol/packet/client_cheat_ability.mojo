"""The `ClientCheatAbility` packet (gophertunnel `packet/client_cheat_ability.go`)."""

from ..ability import AbilityData
from ..io import IO
from .id import ID_CLIENT_CHEAT_ABILITY
from .packet import Packet


struct ClientCheatAbility(Packet):
    """Functions the same as `UpdateAbilities`; deprecated as of 1.20.10."""

    comptime ID: UInt32 = ID_CLIENT_CHEAT_ABILITY
    """The packet ID."""
    var ability_data: AbilityData
    """The ability layers and permissions of the player."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.ability_data = AbilityData()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        self.ability_data.marshal(io)
