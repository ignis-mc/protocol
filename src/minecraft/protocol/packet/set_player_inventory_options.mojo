"""The `SetPlayerInventoryOptions` packet.

This is gophertunnel `packet/set_player_inventory_options.go`.
"""

from ..io import IO
from .id import ID_SET_PLAYER_INVENTORY_OPTIONS
from .packet import Packet

comptime INVENTORY_LAYOUT_NONE: Int32 = 0
"""No layout."""
comptime INVENTORY_LAYOUT_INVENTORY_ONLY: Int32 = 1
"""The inventory only."""
comptime INVENTORY_LAYOUT_DEFAULT: Int32 = 2
"""The default layout."""
comptime INVENTORY_LAYOUT_RECIPE_BOOK_ONLY: Int32 = 3
"""The recipe book only."""

comptime INVENTORY_LEFT_TAB_NONE: Int32 = 0
"""No tab."""
comptime INVENTORY_LEFT_TAB_CONSTRUCTION: Int32 = 1
"""The construction tab."""
comptime INVENTORY_LEFT_TAB_EQUIPMENT: Int32 = 2
"""The equipment tab."""
comptime INVENTORY_LEFT_TAB_ITEMS: Int32 = 3
"""The items tab."""
comptime INVENTORY_LEFT_TAB_NATURE: Int32 = 4
"""The nature tab."""
comptime INVENTORY_LEFT_TAB_SEARCH: Int32 = 5
"""The search tab."""
comptime INVENTORY_LEFT_TAB_SURVIVAL: Int32 = 6
"""The survival tab."""

comptime INVENTORY_RIGHT_TAB_NONE: Int32 = 0
"""No tab."""
comptime INVENTORY_RIGHT_TAB_FULL_SCREEN: Int32 = 1
"""The full-screen tab."""
comptime INVENTORY_RIGHT_TAB_CRAFTING: Int32 = 2
"""The crafting tab."""
comptime INVENTORY_RIGHT_TAB_ARMOUR: Int32 = 3
"""The armour tab."""


struct SetPlayerInventoryOptions(Packet):
    """Updates the inventory options of a player."""

    comptime ID: UInt32 = ID_SET_PLAYER_INVENTORY_OPTIONS
    """The packet ID."""
    var left_inventory_tab: Int32
    """One of the `INVENTORY_LEFT_TAB_*` values."""
    var right_inventory_tab: Int32
    """One of the `INVENTORY_RIGHT_TAB_*` values."""
    var filtering: Bool
    """Whether the recipe book shows only craftable recipes."""
    var inventory_layout: Int32
    """One of the `INVENTORY_LAYOUT_*` values."""
    var crafting_layout: Int32
    """One of the `INVENTORY_LAYOUT_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.left_inventory_tab = 0
        self.right_inventory_tab = 0
        self.filtering = False
        self.inventory_layout = 0
        self.crafting_layout = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.left_inventory_tab)
        io.varint32(self.right_inventory_tab)
        io.bool(self.filtering)
        io.varint32(self.inventory_layout)
        io.varint32(self.crafting_layout)
