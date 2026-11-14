"""The `AdventureSettings` packet (gophertunnel `packet/adventure_settings.go`).

`ADVENTURE_SETTINGS_FLAGS_NO_PVM` and `_NO_MVP` are Go
`AdventureSettingsFlagsNoPvM` and `AdventureSettingsFlagsNoMvP`.
"""

from ..io import IO
from .id import ID_ADVENTURE_SETTINGS
from .packet import Packet

comptime ADVENTURE_FLAG_WORLD_IMMUTABLE: UInt32 = 1
"""Go `AdventureFlagWorldImmutable`."""
comptime ADVENTURE_SETTINGS_FLAGS_NO_PVM: UInt32 = 2
"""Go `AdventureSettingsFlagsNoPvM`."""
comptime ADVENTURE_SETTINGS_FLAGS_NO_MVP: UInt32 = 4
"""Go `AdventureSettingsFlagsNoMvP`."""
comptime ADVENTURE_SETTINGS_FLAGS_UNUSED: UInt32 = 8
"""Go `AdventureSettingsFlagsUnused`."""
comptime ADVENTURE_SETTINGS_FLAGS_SHOW_NAME_TAGS: UInt32 = 16
"""Go `AdventureSettingsFlagsShowNameTags`."""
comptime ADVENTURE_FLAG_AUTO_JUMP: UInt32 = 32
"""Go `AdventureFlagAutoJump`."""
comptime ADVENTURE_FLAG_ALLOW_FLIGHT: UInt32 = 64
"""Go `AdventureFlagAllowFlight`."""
comptime ADVENTURE_FLAG_NO_CLIP: UInt32 = 128
"""Go `AdventureFlagNoClip`."""
comptime ADVENTURE_FLAG_WORLD_BUILDER: UInt32 = 256
"""Go `AdventureFlagWorldBuilder`."""
comptime ADVENTURE_FLAG_FLYING: UInt32 = 512
"""Go `AdventureFlagFlying`."""
comptime ADVENTURE_FLAG_MUTED: UInt32 = 1024
"""Go `AdventureFlagMuted`."""
comptime ACTION_PERMISSION_MINE: UInt32 = 1
"""Go `ActionPermissionMine`."""
comptime ACTION_PERMISSION_DOORS_AND_SWITCHES: UInt32 = 2
"""Go `ActionPermissionDoorsAndSwitches`."""
comptime ACTION_PERMISSION_OPEN_CONTAINERS: UInt32 = 4
"""Go `ActionPermissionOpenContainers`."""
comptime ACTION_PERMISSION_ATTACK_PLAYERS: UInt32 = 8
"""Go `ActionPermissionAttackPlayers`."""
comptime ACTION_PERMISSION_ATTACK_MOBS: UInt32 = 16
"""Go `ActionPermissionAttackMobs`."""
comptime ACTION_PERMISSION_OPERATOR: UInt32 = 32
"""Go `ActionPermissionOperator`."""
comptime ACTION_PERMISSION_TELEPORT: UInt32 = 64
"""Go `ActionPermissionTeleport`."""
comptime ACTION_PERMISSION_BUILD: UInt32 = 128
"""Go `ActionPermissionBuild`."""
comptime ACTION_PERMISSION_DEFAULT: UInt32 = 256
"""Go `ActionPermissionDefault`."""
comptime PERMISSION_LEVEL_VISITOR: UInt32 = 0
"""Go `PermissionLevelVisitor`."""
comptime PERMISSION_LEVEL_MEMBER: UInt32 = 1
"""Go `PermissionLevelMember`."""
comptime PERMISSION_LEVEL_OPERATOR: UInt32 = 2
"""Go `PermissionLevelOperator`."""
comptime PERMISSION_LEVEL_CUSTOM: UInt32 = 3
"""Go `PermissionLevelCustom`."""


struct AdventureSettings(Packet):
    """Sent by the server to update player permissions (superseded)."""

    comptime ID: UInt32 = ID_ADVENTURE_SETTINGS
    """The packet ID."""
    var flags: UInt32
    """A combination of the `ADVENTURE_*` flags."""
    var command_permission_level: UInt32
    """The kind of commands the player may use."""
    var action_permissions: UInt32
    """A combination of the `ACTION_PERMISSION_*` flags."""
    var permission_level: UInt32
    """One of the `PERMISSION_LEVEL_*` values."""
    var custom_stored_permissions: UInt32
    """Custom stored permissions."""
    var player_unique_id: Int64
    """The entity unique ID of the player."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.flags = 0
        self.command_permission_level = 0
        self.action_permissions = 0
        self.permission_level = 0
        self.custom_stored_permissions = 0
        self.player_unique_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.flags)
        io.varuint32(self.command_permission_level)
        io.varuint32(self.action_permissions)
        io.varuint32(self.permission_level)
        io.varuint32(self.custom_stored_permissions)
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        io.int64(self.player_unique_id)
