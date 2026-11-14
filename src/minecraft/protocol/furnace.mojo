"""Furnace UI options (gophertunnel `protocol/furnace.go`)."""

from .io import IO, Marshaler

comptime FURNACE_LAYOUT_NONE: Int32 = 0
"""No furnace layout."""
comptime FURNACE_LAYOUT_INVENTORY_ONLY: Int32 = 1
"""Only the inventory is shown."""
comptime FURNACE_LAYOUT_DEFAULT: Int32 = 2
"""The default furnace layout."""

comptime FURNACE_LEFT_TAB_NONE: Int32 = 0
"""No left tab is selected."""
comptime FURNACE_LEFT_TAB_RECIPE_FOOD: Int32 = 1
"""The food recipes tab."""
comptime FURNACE_LEFT_TAB_RECIPE_ITEMS: Int32 = 2
"""The item recipes tab."""
comptime FURNACE_LEFT_TAB_RECIPE_BLOCKS: Int32 = 3
"""The block recipes tab."""
comptime FURNACE_LEFT_TAB_RECIPE_SEARCH: Int32 = 4
"""The recipe search tab."""
comptime FURNACE_LEFT_TAB_INVENTORY: Int32 = 5
"""The inventory tab."""


struct FurnaceOptions(Marshaler):
    """The options a player selected in a furnace-like container's UI."""

    var left_furnace_tab: Int32
    """The selected left tab, one of the `FURNACE_LEFT_TAB_*` constants."""
    var filtering: Bool
    """Whether only unlocked recipes are shown."""
    var layout: Int32
    """The UI layout, one of the `FURNACE_LAYOUT_*` constants."""

    def __init__(out self):
        """Creates options with nothing selected."""
        self.left_furnace_tab = FURNACE_LEFT_TAB_NONE
        self.filtering = False
        self.layout = FURNACE_LAYOUT_NONE

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the options."""
        io.varint32(self.left_furnace_tab)
        io.bool(self.filtering)
        io.varint32(self.layout)
