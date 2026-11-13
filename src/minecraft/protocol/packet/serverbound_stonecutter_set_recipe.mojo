"""The `ServerboundStonecutterSetRecipe` packet.

This is gophertunnel `packet/serverbound_stonecutter_set_recipe.go`.
"""

from ..io import IO
from .id import ID_SERVERBOUND_STONECUTTER_SET_RECIPE
from .packet import Packet


struct ServerboundStonecutterSetRecipe(Packet):
    """Sent by the client when the player selects a stonecutter recipe."""

    comptime ID: UInt32 = ID_SERVERBOUND_STONECUTTER_SET_RECIPE
    """The packet ID."""
    var container_id: UInt8
    """The ID of the stonecutter container."""
    var recipe_index: Int32
    """The index of the selected recipe."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.container_id = 0
        self.recipe_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.container_id)
        io.varint32(self.recipe_index)
