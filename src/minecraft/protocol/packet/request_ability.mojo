"""The `RequestAbility` packet (gophertunnel `packet/request_ability.go`).

The ability indices here differ from the `ABILITY_*` bit flags in
`protocol/ability.mojo`.
"""

from ..ability import AbilityValue, ability_value
from ..io import IO
from .id import ID_REQUEST_ABILITY
from .packet import Packet

comptime ABILITY_BUILD: Int32 = 0
"""Ability: build."""
comptime ABILITY_MINE: Int32 = 1
"""Ability: mine."""
comptime ABILITY_DOORS_AND_SWITCHES: Int32 = 2
"""Ability: doors and switches."""
comptime ABILITY_OPEN_CONTAINERS: Int32 = 3
"""Ability: open containers."""
comptime ABILITY_ATTACK_PLAYERS: Int32 = 4
"""Ability: attack players."""
comptime ABILITY_ATTACK_MOBS: Int32 = 5
"""Ability: attack mobs."""
comptime ABILITY_OPERATOR_COMMANDS: Int32 = 6
"""Ability: operator commands."""
comptime ABILITY_TELEPORT: Int32 = 7
"""Ability: teleport."""
comptime ABILITY_INVULNERABLE: Int32 = 8
"""Ability: invulnerable."""
comptime ABILITY_FLYING: Int32 = 9
"""Ability: flying."""
comptime ABILITY_MAY_FLY: Int32 = 10
"""Ability: may fly."""
comptime ABILITY_INSTANT_BUILD: Int32 = 11
"""Ability: instant build."""
comptime ABILITY_LIGHTNING: Int32 = 12
"""Ability: lightning."""
comptime ABILITY_FLY_SPEED: Int32 = 13
"""Ability: fly speed."""
comptime ABILITY_WALK_SPEED: Int32 = 14
"""Ability: walk speed."""
comptime ABILITY_MUTED: Int32 = 15
"""Ability: muted."""
comptime ABILITY_WORLD_BUILDER: Int32 = 16
"""Ability: world builder."""
comptime ABILITY_NO_CLIP: Int32 = 17
"""Ability: no clip."""
comptime ABILITY_COUNT: Int32 = 18
"""Ability: count."""


struct RequestAbility(Packet):
    """Sent by the client to ask the server for permission to use an ability."""

    comptime ID: UInt32 = ID_REQUEST_ABILITY
    """The packet ID."""
    var ability: Int32
    """One of the `ABILITY_*` values above."""
    var value: AbilityValue
    """The requested value, a `Bool` or a `Float32`."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.ability = 0
        self.value = AbilityValue()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.ability)
        ability_value(io, self.value)
