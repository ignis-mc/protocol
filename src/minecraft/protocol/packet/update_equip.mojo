"""The `UpdateEquip` packet (gophertunnel `packet/update_equip.go`)."""

from ...nbt.nbt import NBT
from ..io import IO, actor_unique_id
from .id import ID_UPDATE_EQUIP
from .packet import Packet


struct UpdateEquip(Packet):
    """Sent by the server when a horse inventory is opened."""

    comptime ID: UInt32 = ID_UPDATE_EQUIP
    """The packet ID."""
    var window_id: UInt8
    """The ID of the window."""
    var window_type: UInt8
    """The type of the window."""
    var size: Int32
    """Unused; zero in vanilla."""
    var entity_unique_id: Int64
    """The unique ID of the horse."""
    var serialised_inventory_data: List[UInt8]
    """The inventory as network NBT, to the end of the packet."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.window_type = 0
        self.size = 0
        self.entity_unique_id = 0
        self.serialised_inventory_data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.window_id)
        io.uint8(self.window_type)
        io.varint32(self.size)
        actor_unique_id(io, self.entity_unique_id)
        io.bytes(self.serialised_inventory_data)
