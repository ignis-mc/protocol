"""The `InventoryTransaction` packet (gophertunnel `packet/inventory_transaction.go`)."""

from ..inventory import (
    InventoryAction,
    InventoryTransactionData,
    LegacySetItemSlot,
    transaction_data_type,
)
from ..io import IO, slice
from .id import ID_INVENTORY_TRANSACTION
from .packet import Packet

comptime INVENTORY_TRANSACTION_TYPE_NORMAL: UInt32 = 0
"""The normal transaction type."""
comptime INVENTORY_TRANSACTION_TYPE_MISMATCH: UInt32 = 1
"""The mismatch transaction type."""
comptime INVENTORY_TRANSACTION_TYPE_USE_ITEM: UInt32 = 2
"""The use item transaction type."""
comptime INVENTORY_TRANSACTION_TYPE_USE_ITEM_ON_ENTITY: UInt32 = 3
"""The use item on entity transaction type."""
comptime INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM: UInt32 = 4
"""The release item transaction type."""


struct InventoryTransaction(Packet):
    """Sent by the client for inventory changes and world interactions.

    It holds one of several sub-packets, chosen by `transaction_data`.
    """

    comptime ID: UInt32 = ID_INVENTORY_TRANSACTION
    """The packet ID."""
    var legacy_request_id: Int32
    """An ID that is only non-zero at times when sent by the client."""
    var legacy_set_item_slots: List[LegacySetItemSlot]
    """The slots changed by a legacy request; present only for legacy request
    IDs.
    """
    var actions: List[InventoryAction]
    """A list of actions that took place, that form the inventory transaction
    together.
    """
    var transaction_data: InventoryTransactionData
    """A data object that holds data specific to the type of transaction that
    the TransactionPacket held.
    """

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.legacy_request_id = 0
        self.legacy_set_item_slots = List[LegacySetItemSlot]()
        self.actions = List[InventoryAction]()
        self.transaction_data = InventoryTransactionData()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.legacy_request_id)
        var has_legacy = (
            self.legacy_request_id < -1 and (self.legacy_request_id & 1) == 0
        )
        io.bool(has_legacy)
        if has_legacy:
            slice(io, self.legacy_set_item_slots)
        transaction_data_type(io, self.transaction_data)
        slice(io, self.actions)
        self.transaction_data.marshal(io)
