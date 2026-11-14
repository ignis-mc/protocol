"""Enchantment table options (gophertunnel `protocol/enchant.go`)."""

from .io import IO, Marshaler, slice


struct EnchantmentOption(Marshaler):
    """One option of the enchantment table for an item."""

    var cost: UInt8
    """The XP levels the option costs."""
    var enchantments: ItemEnchantments
    """The enchantments applied when the option is chosen."""
    var name: String
    """A meaningless name shown in the Standard Galactic Alphabet."""
    var recipe_network_id: UInt32
    """A network ID, unique among recipes, the client crafts with."""

    def __init__(out self):
        """Creates an empty option."""
        self.cost = 0
        self.enchantments = ItemEnchantments()
        self.name = String()
        self.recipe_network_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the option."""
        io.uint8(self.cost)
        self.enchantments.marshal(io)
        io.string(self.name)
        io.varuint32(self.recipe_network_id)


struct ItemEnchantments(Marshaler):
    """The enchantments one enchantment table button applies."""

    var slot: Int32
    """0, 1 or 2; its use is not clear."""
    var enchantments: Array[List[EnchantmentInstance], 3]
    """Three lists of enchantments, one per activation type."""

    def __init__(out self):
        """Creates three empty lists."""
        self.slot = 0
        self.enchantments = Array[List[EnchantmentInstance], 3](
            fill=List[EnchantmentInstance]()
        )

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the enchantments."""
        io.int32(self.slot)
        for i in range(3):
            slice(io, self.enchantments[i])


@fieldwise_init
struct EnchantmentInstance(Marshaler):
    """An enchantment type and level."""

    var type: UInt8
    """The enchantment type."""
    var level: UInt8
    """The enchantment level."""

    def __init__(out self):
        """Creates enchantment 0 at level 0."""
        self.type = 0
        self.level = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the enchantment."""
        io.uint8(self.type)
        io.uint8(self.level)
