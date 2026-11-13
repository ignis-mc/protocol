"""Command structures (gophertunnel `protocol/command.go`).

The `AvailableCommands` packet builds its commands from these: enums point
into a shared value list, commands point at enums and chained subcommands.
"""

from .io import (
    IO,
    MAX_SLICE_LENGTH,
    Marshaler,
    invalid_value,
    slice,
    string_slice,
    uuid,
)
from .misc_helpers import uint32_slice
from .uuid import UUID

comptime COMMAND_PERMISSION_LEVEL_ANY: UInt8 = 0
"""The `Any` command permission level."""
comptime COMMAND_PERMISSION_LEVEL_GAME_DIRECTORS: UInt8 = 1
"""The `Game Directors` command permission level."""
comptime COMMAND_PERMISSION_LEVEL_ADMIN: UInt8 = 2
"""The `Admin` command permission level."""
comptime COMMAND_PERMISSION_LEVEL_HOST: UInt8 = 3
"""The `Host` command permission level."""
comptime COMMAND_PERMISSION_LEVEL_OWNER: UInt8 = 4
"""The `Owner` command permission level."""
comptime COMMAND_PERMISSION_LEVEL_INTERNAL: UInt8 = 5
"""The `Internal` command permission level."""

comptime COMMAND_ARG_VALID: UInt32 = 0x100000
"""Parameter type flag: Valid."""
comptime COMMAND_ARG_ENUM: UInt32 = 0x200000
"""Parameter type flag: Enum."""
comptime COMMAND_ARG_SUFFIXED: UInt32 = 0x1000000
"""Parameter type flag: Suffixed."""
comptime COMMAND_ARG_SOFT_ENUM: UInt32 = 0x4000000
"""Parameter type flag: Soft Enum."""

