"""The `InventoryContent` packet (gophertunnel `packet/inventory_content.go`)."""

from ..container import FullContainerName
from ..io import IO, func_slice
from ..item import ItemInstance, item_instance
from .id import ID_INVENTORY_CONTENT
from .packet import Packet


struct InventoryContent(Packet):
    """Sent by the server to update the full content of a particular inventory.
    """

    comptime ID: UInt32 = ID_INVENTORY_CONTENT
    """The packet ID."""
    var window_id: UInt32
    """The ID that identifies one of the windows that the client currently has
    opened, or one of the consistent windows such as the main inventory.
    """
    var content: List[ItemInstance]
    """The new content of the inventory."""
    var container: FullContainerName
    """The protocol.FullContainerName that describes the container that the
    content is for.
    """
    var storage_item: ItemInstance
    """The item that is acting as the storage container for the inventory."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.content = List[ItemInstance]()
        self.container = FullContainerName()
        self.storage_item = ItemInstance()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.window_id)
        func_slice[item_instance[I]](io, self.content)
        self.container.marshal(io)
        item_instance(io, self.storage_item)
