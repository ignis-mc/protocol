"""The `MobArmourEquipment` packet (gophertunnel `packet/mob_armour_equipment.go`).
"""

from ..io import IO, actor_runtime_id
from ..item import ItemInstance, item_instance
from .id import ID_MOB_ARMOUR_EQUIPMENT
from .packet import Packet


struct MobArmourEquipment(Packet):
    """Sent by the server to update the armour an entity is wearing.

    It is sent for players and for other entities, such as zombies.
    """

    comptime ID: UInt32 = ID_MOB_ARMOUR_EQUIPMENT
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity."""
    var helmet: ItemInstance
    """The helmet; items not wearable on the head are not rendered."""
    var chestplate: ItemInstance
    """The chestplate."""
    var leggings: ItemInstance
    """The leggings."""
    var boots: ItemInstance
    """The boots."""
    var body: ItemInstance
    """The item worn on the body."""

    def __init__(out self):
        """Creates the packet with every slot empty."""
        self.entity_runtime_id = 0
        self.helmet = ItemInstance()
        self.chestplate = ItemInstance()
        self.leggings = ItemInstance()
        self.boots = ItemInstance()
        self.body = ItemInstance()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.entity_runtime_id)
        item_instance(io, self.helmet)
        item_instance(io, self.chestplate)
        item_instance(io, self.leggings)
        item_instance(io, self.boots)
        item_instance(io, self.body)