comptime COMMAND_ARG_TYPE_INT: UInt32 = 1
"""The `Int` argument type."""
comptime COMMAND_ARG_TYPE_FLOAT: UInt32 = 3
"""The `Float` argument type."""
comptime COMMAND_ARG_TYPE_R_VALUE: UInt32 = 4
"""The `R Value` argument type."""
comptime COMMAND_ARG_TYPE_WILDCARD_INT: UInt32 = 5
"""The `Wildcard Int` argument type."""
comptime COMMAND_ARG_TYPE_OPERATOR: UInt32 = 6
"""The `Operator` argument type."""
comptime COMMAND_ARG_TYPE_COMPARE_OPERATOR: UInt32 = 7
"""The `Compare Operator` argument type."""
comptime COMMAND_ARG_TYPE_TARGET: UInt32 = 8
"""The `Target` argument type."""
comptime COMMAND_ARG_TYPE_STANDALONE_TARGET: UInt32 = 9
"""The `Standalone Target` argument type."""
comptime COMMAND_ARG_TYPE_WILDCARD_TARGET: UInt32 = 10
"""The `Wildcard Target` argument type."""
comptime COMMAND_ARG_TYPE_NON_ID_TARGET: UInt32 = 11
"""The `Non ID Target` argument type."""
comptime COMMAND_ARG_TYPE_SCORE_ARG: UInt32 = 12
"""The `Score Arg` argument type."""
comptime COMMAND_ARG_TYPE_SCORE_ARGS: UInt32 = 13
"""The `Score Args` argument type."""
comptime COMMAND_ARG_TYPE_SCORE_SELECT_PARAM: UInt32 = 14
"""The `Score Select Param` argument type."""
comptime COMMAND_ARG_TYPE_SCORE_SELECTOR: UInt32 = 15
"""The `Score Selector` argument type."""
comptime COMMAND_ARG_TYPE_TAG_SELECTOR: UInt32 = 16
"""The `Tag Selector` argument type."""
comptime COMMAND_ARG_TYPE_FILEPATH: UInt32 = 17
"""The `Filepath` argument type."""
comptime COMMAND_ARG_TYPE_FILE_PATH_VAL: UInt32 = 18
"""The `File Path Val` argument type."""
comptime COMMAND_ARG_TYPE_FILE_PATH_CONT: UInt32 = 19
"""The `File Path Cont` argument type."""
comptime COMMAND_ARG_TYPE_INT_RANGE_VAL: UInt32 = 20
"""The `Int Range Val` argument type."""
comptime COMMAND_ARG_TYPE_INT_RANGE_POST_VAL: UInt32 = 21
"""The `Int Range Post Val` argument type."""
comptime COMMAND_ARG_TYPE_INT_RANGE: UInt32 = 22
"""The `Int Range` argument type."""
comptime COMMAND_ARG_TYPE_INTEGER_RANGE: UInt32 = 23
"""The `Integer Range` argument type."""
comptime COMMAND_ARG_TYPE_RATIONAL_RANGE_VAL: UInt32 = 24
"""The `Rational Range Val` argument type."""
comptime COMMAND_ARG_TYPE_RATIONAL_RANGE_POST_VAL: UInt32 = 25
"""The `Rational Range Post Val` argument type."""
comptime COMMAND_ARG_TYPE_RATIONAL_RANGE: UInt32 = 26
"""The `Rational Range` argument type."""
comptime COMMAND_ARG_TYPE_RATIONAL_RANGE_FULL: UInt32 = 27
"""The `Rational Range Full` argument type."""
comptime COMMAND_ARG_TYPE_SELECTION_ARGS: UInt32 = 28
"""The `Selection Args` argument type."""
comptime COMMAND_ARG_TYPE_ARGS: UInt32 = 29
"""The `Args` argument type."""
comptime COMMAND_ARG_TYPE_ARG: UInt32 = 30
"""The `Arg` argument type."""
comptime COMMAND_ARG_TYPE_M_ARG: UInt32 = 31
"""The `M Arg` argument type."""
comptime COMMAND_ARG_TYPE_M_VALUE: UInt32 = 32
"""The `M Value` argument type."""
comptime COMMAND_ARG_TYPE_NAME: UInt32 = 33
"""The `Name` argument type."""
comptime COMMAND_ARG_TYPE_TYPE: UInt32 = 34
"""The `Type` argument type."""
comptime COMMAND_ARG_TYPE_FAMILY: UInt32 = 35
"""The `Family` argument type."""
comptime COMMAND_ARG_TYPE_PERMISSION: UInt32 = 36
"""The `Permission` argument type."""
comptime COMMAND_ARG_TYPE_PERMISSIONS: UInt32 = 37
"""The `Permissions` argument type."""
comptime COMMAND_ARG_TYPE_PERMISSION_SELECTOR: UInt32 = 38
"""The `Permission Selector` argument type."""
comptime COMMAND_ARG_TYPE_PERMISSION_ELEMENT: UInt32 = 39
"""The `Permission Element` argument type."""
comptime COMMAND_ARG_TYPE_PERMISSION_ELEMENTS: UInt32 = 40
"""The `Permission Elements` argument type."""
comptime COMMAND_ARG_TYPE_TAG: UInt32 = 41
"""The `Tag` argument type."""
comptime COMMAND_ARG_TYPE_HAS_ITEM_ELEMENT: UInt32 = 42
"""The `Has Item Element` argument type."""
comptime COMMAND_ARG_TYPE_HAS_ITEM_ELEMENTS: UInt32 = 43
"""The `Has Item Elements` argument type."""
comptime COMMAND_ARG_TYPE_HAS_ITEM: UInt32 = 44
"""The `Has Item` argument type."""
comptime COMMAND_ARG_TYPE_HAS_ITEMS: UInt32 = 45
"""The `Has Items` argument type."""
comptime COMMAND_ARG_TYPE_HAS_ITEM_SELECTOR: UInt32 = 46
"""The `Has Item Selector` argument type."""
comptime COMMAND_ARG_TYPE_EQUIPMENT_SLOTS: UInt32 = 47
"""The `Equipment Slots` argument type."""
comptime COMMAND_ARG_TYPE_PROPERTY_VALUE: UInt32 = 48
"""The `Property Value` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_PARAM_VALUE: UInt32 = 49
"""The `Has Property Param Value` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_PARAM_ENUM_VALUE: UInt32 = 50
"""The `Has Property Param Enum Value` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_ARG: UInt32 = 51
"""The `Has Property Arg` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_ARGS: UInt32 = 52
"""The `Has Property Args` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_ELEMENT: UInt32 = 53
"""The `Has Property Element` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_ELEMENTS: UInt32 = 54
"""The `Has Property Elements` argument type."""
comptime COMMAND_ARG_TYPE_HAS_PROPERTY_SELECTOR: UInt32 = 55
"""The `Has Property Selector` argument type."""
comptime COMMAND_ARG_TYPE_STRING: UInt32 = 56
"""The `String` argument type."""
comptime COMMAND_ARG_TYPE_ID_CONTINUATION: UInt32 = 57
"""The `ID Continuation` argument type."""
comptime COMMAND_ARG_TYPE_COORD_X_INT: UInt32 = 58
"""The `Coord X Int` argument type."""
comptime COMMAND_ARG_TYPE_COORD_Y_INT: UInt32 = 59
"""The `Coord Y Int` argument type."""
comptime COMMAND_ARG_TYPE_COORD_Z_INT: UInt32 = 60
"""The `Coord Z Int` argument type."""
comptime COMMAND_ARG_TYPE_COORD_X_FLOAT: UInt32 = 61
"""The `Coord X Float` argument type."""
comptime COMMAND_ARG_TYPE_COORD_Y_FLOAT: UInt32 = 62
"""The `Coord Y Float` argument type."""
comptime COMMAND_ARG_TYPE_COORD_Z_FLOAT: UInt32 = 63
"""The `Coord Z Float` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_POSITION: UInt32 = 64
"""The `Block Position` argument type."""
comptime COMMAND_ARG_TYPE_POSITION: UInt32 = 65
"""The `Position` argument type."""
comptime COMMAND_ARG_TYPE_MESSAGE_XP: UInt32 = 66
"""The `Message XP` argument type."""
comptime COMMAND_ARG_TYPE_MESSAGE: UInt32 = 67
"""The `Message` argument type."""
comptime COMMAND_ARG_TYPE_MESSAGE_ROOT: UInt32 = 68
"""The `Message Root` argument type."""
comptime COMMAND_ARG_TYPE_POST_SELECTOR: UInt32 = 69
"""The `Post Selector` argument type."""
comptime COMMAND_ARG_TYPE_RAW_TEXT: UInt32 = 70
"""The `Raw Text` argument type."""
comptime COMMAND_ARG_TYPE_TEXT_CONTINUATION: UInt32 = 71
"""The `Text Continuation` argument type."""
comptime COMMAND_ARG_TYPE_JSON_VALUE: UInt32 = 72
"""The `JSON Value` argument type."""
comptime COMMAND_ARG_TYPE_JSON_FIELD: UInt32 = 73
"""The `JSON Field` argument type."""
comptime COMMAND_ARG_TYPE_JSON: UInt32 = 74
"""The `JSON` argument type."""
comptime COMMAND_ARG_TYPE_JSON_OBJECT_FIELDS: UInt32 = 75
"""The `JSON Object Fields` argument type."""
comptime COMMAND_ARG_TYPE_JSON_OBJECT_CONT: UInt32 = 76
"""The `JSON Object Cont` argument type."""
comptime COMMAND_ARG_TYPE_JSON_ARRAY: UInt32 = 77
"""The `JSON Array` argument type."""
comptime COMMAND_ARG_TYPE_JSON_ARRAY_VALUES: UInt32 = 78
"""The `JSON Array Values` argument type."""
comptime COMMAND_ARG_TYPE_JSON_ARRAY_CONT: UInt32 = 79
"""The `JSON Array Cont` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_STATE: UInt32 = 80
"""The `Block State` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_STATE_KEY: UInt32 = 81
"""The `Block State Key` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_STATE_VALUE: UInt32 = 82
"""The `Block State Value` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_STATE_VALUES: UInt32 = 83
"""The `Block State Values` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_STATES: UInt32 = 84
"""The `Block States` argument type."""
comptime COMMAND_ARG_TYPE_BLOCK_STATES_CONT: UInt32 = 85
"""The `Block States Cont` argument type."""
comptime COMMAND_ARG_TYPE_CLOCK_TIME_MARKER: UInt32 = 86
"""The `Clock Time Marker` argument type."""
comptime COMMAND_ARG_TYPE_COMMAND: UInt32 = 87
"""The `Command` argument type."""
comptime COMMAND_ARG_TYPE_SLASH_COMMAND: UInt32 = 88
"""The `Slash Command` argument type."""
comptime COMMAND_ARG_TYPE_CODE_BUILDER_ARG: UInt32 = 89
"""The `Code Builder Arg` argument type."""
comptime COMMAND_ARG_TYPE_CODE_BUILDER_ARGS: UInt32 = 90
"""The `Code Builder Args` argument type."""
comptime COMMAND_ARG_TYPE_CODE_BUILDER_SELECT_PARAM: UInt32 = 91
"""The `Code Builder Select Param` argument type."""
comptime COMMAND_ARG_TYPE_CODE_BUILDER_SELECTOR: UInt32 = 92
"""The `Code Builder Selector` argument type."""
comptime COMMAND_ARG_TYPE_CHAINED_COMMAND: UInt32 = 0x8000000
"""The `Chained Command` argument type."""

