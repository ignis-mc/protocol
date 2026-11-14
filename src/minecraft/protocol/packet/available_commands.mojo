"""The `AvailableCommands` packet (gophertunnel `packet/available_commands.go`)."""

from ..command import (
    ChainedSubcommand,
    Command,
    CommandEnum,
    CommandEnumConstraint,
    DynamicEnum,
    command_enums,
)
from ..io import IO, slice, string_slice
from .id import ID_AVAILABLE_COMMANDS
from .packet import Packet


struct AvailableCommands(Packet):
    """Sent by the server with every command the player may use."""

    comptime ID: UInt32 = ID_AVAILABLE_COMMANDS
    """The packet ID."""
    var enum_values: List[String]
    """Every enum value; enums index into it."""
    var chained_subcommand_values: List[String]
    """Every chained subcommand name."""
    var suffixes: List[String]
    """Every parameter suffix."""
    var enums: List[CommandEnum]
    """The fixed command enums."""
    var chained_subcommands: List[ChainedSubcommand]
    """The subcommands followed by a chained command."""
    var commands: List[Command]
    """The commands; they replace any sent before."""
    var dynamic_enums: List[DynamicEnum]
    """Enums that may change at runtime."""
    var constraints: List[CommandEnumConstraint]
    """Constraints on enum options."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.enum_values = List[String]()
        self.chained_subcommand_values = List[String]()
        self.suffixes = List[String]()
        self.enums = List[CommandEnum]()
        self.chained_subcommands = List[ChainedSubcommand]()
        self.commands = List[Command]()
        self.dynamic_enums = List[DynamicEnum]()
        self.constraints = List[CommandEnumConstraint]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        string_slice(io, self.enum_values)
        string_slice(io, self.chained_subcommand_values)
        string_slice(io, self.suffixes)
        command_enums(io, self.enums, self.enum_values)
        slice(io, self.chained_subcommands)
        slice(io, self.commands)
        slice(io, self.dynamic_enums)
        slice(io, self.constraints)
