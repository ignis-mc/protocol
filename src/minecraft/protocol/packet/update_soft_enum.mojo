"""The `UpdateSoftEnum` packet (gophertunnel `packet/update_soft_enum.go`)."""

from ..io import IO, string_slice
from .id import ID_UPDATE_SOFT_ENUM
from .packet import Packet

comptime SOFT_ENUM_ACTION_ADD: UInt8 = 0
"""Add the options."""
comptime SOFT_ENUM_ACTION_REMOVE: UInt8 = 1
"""Remove the options."""
comptime SOFT_ENUM_ACTION_SET: UInt8 = 2
"""Replace every option."""


struct UpdateSoftEnum(Packet):
    """Sent by the server to update a soft (dynamic) command enum."""

    comptime ID: UInt32 = ID_UPDATE_SOFT_ENUM
    """The packet ID."""
    var enum_type: String
    """The name of the enum."""
    var options: List[String]
    """The options to add, remove or set."""
    var action_type: UInt8
    """One of the `SOFT_ENUM_ACTION_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.enum_type = String()
        self.options = List[String]()
        self.action_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.enum_type)
        string_slice(io, self.options)
        io.uint8(self.action_type)
