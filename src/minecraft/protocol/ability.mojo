"""Player abilities (gophertunnel `protocol/ability.go`).

`AbilityValue` ports the Go `IO.AbilityValue` method, whose value is a Go
`any` holding a `bool` or a `float32`.
"""

from std.utils import Variant

from .io import IO, Marshaler, invalid_value, slice

comptime ABILITY_BUILD: UInt32 = 1 << 0
"""The `Build` ability bit."""
comptime ABILITY_MINE: UInt32 = 1 << 1
"""The `Mine` ability bit."""
comptime ABILITY_DOORS_AND_SWITCHES: UInt32 = 1 << 2
"""The `DoorsAndSwitches` ability bit."""
comptime ABILITY_OPEN_CONTAINERS: UInt32 = 1 << 3
"""The `OpenContainers` ability bit."""
comptime ABILITY_ATTACK_PLAYERS: UInt32 = 1 << 4
"""The `AttackPlayers` ability bit."""
comptime ABILITY_ATTACK_MOBS: UInt32 = 1 << 5
"""The `AttackMobs` ability bit."""
comptime ABILITY_OPERATOR_COMMANDS: UInt32 = 1 << 6
"""The `OperatorCommands` ability bit."""
comptime ABILITY_TELEPORT: UInt32 = 1 << 7
"""The `Teleport` ability bit."""
comptime ABILITY_INVULNERABLE: UInt32 = 1 << 8
"""The `Invulnerable` ability bit."""
comptime ABILITY_FLYING: UInt32 = 1 << 9
"""The `Flying` ability bit."""
comptime ABILITY_MAY_FLY: UInt32 = 1 << 10
"""The `MayFly` ability bit."""
comptime ABILITY_INSTANT_BUILD: UInt32 = 1 << 11
"""The `InstantBuild` ability bit."""
comptime ABILITY_LIGHTNING: UInt32 = 1 << 12
"""The `Lightning` ability bit."""
comptime ABILITY_FLY_SPEED: UInt32 = 1 << 13
"""The `FlySpeed` ability bit."""
comptime ABILITY_WALK_SPEED: UInt32 = 1 << 14
"""The `WalkSpeed` ability bit."""
comptime ABILITY_MUTED: UInt32 = 1 << 15
"""The `Muted` ability bit."""
comptime ABILITY_WORLD_BUILDER: UInt32 = 1 << 16
"""The `WorldBuilder` ability bit."""
comptime ABILITY_NO_CLIP: UInt32 = 1 << 17
"""The `NoClip` ability bit."""
comptime ABILITY_PRIVILEGED_BUILDER: UInt32 = 1 << 18
"""The `PrivilegedBuilder` ability bit."""
comptime ABILITY_VERTICAL_FLY_SPEED: UInt32 = 1 << 19
"""The `VerticalFlySpeed` ability bit."""
comptime ABILITY_COUNT: UInt32 = 1 << 20
"""The bit after the last ability (Go `AbilityCount`)."""

comptime ABILITY_LAYER_TYPE_CUSTOM_CACHE: UInt16 = 0
"""A cached custom layer."""
comptime ABILITY_LAYER_TYPE_BASE: UInt16 = 1
"""The base layer."""
comptime ABILITY_LAYER_TYPE_SPECTATOR: UInt16 = 2
"""The spectator layer."""
comptime ABILITY_LAYER_TYPE_COMMANDS: UInt16 = 3
"""The layer set by commands."""
comptime ABILITY_LAYER_TYPE_EDITOR: UInt16 = 4
"""The editor layer."""
comptime ABILITY_LAYER_TYPE_LOADING_SCREEN: UInt16 = 5
"""The loading screen layer."""

comptime ABILITY_BASE_FLY_SPEED: Float32 = 0.05
"""The default horizontal fly speed."""
comptime ABILITY_BASE_WALK_SPEED: Float32 = 0.1
"""The default walk speed."""
comptime ABILITY_BASE_VERTICAL_FLY_SPEED: Float32 = 1.0
"""The default vertical fly speed."""


struct AbilityLayer(Marshaler):
    """The abilities of one layer, such as the base or spectator layer."""

    var type: UInt16
    """One of the `ABILITY_LAYER_TYPE_*` values."""
    var abilities: UInt32
    """The `ABILITY_*` bits this layer sets."""
    var values: UInt32
    """The values of the abilities in `abilities`."""
    var fly_speed: Float32
    """The default horizontal fly speed."""
    var vertical_fly_speed: Float32
    """The default vertical fly speed."""
    var walk_speed: Float32
    """The default walk speed."""

    def __init__(out self):
        """Creates a zero layer."""
        self.type = 0
        self.abilities = 0
        self.values = 0
        self.fly_speed = 0
        self.vertical_fly_speed = 0
        self.walk_speed = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the layer.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint16(self.type)
        io.uint32(self.abilities)
        io.uint32(self.values)
        io.float32(self.fly_speed)
        io.float32(self.vertical_fly_speed)
        io.float32(self.walk_speed)


struct AbilityData(Marshaler):
    """The ability layers and permissions of a player."""

    var entity_unique_id: Int64
    """The player's unique ID; 0 works."""
    var player_permissions: UInt8
    """The permission level shown in the player list."""
    var command_permissions: UInt8
    """The commands the player may run."""
    var layers: List[AbilityLayer]
    """The ability layers; at least the base layer."""

    def __init__(out self):
        """Creates data with no layers."""
        self.entity_unique_id = 0
        self.player_permissions = 0
        self.command_permissions = 0
        self.layers = List[AbilityLayer]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the data.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        io.int64(self.entity_unique_id)
        io.uint8(self.player_permissions)
        io.uint8(self.command_permissions)
        slice(io, self.layers)


comptime _ABILITY_VALUE_TYPE_BOOL: UInt8 = 1
comptime _ABILITY_VALUE_TYPE_FLOAT: UInt8 = 2


struct AbilityValue(Marshaler):
    """The value of a requested ability: a `Bool` or a `Float32`."""

    var value: Variant[Bool, Float32]
    """The value."""

    def __init__(out self):
        """Creates `False`."""
        self.value = False

    @implicit
    def __init__(out self, value: Bool):
        """Creates a boolean value.

        Args:
            value: The value.
        """
        self.value = value

    @implicit
    def __init__(out self, value: Float32):
        """Creates a float value.

        Args:
            value: The value.
        """
        self.value = value

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value (see `ability_value`).

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        ability_value(io, self)


def ability_value[I: IO](mut io: I, mut x: AbilityValue) raises:
    """Marshals a type byte, a bool and a float; only one of them is used.

    This is gophertunnel `IO.AbilityValue`.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the type byte is neither bool (1) nor float (2).
    """
    var value_type = _ABILITY_VALUE_TYPE_FLOAT
    var bool_value = False
    var float_value = Float32(0)
    if x.value.isa[Bool]():
        value_type = _ABILITY_VALUE_TYPE_BOOL
        bool_value = x.value[Bool]
    else:
        float_value = x.value[Float32]
    io.uint8(value_type)
    io.bool(bool_value)
    io.float32(float_value)
    if not io.reads():
        return
    if value_type == _ABILITY_VALUE_TYPE_BOOL:
        x.value = bool_value
    elif value_type == _ABILITY_VALUE_TYPE_FLOAT:
        x.value = float_value
    else:
        invalid_value(
            String(value_type), "ability value type", "must be bool or float32"
        )
