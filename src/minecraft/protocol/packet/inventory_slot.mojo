"""The `InventorySlot` packet (gophertunnel `packet/inventory_slot.go`)."""

from ..container import FullContainerName
from ..io import IO, optional_func, optional_marshaler
from ..item import ItemInstance, item_instance
from .id import ID_INVENTORY_SLOT
from .packet import Packet


struct InventorySlot(Packet):
    """Sent by the server to update a single slot in one of the inventory
    windows that the client currently has opened.
    """

    comptime ID: UInt32 = ID_INVENTORY_SLOT
    """The packet ID."""
    var window_id: UInt32
    """The ID of the window that the packet modifies."""
    var slot: UInt32
    """The index of the slot that the packet modifies."""
    var container: Optional[FullContainerName]
    """The protocol.FullContainerName that describes the container that the
    content is for.
    """
    var storage_item: Optional[ItemInstance]
    """The item that is acting as the storage container for the inventory."""
    var new_item: ItemInstance
    """The item to be put in the slot at Slot."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.slot = 0
        self.container = None
        self.storage_item = None
        self.new_item = ItemInstance()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.window_id)
        io.varuint32(self.slot)
        optional_marshaler(io, self.container)
        optional_func[item_instance[I]](io, self.storage_item)
        item_instance(io, self.new_item)