comptime PARAM_OPTION_COLLAPSE_ENUM: UInt8 = 1
"""Collapses an enum parameter so its options only show as auto-completion."""
comptime PARAM_OPTION_HAS_SEMANTIC_CONSTRAINT: UInt8 = 2
"""Parameter option: Has Semantic Constraint."""
comptime PARAM_OPTION_AS_CHAINED_COMMAND: UInt8 = 4
"""Parameter option: As Chained Command."""

comptime COMMAND_ENUM_CONSTRAINT_CHEATS_ENABLED: UInt8 = 0
"""Enum constraint: Cheats Enabled."""
comptime COMMAND_ENUM_CONSTRAINT_OPERATOR_PERMISSIONS: UInt8 = 1
"""Enum constraint: Operator Permissions."""
comptime COMMAND_ENUM_CONSTRAINT_HOST_PERMISSIONS: UInt8 = 2
"""Enum constraint: Host Permissions."""

comptime COMMAND_ORIGIN_PLAYER: UInt32 = 0
"""A command issued by: Player."""
comptime COMMAND_ORIGIN_BLOCK: UInt32 = 1
"""A command issued by: Block."""
comptime COMMAND_ORIGIN_MINECART_BLOCK: UInt32 = 2
"""A command issued by: Minecart Block."""
comptime COMMAND_ORIGIN_DEV_CONSOLE: UInt32 = 3
"""A command issued by: Dev Console."""
comptime COMMAND_ORIGIN_TEST: UInt32 = 4
"""A command issued by: Test."""
comptime COMMAND_ORIGIN_AUTOMATION_PLAYER: UInt32 = 5
"""A command issued by: Automation Player."""
comptime COMMAND_ORIGIN_CLIENT_AUTOMATION: UInt32 = 6
"""A command issued by: Client Automation."""
comptime COMMAND_ORIGIN_DEDICATED_SERVER: UInt32 = 7
"""A command issued by: Dedicated Server."""
comptime COMMAND_ORIGIN_ENTITY: UInt32 = 8
"""A command issued by: Entity."""
comptime COMMAND_ORIGIN_VIRTUAL: UInt32 = 9
"""A command issued by: Virtual."""
comptime COMMAND_ORIGIN_GAME_ARGUMENT: UInt32 = 10
"""A command issued by: Game Argument."""
comptime COMMAND_ORIGIN_ENTITY_SERVER: UInt32 = 11
"""A command issued by: Entity Server."""
comptime COMMAND_ORIGIN_PRECOMPILED: UInt32 = 12
"""A command issued by: Precompiled."""
comptime COMMAND_ORIGIN_GAME_DIRECTOR_ENTITY_SERVER: UInt32 = 13
"""A command issued by: Game Director Entity Server."""
comptime COMMAND_ORIGIN_SCRIPT: UInt32 = 14
"""A command issued by: Script."""
comptime COMMAND_ORIGIN_EXECUTOR: UInt32 = 15
"""A command issued by: Executor."""


