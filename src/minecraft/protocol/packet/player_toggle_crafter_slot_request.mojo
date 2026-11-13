"""The `PlayerToggleCrafterSlotRequest` packet (gophertunnel `packet/player_toggle_crafter_slot_request.go`).
"""

from ..io import IO
from .id import ID_PLAYER_TOGGLE_CRAFTER_SLOT_REQUEST
from .packet import Packet


struct PlayerToggleCrafterSlotRequest(Packet):
    """Sent by the client when it toggles a slot of a Crafter."""

    comptime ID: UInt32 = ID_PLAYER_TOGGLE_CRAFTER_SLOT_REQUEST
    """The packet ID."""
    var pos_x: Int32
    """The X position of the Crafter."""
    var pos_y: Int32
    """The Y position of the Crafter."""
    var pos_z: Int32
    """The Z position of the Crafter."""
    var slot: UInt8
    """The index of the toggled slot, 0 to 8."""
    var disabled: Bool
    """Whether the slot is now disabled."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.pos_x = 0
        self.pos_y = 0
        self.pos_z = 0
        self.slot = 0
        self.disabled = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int32(self.pos_x)
        io.int32(self.pos_y)
        io.int32(self.pos_z)
        io.uint8(self.slot)
        io.bool(self.disabled)
