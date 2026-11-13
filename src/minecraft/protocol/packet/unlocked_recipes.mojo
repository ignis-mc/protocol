"""The `UnlockedRecipes` packet (gophertunnel `packet/unlocked_recipes.go`)."""

from ..io import IO, string_slice
from .id import ID_UNLOCKED_RECIPES
from .packet import Packet

comptime UNLOCKED_RECIPES_TYPE_EMPTY: UInt32 = 0
"""No change."""
comptime UNLOCKED_RECIPES_TYPE_INITIALLY_UNLOCKED: UInt32 = 1
"""The initial set of recipes."""
comptime UNLOCKED_RECIPES_TYPE_NEWLY_UNLOCKED: UInt32 = 2
"""Newly unlocked recipes."""
comptime UNLOCKED_RECIPES_TYPE_REMOVE_UNLOCKED: UInt32 = 3
"""Recipes to lock again."""
comptime UNLOCKED_RECIPES_TYPE_REMOVE_ALL_UNLOCKED: UInt32 = 4
"""Lock every recipe."""


struct UnlockedRecipes(Packet):
    """Sent by the server to change the recipes a player has unlocked."""

    comptime ID: UInt32 = ID_UNLOCKED_RECIPES
    """The packet ID."""
    var unlock_type: UInt32
    """One of the `UNLOCKED_RECIPES_TYPE_*` values."""
    var recipes: List[String]
    """The recipe names."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.unlock_type = 0
        self.recipes = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.unlock_type)
        string_slice(io, self.recipes)
