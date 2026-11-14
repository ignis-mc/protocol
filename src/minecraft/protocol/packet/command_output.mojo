"""The `CommandOutput` packet (gophertunnel `packet/command_output.go`)."""

from ..command import CommandOrigin, CommandOutputMessage, command_origin_data
from ..io import IO, invalid_value, optional_string, slice
from .id import ID_COMMAND_OUTPUT
from .packet import Packet

comptime COMMAND_OUTPUT_TYPE_NONE: UInt8 = 0
"""Go `CommandOutputTypeNone`."""
comptime COMMAND_OUTPUT_TYPE_LAST_OUTPUT: UInt8 = 1
"""Go `CommandOutputTypeLastOutput`."""
comptime COMMAND_OUTPUT_TYPE_SILENT: UInt8 = 2
"""Go `CommandOutputTypeSilent`."""
comptime COMMAND_OUTPUT_TYPE_ALL_OUTPUT: UInt8 = 3
"""Go `CommandOutputTypeAllOutput`."""
comptime COMMAND_OUTPUT_TYPE_DATA_SET: UInt8 = 4
"""Go `CommandOutputTypeDataSet`."""


struct CommandOutput(Packet):
    """Sent by the server with command output, relayed to its origin."""

    comptime ID: UInt32 = ID_COMMAND_OUTPUT
    """The packet ID."""
    var command_origin: CommandOrigin
    """The origin of the command request."""
    var output_type: UInt8
    """One of the `COMMAND_OUTPUT_TYPE_*` values."""
    var success_count: UInt32
    """How often the command succeeded."""
    var output_messages: List[CommandOutputMessage]
    """The output messages."""
    var data_set: Optional[String]
    """Unknown data."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.command_origin = CommandOrigin()
        self.output_type = 0
        self.success_count = 0
        self.output_messages = List[CommandOutputMessage]()
        self.data_set = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        command_origin_data(io, self.command_origin)
        var output_type = String(
            _command_output_type_to_string(self.output_type)
        )
        io.string(output_type)
        self.output_type = _command_output_type_from_string(output_type)
        io.uint32(self.success_count)
        slice(io, self.output_messages)
        optional_string(io, self.data_set)


def _command_output_type_to_string(x: UInt8) -> StaticString:
    if x == COMMAND_OUTPUT_TYPE_NONE:
        return "none"
    if x == COMMAND_OUTPUT_TYPE_LAST_OUTPUT:
        return "lastoutput"
    if x == COMMAND_OUTPUT_TYPE_SILENT:
        return "silent"
    if x == COMMAND_OUTPUT_TYPE_ALL_OUTPUT:
        return "alloutput"
    if x == COMMAND_OUTPUT_TYPE_DATA_SET:
        return "dataset"
    return "unknown"


def _command_output_type_from_string(s: String) raises -> UInt8:
    if s == "none":
        return COMMAND_OUTPUT_TYPE_NONE
    if s == "lastoutput":
        return COMMAND_OUTPUT_TYPE_LAST_OUTPUT
    if s == "silent":
        return COMMAND_OUTPUT_TYPE_SILENT
    if s == "alloutput":
        return COMMAND_OUTPUT_TYPE_ALL_OUTPUT
    if s == "dataset":
        return COMMAND_OUTPUT_TYPE_DATA_SET
    invalid_value(s, "outputType", "unknown type")
    return 0
