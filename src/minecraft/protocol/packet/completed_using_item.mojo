"""The `CompletedUsingItem` packet (gophertunnel `packet/completed_using_item.go`)."""

from ..io import IO
from .id import ID_COMPLETED_USING_ITEM
from .packet import Packet

comptime USE_ITEM_EQUIP_ARMOUR: Int32 = 0
"""The equip armour use method."""
comptime USE_ITEM_EAT: Int32 = 1
"""The eat use method."""
comptime USE_ITEM_ATTACK: Int32 = 2
"""The attack use method."""
comptime USE_ITEM_CONSUME: Int32 = 3
"""The consume use method."""
comptime USE_ITEM_THROW: Int32 = 4
"""The throw use method."""
comptime USE_ITEM_SHOOT: Int32 = 5
"""The shoot use method."""
comptime USE_ITEM_PLACE: Int32 = 6
"""The place use method."""
comptime USE_ITEM_FILL_BOTTLE: Int32 = 7
"""The fill bottle use method."""
comptime USE_ITEM_FILL_BUCKET: Int32 = 8
"""The fill bucket use method."""
comptime USE_ITEM_POUR_BUCKET: Int32 = 9
"""The pour bucket use method."""
comptime USE_ITEM_USE_TOOL: Int32 = 10
"""The use tool use method."""
comptime USE_ITEM_INTERACT: Int32 = 11
"""The interact use method."""
comptime USE_ITEM_RETRIEVED: Int32 = 12
"""The retrieved use method."""
comptime USE_ITEM_DYED: Int32 = 13
"""The dyed use method."""
comptime USE_ITEM_TRADED: Int32 = 14
"""The traded use method."""
comptime USE_ITEM_BRUSHING_COMPLETED: Int32 = 15
"""The brushing completed use method."""
comptime USE_ITEM_OPENED_VAULT: Int32 = 16
"""The opened vault use method."""


struct CompletedUsingItem(Packet):
    """Sent by the server to tell the client that it should be done using the
    item it is currently using.
    """

    comptime ID: UInt32 = ID_COMPLETED_USING_ITEM
    """The packet ID."""
    var used_item_id: Int16
    """The item ID of the item that the client completed using."""
    var use_method: Int32
    """The method of the using of the item that was completed."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.used_item_id = 0
        self.use_method = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int16(self.used_item_id)
        io.int32(self.use_method)
