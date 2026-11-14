"""The `GUIDataPickItem` packet (gophertunnel `packet/gui_data_pick_item.go`)."""

from ..io import IO
from .id import ID_GUI_DATA_PICK_ITEM
from .packet import Packet


struct GUIDataPickItem(Packet):
    """Sent by the server to make the client 'select' a hot bar slot."""

    comptime ID: UInt32 = ID_GUI_DATA_PICK_ITEM
    """The packet ID."""
    var item_name: String
    """The name of the item that shows up in the top part of the popup that
    shows up when selecting an item.
    """
    var item_effects: String
    """The line under the ItemName, where the effects of the item are usually
    situated.
    """
    var hot_bar_slot: Int32
    """The hot bar slot to be selected/picked."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.item_name = String()
        self.item_effects = String()
        self.hot_bar_slot = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.item_name)
        io.string(self.item_effects)
        io.int32(self.hot_bar_slot)