struct Command(Marshaler):
    """A command shown client-side in `/help` and auto-completion."""

    var name: String
    """The command name; the client may crash on uppercase letters."""
    var description: String
    """The description shown in `/help`."""
    var flags: UInt16
    """A combination of flags not currently known."""
    var permission_level: UInt8
    """One of the `COMMAND_PERMISSION_LEVEL_*` values."""
    var aliases_offset: UInt32
    """The offset of the `CommandEnum` holding the command's aliases."""
    var chained_subcommand_offsets: List[UInt32]
    """Offsets into the packet's `ChainedSubcommand` list."""
    var overloads: List[CommandOverload]
    """The ways in which the command may be executed."""

    def __init__(out self):
        """Creates an empty command."""
        self.name = String()
        self.description = String()
        self.flags = 0
        self.permission_level = 0
        self.aliases_offset = 0
        self.chained_subcommand_offsets = List[UInt32]()
        self.overloads = List[CommandOverload]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the command.

        The permission level travels as its lowercase name.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the permission level is unknown.
        """
        var permission = String(
            _command_permission_to_string(self.permission_level)
        )
        io.string(self.name)
        io.string(self.description)
        io.uint16(self.flags)
        io.string(permission)
        self.permission_level = _command_permission_from_string(permission)
        io.uint32(self.aliases_offset)
        uint32_slice(io, self.chained_subcommand_offsets)
        slice(io, self.overloads)


struct CommandOverload(Marshaler):
    """One usage of a command (like a function overload)."""

    var chaining: Bool
    """Whether the parameters use chained subcommands."""
    var parameters: List[CommandParameter]
    """The parameters of this overload."""

    def __init__(out self):
        """Creates an overload without parameters."""
        self.chaining = False
        self.parameters = List[CommandParameter]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the overload.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.chaining)
        slice(io, self.parameters)


struct CommandParameter(Marshaler):
    """A single parameter of a command overload."""

    var name: String
    """The name, shown as `<name: type>` in the usage."""
    var type: UInt32
    """A combination of `COMMAND_ARG_*` flags and a type or enum index."""
    var optional: Bool
    """Whether the parameter may be omitted."""
    var options: UInt8
    """A combination of `PARAM_OPTION_*` values."""

    def __init__(out self):
        """Creates an empty parameter."""
        self.name = String()
        self.type = 0
        self.optional = False
        self.options = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the parameter.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        io.uint32(self.type)
        io.bool(self.optional)
        io.uint8(self.options)


struct CommandEnum(Copyable, Defaultable):
    """A fixed enum in a command usage.

    It has no layout of its own: `CommandEnumContext` marshals it, because
    its value indices refer to the packet's enum value list.
    """

    var type: String
    """The enum's type name, shown in the usage."""
    var value_indices: List[UInt32]
    """Indices into the `AvailableCommands` packet's enum values."""

    def __init__(out self):
        """Creates an empty enum."""
        self.type = String()
        self.value_indices = List[UInt32]()


