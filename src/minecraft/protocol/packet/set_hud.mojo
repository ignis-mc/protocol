"""The `SetHud` packet (gophertunnel `packet/set_hud.go`)."""

from ..io import IO, varint32_slice
from .id import ID_SET_HUD
from .packet import Packet

comptime HUD_ELEMENT_PAPER_DOLL: Int32 = 0
"""The paper doll HUD element."""
comptime HUD_ELEMENT_ARMOUR: Int32 = 1
"""The armour HUD element."""
comptime HUD_ELEMENT_TOOL_TIPS: Int32 = 2
"""The tool tips HUD element."""
comptime HUD_ELEMENT_TOUCH_CONTROLS: Int32 = 3
"""The touch controls HUD element."""
comptime HUD_ELEMENT_CROSSHAIR: Int32 = 4
"""The crosshair HUD element."""
comptime HUD_ELEMENT_HOT_BAR: Int32 = 5
"""The hot bar HUD element."""
comptime HUD_ELEMENT_HEALTH: Int32 = 6
"""The health HUD element."""
comptime HUD_ELEMENT_PROGRESS_BAR: Int32 = 7
"""The progress bar HUD element."""
comptime HUD_ELEMENT_HUNGER: Int32 = 8
"""The hunger HUD element."""
comptime HUD_ELEMENT_AIR_BUBBLES: Int32 = 9
"""The air bubbles HUD element."""
comptime HUD_ELEMENT_HORSE_HEALTH: Int32 = 10
"""The horse health HUD element."""
comptime HUD_ELEMENT_STATUS_EFFECTS: Int32 = 11
"""The status effects HUD element."""
comptime HUD_ELEMENT_ITEM_TEXT: Int32 = 12
"""The item text HUD element."""

comptime HUD_VISIBILITY_HIDE: Int32 = 0
"""Hide the elements."""
comptime HUD_VISIBILITY_RESET: Int32 = 1
"""Reset the elements to their default visibility."""


struct SetHud(Packet):
    """Sent by the server to show or hide HUD elements."""

    comptime ID: UInt32 = ID_SET_HUD
    """The packet ID."""
    var elements: List[Int32]
    """The `HUD_ELEMENT_*` values to update."""
    var visibility: Int32
    """One of the `HUD_VISIBILITY_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.elements = List[Int32]()
        self.visibility = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        varint32_slice(io, self.elements)
        io.varint32(self.visibility)
