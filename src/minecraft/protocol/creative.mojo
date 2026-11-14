"""Creative inventory groups and items (gophertunnel `protocol/creative.go`)."""

from .io import IO, Marshaler
from .item import ItemStack, item

comptime CREATIVE_CATEGORY_ALL: UInt8 = 0
"""Every creative category."""
comptime CREATIVE_CATEGORY_CONSTRUCTION: UInt8 = 1
"""The construction category."""
comptime CREATIVE_CATEGORY_NATURE: UInt8 = 2
"""The nature category."""
comptime CREATIVE_CATEGORY_EQUIPMENT: UInt8 = 3
"""The equipment category."""
comptime CREATIVE_CATEGORY_ITEMS: UInt8 = 4
"""The items category."""
comptime CREATIVE_CATEGORY_ITEM_COMMAND_ONLY: UInt8 = 5
"""Items only obtainable with commands."""
comptime CREATIVE_CATEGORY_UNDEFINED: UInt8 = 6
"""An undefined category."""


struct CreativeGroup(Marshaler):
    """A group of items in the creative inventory."""

    var category: UInt8
    """The category, one of the `CREATIVE_CATEGORY_*` constants."""
    var name: String
    """The locale name of the group, such as `itemGroup.name.planks`."""
    var icon: ItemStack
    """The item shown for the group."""

    def __init__(out self):
        """Creates an empty group."""
        self.category = CREATIVE_CATEGORY_ALL
        self.name = String()
        self.icon = ItemStack()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the group."""
        io.uint8(self.category)
        io.string(self.name)
        item(io, self.icon)


struct CreativeItem(Marshaler):
    """An item in the creative inventory."""

    var creative_item_network_id: UInt32
    """A unique ID of the creative item."""
    var item: ItemStack
    """The item."""
    var group_index: UInt32
    """The index of the item's group in the `CreativeContent` packet."""

    def __init__(out self):
        """Creates an empty creative item."""
        self.creative_item_network_id = 0
        self.item = ItemStack()
        self.group_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the creative item."""
        io.varuint32(self.creative_item_network_id)
        item(io, self.item)
        io.varuint32(self.group_index)