struct CommandEnumContext(Copyable):
    """Context for encoding command enums (gophertunnel `CommandEnumContext`).

    Older protocols sized each value index by the number of enum values
    (`uint8` up to 255, `uint16` up to 65535, else `uint32`). Protocol 2225
    always writes a `uint32`, so the indices are independent of
    `enum_values`; the context is kept so `AvailableCommands` reads like Go.
    """

    var enum_values: List[String]
    """The `AvailableCommands` packet's enum values."""

    def __init__(out self, var enum_values: List[String]):
        """Creates a context over the packet's enum values.

        Args:
            enum_values: The enum values of the packet.
        """
        self.enum_values = enum_values^

    def marshal[I: IO](self, mut io: I, mut x: CommandEnum) raises:
        """Reads or writes one command enum.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.
            x: The enum.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(x.type)
        uint32_slice(io, x.value_indices)


def command_enums[
    I: IO
](mut io: I, mut x: List[CommandEnum], enum_values: List[String]) raises:
    """Marshals a varuint32-prefixed list of command enums.

    This is Go's `FuncIOSlice(io, &pk.Enums, CommandEnumContext{...}.Marshal)`
    from the `AvailableCommands` packet.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The enums.
        enum_values: The packet's enum values.

    Raises:
        If the input is malformed or a value is invalid.
    """
    var ctx = CommandEnumContext(enum_values.copy())
    var count = UInt32(len(x))
    io.varuint32(count)
    if io.reads():
        io.slice_length(count, MAX_SLICE_LENGTH)
        x = List[CommandEnum](capacity=Int(count))
        for _ in range(Int(count)):
            var e = CommandEnum()
            ctx.marshal(io, e)
            x.append(e^)
        return
    for i in range(len(x)):
        ctx.marshal(io, x[i])


struct ChainedSubcommand(Marshaler):
    """A subcommand followed by a chained command, as in `/execute`."""

    var name: String
    """The name, shown as a regular subcommand enum."""
    var values: List[ChainedSubcommandValue]
    """The index and parameter type of each chained subcommand value."""

    def __init__(out self):
        """Creates an empty chained subcommand."""
        self.name = String()
        self.values = List[ChainedSubcommandValue]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the chained subcommand.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        slice(io, self.values)


struct ChainedSubcommandValue(Marshaler):
    """The value of a chained subcommand argument."""

    var index: UInt32
    """The index into the packet's chained subcommand values."""
    var value: UInt32
    """The basic argument type, without the special flags."""

    def __init__(out self):
        """Creates a zero value."""
        self.index = 0
        self.value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.index)
        io.varuint32(self.value)


