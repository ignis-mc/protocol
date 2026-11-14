"""The `ItemRegistry` packet (gophertunnel `packet/item_registry.go`)."""

from ..io import IO, slice
from ..item import ItemEntry
from .id import ID_ITEM_REGISTRY
from .packet import Packet


struct ItemRegistry(Packet):
    """Sent by the server to send the client a list of available items and
    attach client-side components to a custom item.
    """

    comptime ID: UInt32 = ID_ITEM_REGISTRY
    """The packet ID."""
    var items: List[ItemEntry]
    """A list of all items with their legacy IDs which are available in the
    game.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.items = List[ItemEntry]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.items)
