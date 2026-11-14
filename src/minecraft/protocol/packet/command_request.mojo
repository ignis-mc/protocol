"""The `CommandRequest` packet (gophertunnel `packet/command_request.go`)."""

from ..command import CommandOrigin, command_origin_data
from ..io import IO
from .id import ID_COMMAND_REQUEST
from .packet import Packet


struct CommandRequest(Packet):
    """Sent by the client to request the execution of a server-side command."""

    comptime ID: UInt32 = ID_COMMAND_REQUEST
    """The packet ID."""
    var command_line: String
    """The raw entered command line."""
    var command_origin: CommandOrigin
    """The data specifying the origin of the command."""
    var internal: Bool
    """Whether the request is internal; its use is unknown and `False` works."""
    var version: String
    """The version of the command that is being executed."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.command_line = String()
        self.command_origin = CommandOrigin()
        self.internal = False
        self.version = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.command_line)
        command_origin_data(io, self.command_origin)
        io.bool(self.internal)
        io.string(self.version)
