"""The `MobEquipment` packet (gophertunnel `packet/mob_equipment.go`)."""

from ..io import IO, actor_runtime_id
from ..item import ItemInstance, item_instance
from .id import ID_MOB_EQUIPMENT
from .packet import Packet


struct MobEquipment(Packet):
    """Sent by both sides to show the item an entity holds in its hand."""

    comptime ID: UInt32 = ID_MOB_EQUIPMENT
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var new_item: ItemInstance
    """The item now held."""
    var inventory_slot: UInt8
    """The held slot; kept for backwards compatibility with `hot_bar_slot`."""
    var hot_bar_slot: UInt8
    """The held hot bar slot."""
    var window_id: UInt8
    """The window whose equipped item changed, such as the off hand."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.new_item = ItemInstance()
        self.inventory_slot = 0
        self.hot_bar_slot = 0
        self.window_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        item_instance(io, self.new_item)
        io.uint8(self.inventory_slot)
        io.uint8(self.hot_bar_slot)
        io.uint8(self.window_id)
