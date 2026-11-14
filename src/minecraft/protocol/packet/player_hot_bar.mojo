"""The `PlayerHotBar` packet (gophertunnel `packet/player_hot_bar.go`)."""

from ..io import IO
from .id import ID_PLAYER_HOT_BAR
from .packet import Packet


struct PlayerHotBar(Packet):
    """Sent by the server about the hot bar; its current use is unclear."""

    comptime ID: UInt32 = ID_PLAYER_HOT_BAR
    """The packet ID."""
    var selected_hot_bar_slot: UInt32
    """The selected hot bar slot."""
    var window_id: UInt8
    """The window ID."""
    var select_hot_bar_slot: Bool
    """Whether to select the slot."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.selected_hot_bar_slot = 0
        self.window_id = 0
        self.select_hot_bar_slot = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.selected_hot_bar_slot)
        io.uint8(self.window_id)
        io.bool(self.select_hot_bar_slot)
