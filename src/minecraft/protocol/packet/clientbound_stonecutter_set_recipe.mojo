"""The `ClientboundStonecutterSetRecipe` packet (gophertunnel `packet/clientbound_stonecutter_set_recipe.go`)."""

from ..io import IO, actor_unique_id
from .id import ID_CLIENTBOUND_STONECUTTER_SET_RECIPE
from .packet import Packet


struct ClientboundStonecutterSetRecipe(Packet):
    """Sent by the server when the selected stonecutter recipe changes."""

    comptime ID: UInt32 = ID_CLIENTBOUND_STONECUTTER_SET_RECIPE
    """The packet ID."""
    var player_unique_id: Int64
    """The unique ID of the player owning the container."""
    var container_id: UInt8
    """The ID of the stonecutter container."""
    var recipe_index: Int32
    """The index of the selected recipe."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.player_unique_id = 0
        self.container_id = 0
        self.recipe_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.player_unique_id)
        io.uint8(self.container_id)
        io.varint32(self.recipe_index)
