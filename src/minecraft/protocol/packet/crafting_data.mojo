"""The `CraftingData` packet (gophertunnel `packet/crafting_data.go`)."""

from ..io import IO, func_slice, slice
from ..item import MaterialReducer, material_reducer
from ..recipe import (
    MultiRecipe,
    PotionContainerChangeRecipe,
    PotionRecipe,
    ShapedChemistryRecipe,
    ShapedRecipe,
    ShapelessChemistryRecipe,
    ShapelessRecipe,
    SmithingTransformRecipe,
    SmithingTrimRecipe,
    UserDataShapelessRecipe,
)
from .id import ID_CRAFTING_DATA
from .packet import Packet


struct CraftingData(Packet):
    """Sent by the server to let the client know all crafting data that the
    server maintains.
    """

    comptime ID: UInt32 = ID_CRAFTING_DATA
    """The packet ID."""
    var shaped_recipes: List[ShapedRecipe]
    """Shaped crafting recipes."""
    var shapeless_recipes: List[ShapelessRecipe]
    """Shapeless crafting recipes."""
    var multi_recipes: List[MultiRecipe]
    """Recipes the client has hard-coded, such as map extending."""
    var user_data_shapeless_recipes: List[UserDataShapelessRecipe]
    """Shapeless recipes whose items keep their user data."""
    var shapeless_chemistry_recipes: List[ShapelessChemistryRecipe]
    """Shapeless Education Edition chemistry recipes."""
    var shaped_chemistry_recipes: List[ShapedChemistryRecipe]
    """Shaped Education Edition chemistry recipes."""
    var smithing_transform_recipes: List[SmithingTransformRecipe]
    """Smithing table upgrade recipes."""
    var smithing_trim_recipes: List[SmithingTrimRecipe]
    """Smithing table armour trim recipes."""
    var potion_recipes: List[PotionRecipe]
    """A list of all potion mixing recipes which may be used in the brewing
    stand.
    """
    var potion_container_change_recipes: List[PotionContainerChangeRecipe]
    """A list of all recipes to convert a potion from one type to another, such
    as from a drinkable potion to a splash potion, or from a splash potion to a
    lingering potion.
    """
    var material_reducers: List[MaterialReducer]
    """A list of all material reducers which is used in education edition
    chemistry.
    """
    var clear_recipes: Bool
    """Whether the client should drop every recipe it currently knows."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.shaped_recipes = List[ShapedRecipe]()
        self.shapeless_recipes = List[ShapelessRecipe]()
        self.multi_recipes = List[MultiRecipe]()
        self.user_data_shapeless_recipes = List[UserDataShapelessRecipe]()
        self.shapeless_chemistry_recipes = List[ShapelessChemistryRecipe]()
        self.shaped_chemistry_recipes = List[ShapedChemistryRecipe]()
        self.smithing_transform_recipes = List[SmithingTransformRecipe]()
        self.smithing_trim_recipes = List[SmithingTrimRecipe]()
        self.potion_recipes = List[PotionRecipe]()
        self.potion_container_change_recipes = List[
            PotionContainerChangeRecipe
        ]()
        self.material_reducers = List[MaterialReducer]()
        self.clear_recipes = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.shaped_recipes)
        slice(io, self.shapeless_recipes)
        slice(io, self.multi_recipes)
        slice(io, self.user_data_shapeless_recipes)
        slice(io, self.shapeless_chemistry_recipes)
        slice(io, self.shaped_chemistry_recipes)
        slice(io, self.smithing_transform_recipes)
        slice(io, self.smithing_trim_recipes)
        slice(io, self.potion_recipes)
        slice(io, self.potion_container_change_recipes)
        func_slice[material_reducer[I]](io, self.material_reducers)
        io.bool(self.clear_recipes)
