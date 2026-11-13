"""The `SimulationType` packet (gophertunnel `packet/simulation_type.go`)."""

from ..io import IO
from .id import ID_SIMULATION_TYPE
from .packet import Packet

comptime SIMULATION_TYPE_GAME: UInt8 = 0
"""A normal game."""
comptime SIMULATION_TYPE_EDITOR: UInt8 = 1
"""Editor mode."""
comptime SIMULATION_TYPE_TEST: UInt8 = 2
"""A test."""
comptime SIMULATION_TYPE_INVALID: UInt8 = 3
"""An invalid simulation type."""


struct SimulationType(Packet):
    """Sent by the server with the simulation type (in progress)."""

    comptime ID: UInt32 = ID_SIMULATION_TYPE
    """The packet ID."""
    var simulation_type: UInt8
    """One of the `SIMULATION_TYPE_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.simulation_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.simulation_type)
