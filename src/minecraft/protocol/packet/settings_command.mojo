"""The `SettingsCommand` packet (gophertunnel `packet/settings_command.go`)."""

from ..io import IO
from .id import ID_SETTINGS_COMMAND
from .packet import Packet


struct SettingsCommand(Packet):
    """Sent by the client when a settings change issues a command."""

    comptime ID: UInt32 = ID_SETTINGS_COMMAND
    """The packet ID."""
    var command_line: String
    """The full command line."""
    var suppress_output: Bool
    """Whether the command output is hidden."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.command_line = String()
        self.suppress_output = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.command_line)
        io.bool(self.suppress_output)
