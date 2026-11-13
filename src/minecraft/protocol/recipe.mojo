"""Crafting, smithing and potion recipes (gophertunnel `protocol/recipe.go`).

gophertunnel v1.63.0 sends each recipe kind in its own typed list of the
`CraftingData` packet, so recipes have no type IDs and no shared interface.
The Go types that only embed another recipe (`UserDataShapelessRecipe`,
`ShapelessChemistryRecipe`, `ShapedChemistryRecipe`) are aliases here.
"""

from .io import (
    IO,
    Marshaler,
    invalid_value,
    optional_marshaler,
    slice,
    uuid,
)
from .item import ItemStack, item
from .item_descriptor import ItemDescriptorCount, item_descriptor_count
from .uuid import UUID

comptime RECIPE_UNLOCK_CONTEXT_NONE: Int32 = 0
"""The recipe is unlocked by having its ingredients."""
comptime RECIPE_UNLOCK_CONTEXT_ALWAYS_UNLOCKED: Int32 = 1
"""The recipe is always unlocked."""
comptime RECIPE_UNLOCK_CONTEXT_PLAYER_IN_WATER: Int32 = 2
"""The recipe is unlocked when the player is in water."""
comptime RECIPE_UNLOCK_CONTEXT_PLAYER_HAS_MANY_ITEMS: Int32 = 3
"""The recipe is unlocked when the player has many items."""


@fieldwise_init
struct PotionContainerChangeRecipe(Marshaler):
    """A recipe that turns a potion into another kind of potion container."""

    var input_item_id: Int32
    """The item ID of the potion put in."""
    var reagent_item_id: Int32
    """The item ID of the item added to change the container."""
    var output_item_id: Int32
    """The item ID of the resulting potion."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.input_item_id = 0
        self.reagent_item_id = 0
        self.output_item_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.input_item_id)
        io.varint32(self.reagent_item_id)
        io.varint32(self.output_item_id)


@fieldwise_init
struct PotionRecipe(Marshaler):
    """A potion brewing recipe for the brewing stand."""

    var input_potion_id: Int32
    """The item ID of the potion put in."""
    var input_potion_metadata: Int32
    """The type of the potion put in."""
    var reagent_item_id: Int32
    """The item ID of the reagent."""
    var reagent_item_metadata: Int32
    """The metadata value of the reagent."""
    var output_potion_id: Int32
    """The item ID of the brewed potion."""
    var output_potion_metadata: Int32
    """The type of the brewed potion."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.input_potion_id = 0
        self.input_potion_metadata = 0
        self.reagent_item_id = 0
        self.reagent_item_metadata = 0
        self.output_potion_id = 0
        self.output_potion_metadata = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.input_potion_id)
        io.varint32(self.input_potion_metadata)
        io.varint32(self.reagent_item_id)
        io.varint32(self.reagent_item_metadata)
        io.varint32(self.output_potion_id)
        io.varint32(self.output_potion_metadata)


struct RecipeUnlockRequirement(Marshaler):
    """What unlocks a shaped or shapeless recipe."""

    var context: Int32
    """One of the `RECIPE_UNLOCK_CONTEXT_*` constants."""
    var ingredients: List[ItemDescriptorCount]
    """The ingredients that unlock the recipe; only sent for context none."""

    def __init__(out self):
        """Creates a requirement with context none and no ingredients."""
        self.context = RECIPE_UNLOCK_CONTEXT_NONE
        self.ingredients = List[ItemDescriptorCount]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the requirement.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.context)
        var present = self.context == RECIPE_UNLOCK_CONTEXT_NONE
        io.bool(present)
        if present:
            slice(io, self.ingredients)