struct DynamicEnum(Marshaler):
    """An enum whose options can change without a new `AvailableCommands`."""

    var type: String
    """The enum's type name, shown in the usage."""
    var values: List[String]
    """The possible options."""

    def __init__(out self):
        """Creates an empty enum."""
        self.type = String()
        self.values = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the enum.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.type)
        string_slice(io, self.values)


struct CommandEnumConstraint(Marshaler):
    """Limits when an enum value may be used (cheats, permissions)."""

    var enum_value_index: UInt32
    """The enum value this constraint applies to."""
    var enum_index: UInt32
    """The enum this constraint applies to."""
    var constraints: List[UInt8]
    """`COMMAND_ENUM_CONSTRAINT_*` values."""

    def __init__(out self):
        """Creates an empty constraint."""
        self.enum_value_index = 0
        self.enum_index = 0
        self.constraints = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the constraint.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.enum_value_index)
        io.uint32(self.enum_index)
        io.byte_slice(self.constraints)


struct CommandOrigin(Copyable, Defaultable):
    """Identifies where a command request came from.

    A `CommandOutput` should echo the `CommandOrigin` of its request.
    """

    var origin: UInt32
    """One of the `COMMAND_ORIGIN_*` values."""
    var uuid: UUID
    """A unique identifier for every instantiation of a command."""
    var request_id: String
    """The request ID, mostly used by websocket servers."""
    var player_unique_id: Int64
    """The player's unique entity ID; 0 seems to work."""

    def __init__(out self):
        """Creates a player origin with zero fields."""
        self.origin = COMMAND_ORIGIN_PLAYER
        self.uuid = UUID()
        self.request_id = String()
        self.player_unique_id = 0


def command_origin_data[I: IO](mut io: I, mut x: CommandOrigin) raises:
    """Marshals a command origin (gophertunnel `CommandOriginData`).

    The origin travels as its name; the player unique ID is a fixed `int64`.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The origin.

    Raises:
        If the input is malformed or the origin is unknown.
    """
    var origin = String(_command_origin_to_string(x.origin))
    io.string(origin)
    uuid(io, x.uuid)
    io.string(x.request_id)
    io.int64(x.player_unique_id)
    x.origin = _command_origin_from_string(origin)


struct CommandOutputMessage(Marshaler):
    """One message of a command's output."""

    var success: Bool
    """Whether the command succeeded (white text) or failed (red text)."""
    var message: String
    """The message, or a translation key such as `commands.tp.success`."""
    var parameters: List[String]
    """Translation parameters for built-in messages."""

    def __init__(out self):
        """Creates an empty message."""
        self.success = False
        self.message = String()
        self.parameters = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the message.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.message)
        io.bool(self.success)
        string_slice(io, self.parameters)


comptime _COMMAND_ORIGIN_NAMES: List[StaticString] = [
    "player",
    "commandblock",
    "minecartcommandblock",
    "devconsole",
    "test",
    "automationplayer",
    "clientautomation",
    "dedicatedserver",
    "entity",
    "virtual",
    "gameargument",
    "entityserver",
    "precompiled",
    "gamedirectorentityserver",
    "scripting",
    "executecontext",
]

comptime _COMMAND_PERMISSION_NAMES: List[StaticString] = [
    "any",
    "gamedirectors",
    "admin",
    "host",
    "owner",
    "internal",
]


def _command_origin_to_string(x: UInt32) -> StaticString:
    ref names = materialize[_COMMAND_ORIGIN_NAMES]()
    if Int(x) < len(names):
        return names[Int(x)]
    return "unknown"


def _command_origin_from_string(s: String) raises -> UInt32:
    ref names = materialize[_COMMAND_ORIGIN_NAMES]()
    for i in range(len(names)):
        if s == names[i]:
            return UInt32(i)
    invalid_value(s, "origin", "unknown origin")
    return 0


def _command_permission_to_string(x: UInt8) -> StaticString:
    ref names = materialize[_COMMAND_PERMISSION_NAMES]()
    if Int(x) < len(names):
        return names[Int(x)]
    return "unknown"


def _command_permission_from_string(s: String) raises -> UInt8:
    ref names = materialize[_COMMAND_PERMISSION_NAMES]()
    for i in range(len(names)):
        if s == names[i]:
            return UInt8(i)
    invalid_value(s, "permissionLevel", "unknown permission level")
    return 0
