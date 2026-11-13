"""The `SetPlayerFurnaceOptions` packet.

This is gophertunnel `packet/set_player_furnace_options.go`.
"""

from ..furnace import FurnaceOptions
from ..io import IO
from .id import ID_SET_PLAYER_FURNACE_OPTIONS
from .packet import Packet

comptime FURNACE_TYPE_NONE: UInt8 = 0
"""No furnace."""
comptime FURNACE_TYPE_FURNACE: UInt8 = 1
"""A furnace."""
comptime FURNACE_TYPE_BLAST_FURNACE: UInt8 = 2
"""A blast furnace."""
comptime FURNACE_TYPE_SMOKER: UInt8 = 3
"""A smoker."""


struct SetPlayerFurnaceOptions(Packet):
    """Updates the options a player selected in a furnace-like UI."""

    comptime ID: UInt32 = ID_SET_PLAYER_FURNACE_OPTIONS
    """The packet ID."""
    var furnace_type: UInt8
    """One of the `FURNACE_TYPE_*` values."""
    var furnace_options: FurnaceOptions
    """The selected options."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.furnace_type = 0
        self.furnace_options = FurnaceOptions()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.furnace_type)
        self.furnace_options.marshal(io)