struct ShapelessRecipe(Marshaler):
    """A recipe whose ingredients may be placed in any shape."""

    var recipe_id: String
    """A unique ID of the recipe."""
    var input: List[ItemDescriptorCount]
    """The items required to craft the output."""
    var output: List[ItemStack]
    """The items created by the recipe."""
    var uuid: UUID
    """A UUID identifying the recipe; may be empty."""
    var block: String
    """The block required, without `minecraft:`, such as `crafting_table`."""
    var priority: Int32
    """The recipe's priority."""
    var unlock_requirement: Optional[RecipeUnlockRequirement]
    """What unlocks the recipe, if anything."""
    var recipe_network_id: UInt32
    """A unique, non-zero network ID of the recipe."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.recipe_id = String()
        self.input = List[ItemDescriptorCount]()
        self.output = List[ItemStack]()
        self.uuid = UUID()
        self.block = String()
        self.priority = 0
        self.unlock_requirement = None
        self.recipe_network_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.recipe_id)
        slice(io, self.input)
        slice(io, self.output)
        uuid(io, self.uuid)
        io.string(self.block)
        io.varint32(self.priority)
        optional_marshaler(io, self.unlock_requirement)
        io.varuint32(self.recipe_network_id)


comptime UserDataShapelessRecipe = ShapelessRecipe
"""A shapeless recipe whose items keep their user data, such as dyeing a
shulker box. It has the layout of `ShapelessRecipe`."""

comptime ShapelessChemistryRecipe = ShapelessRecipe
"""An Education Edition chemistry recipe with the layout of `ShapelessRecipe`.
"""


struct ShapedRecipe(Marshaler):
    """A recipe whose ingredients must be placed in a specific shape."""

    var recipe_id: String
    """A unique ID of the recipe."""
    var width: Int32
    """The width of the shape."""
    var height: Int32
    """The height of the shape."""
    var input: List[ItemDescriptorCount]
    """The ingredients; exactly `width * height` of them."""
    var output: List[ItemStack]
    """The items created by the recipe."""
    var uuid: UUID
    """A UUID identifying the recipe; may be empty."""
    var block: String
    """The block required, without `minecraft:`, such as `crafting_table`."""
    var priority: Int32
    """The recipe's priority."""
    var assume_symmetry: Bool
    """Whether the recipe may also be crafted mirrored."""
    var unlock_requirement: Optional[RecipeUnlockRequirement]
    """What unlocks the recipe, if anything."""
    var recipe_network_id: UInt32
    """A unique, non-zero network ID of the recipe."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.recipe_id = String()
        self.width = 0
        self.height = 0
        self.input = List[ItemDescriptorCount]()
        self.output = List[ItemStack]()
        self.uuid = UUID()
        self.block = String()
        self.priority = 0
        self.assume_symmetry = False
        self.unlock_requirement = None
        self.recipe_network_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the ingredient count is not `width * height`, or the input is
            malformed.
        """
        io.string(self.recipe_id)
        io.varint32(self.width)
        io.varint32(self.height)
        slice(io, self.input)
        if Int64(len(self.input)) != Int64(self.width) * Int64(self.height):
            invalid_value(
                String(len(self.input)),
                "shaped recipe ingredients",
                "must equal width multiplied by height",
            )
        slice(io, self.output)
        uuid(io, self.uuid)
        io.string(self.block)
        io.varint32(self.priority)
        io.bool(self.assume_symmetry)
        optional_marshaler(io, self.unlock_requirement)
        io.varuint32(self.recipe_network_id)


comptime ShapedChemistryRecipe = ShapedRecipe
"""An Education Edition chemistry recipe with the layout of `ShapedRecipe`."""


struct MultiRecipe(Marshaler):
    """An "enable" switch for a multi-shape recipe."""

    var uuid: UUID
    """A UUID identifying the recipe; may be empty."""
    var recipe_network_id: UInt32
    """A unique, non-zero network ID of the recipe."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.uuid = UUID()
        self.recipe_network_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        uuid(io, self.uuid)
        io.varuint32(self.recipe_network_id)


struct SmithingTransformRecipe(Marshaler):
    """A smithing table recipe combining three inputs into a new item."""

    var recipe_network_id: UInt32
    """A unique, non-zero network ID of the recipe."""
    var recipe_id: String
    """A unique ID of the recipe."""
    var template: ItemDescriptorCount
    """The template that shapes the base item."""
    var base: ItemDescriptorCount
    """The item the addition is applied to."""
    var addition: ItemDescriptorCount
    """The item added to the base."""
    var result: ItemStack
    """The resulting item."""
    var block: String
    """The block required, without `minecraft:`, such as `smithing_table`."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.recipe_network_id = 0
        self.recipe_id = String()
        self.template = ItemDescriptorCount()
        self.base = ItemDescriptorCount()
        self.addition = ItemDescriptorCount()
        self.result = ItemStack()
        self.block = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.recipe_id)
        item_descriptor_count(io, self.template)
        item_descriptor_count(io, self.base)
        item_descriptor_count(io, self.addition)
        item(io, self.result)
        io.string(self.block)
        io.varuint32(self.recipe_network_id)


struct SmithingTrimRecipe(Marshaler):
    """A smithing table recipe that applies an armour trim."""

    var recipe_network_id: UInt32
    """A unique, non-zero network ID of the recipe."""
    var recipe_id: String
    """A unique ID of the recipe."""
    var template: ItemDescriptorCount
    """The trim template."""
    var base: ItemDescriptorCount
    """The armour piece the trim is applied to."""
    var addition: ItemDescriptorCount
    """The trim material."""
    var block: String
    """The block required, without `minecraft:`, such as `smithing_table`."""

    def __init__(out self):
        """Creates an empty recipe."""
        self.recipe_network_id = 0
        self.recipe_id = String()
        self.template = ItemDescriptorCount()
        self.base = ItemDescriptorCount()
        self.addition = ItemDescriptorCount()
        self.block = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the recipe.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.recipe_id)
        item_descriptor_count(io, self.template)
        item_descriptor_count(io, self.base)
        item_descriptor_count(io, self.addition)
        io.string(self.block)
        io.varuint32(self.recipe_network_id)
