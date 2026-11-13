"""Inventory actions and transactions (gophertunnel `protocol/inventory.go`).

Go's `InventoryTransactionData` interface becomes `InventoryTransactionData`,
a struct holding a `Variant` of the five concrete data types, each carrying
its type ID as `comptime ID`. As in Go, the type ID and the data are not
adjacent on the wire: `transaction_data_type` marshals the ID (choosing the
variant when reading) and `InventoryTransactionData.marshal` the data.
"""

from std.builtin.rebind import downcast
from std.utils import Variant

from .block_pos import BlockPos
from .io import (
    IO,
    Marshaler,
    actor_runtime_id,
    block_pos,
    slice,
    unknown_enum_option,
    vec3,
)
from .item import ItemInstance, item_instance
from .math import Vec3

comptime INVENTORY_ACTION_SOURCE_CONTAINER: UInt32 = 0
"""The container inventory action source."""
comptime INVENTORY_ACTION_SOURCE_WORLD: UInt32 = 2
"""The world inventory action source."""
comptime INVENTORY_ACTION_SOURCE_CREATIVE: UInt32 = 3
"""The creative inventory action source."""
comptime INVENTORY_ACTION_SOURCE_TODO: UInt32 = 99999
"""The todo inventory action source."""

comptime WINDOW_ID_INVENTORY: Int8 = 0
"""The inventory window ID."""
comptime WINDOW_ID_OFF_HAND: Int8 = 119
"""The off hand window ID."""
comptime WINDOW_ID_ARMOUR: Int8 = 120
"""The armour window ID."""
comptime WINDOW_ID_UI: Int8 = 124
"""The ui window ID."""

comptime INVENTORY_TRANSACTION_TYPE_NORMAL: UInt32 = 0
"""The type ID of the normal transaction data."""
comptime INVENTORY_TRANSACTION_TYPE_MISMATCH: UInt32 = 1
"""The type ID of the mismatch transaction data."""
comptime INVENTORY_TRANSACTION_TYPE_USE_ITEM: UInt32 = 2
"""The type ID of the use item transaction data."""
comptime INVENTORY_TRANSACTION_TYPE_USE_ITEM_ON_ENTITY: UInt32 = 3
"""The type ID of the use item on entity transaction data."""
comptime INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM: UInt32 = 4
"""The type ID of the release item transaction data."""

comptime USE_ITEM_ACTION_CLICK_BLOCK: UInt32 = 0
"""Use item action: click block."""
comptime USE_ITEM_ACTION_CLICK_AIR: UInt32 = 1
"""Use item action: click air."""
comptime USE_ITEM_ACTION_BREAK_BLOCK: UInt32 = 2
"""Use item action: break block."""
comptime USE_ITEM_ACTION_USE_AS_ATTACK: UInt32 = 3
"""Use item action: use as attack."""

comptime TRIGGER_TYPE_UNKNOWN: UInt32 = 0
"""Trigger type: unknown."""
comptime TRIGGER_TYPE_PLAYER_INPUT: UInt32 = 1
"""Trigger type: player input."""
comptime TRIGGER_TYPE_SIMULATION_TICK: UInt32 = 2
"""Trigger type: simulation tick."""

comptime CLIENT_PREDICTION_FAILURE: UInt8 = 0
"""Client prediction: failure."""
comptime CLIENT_PREDICTION_SUCCESS: UInt8 = 1
"""Client prediction: success."""

comptime CLIENT_COOLDOWN_STATE_OFF: UInt8 = 0
"""Client cooldown state: off."""
comptime CLIENT_COOLDOWN_STATE_ON: UInt8 = 1
"""Client cooldown state: on."""

comptime HAND_SLOT_MAIN_HAND: UInt8 = 0
"""Hand slot: main hand."""
comptime HAND_SLOT_OFF_HAND: UInt8 = 1
"""Hand slot: off hand."""

comptime USE_ITEM_ON_ENTITY_ACTION_INTERACT: Int32 = 0
"""Use item on entity action: interact."""
comptime USE_ITEM_ON_ENTITY_ACTION_ATTACK: Int32 = 1
"""Use item on entity action: attack."""

comptime RELEASE_ITEM_ACTION_RELEASE: Int32 = 0
"""Release item action: release."""
comptime RELEASE_ITEM_ACTION_CONSUME: Int32 = 1
"""Release item action: consume."""


struct InventoryAction(Marshaler):
    """One slot change of an inventory transaction."""

    var source_type: UInt32
    """One of the `INVENTORY_ACTION_SOURCE_*` constants."""
    var window_id: Optional[Int8]
    """The window the client has open; absent for world sources."""
    var source_flags: Optional[UInt32]
    """Flags, present only for world sources."""
    var inventory_slot: UInt32
    """The slot the action changed."""
    var old_item: ItemInstance
    """The item in the slot before the action."""
    var new_item: ItemInstance
    """The item in the slot after the action."""

    def __init__(out self):
        """Creates an empty action."""
        self.source_type = 0
        self.window_id = None
        self.source_flags = None
        self.inventory_slot = 0
        self.old_item = ItemInstance()
        self.new_item = ItemInstance()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.source_type)
        _optional_int8(io, self.window_id)
        _optional_varuint32(io, self.source_flags)
        io.varuint32(self.inventory_slot)
        item_instance(io, self.old_item)
        item_instance(io, self.new_item)


trait InventoryTransactionDataKind(Marshaler):
    """A concrete transaction data type: one implementation of Go's
    `InventoryTransactionData`."""

    comptime ID: UInt32
    """The data's type ID, one of the `INVENTORY_TRANSACTION_TYPE_*` constants.
    """


struct NormalTransactionData(InventoryTransactionDataKind):
    """The data of a normal transaction, such as crafting; it is empty."""

    comptime ID: UInt32 = INVENTORY_TRANSACTION_TYPE_NORMAL
    """The data's type ID."""

    def __init__(out self):
        """Creates the data."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the data has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never; `Marshaler` requires the signature.
        """
        pass


struct MismatchTransactionData(InventoryTransactionDataKind):
    """The data of a mismatched transaction; it is empty."""

    comptime ID: UInt32 = INVENTORY_TRANSACTION_TYPE_MISMATCH
    """The data's type ID."""

    def __init__(out self):
        """Creates the data."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the data has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never; `Marshaler` requires the signature.
        """
        pass


struct UseItemTransactionData(InventoryTransactionDataKind):
    """The data sent when the client uses an item on a block.

    `marshal` writes the transaction data fields. `player_inventory_action`
    also includes the legacy request and the actions, as `PlayerAuthInput`
    sends them.
    """

    comptime ID: UInt32 = INVENTORY_TRANSACTION_TYPE_USE_ITEM
    """The data's type ID."""
    var legacy_request_id: Int32
    """Non-zero only when sent by the client with legacy slots."""
    var legacy_set_item_slots: Optional[List[LegacySetItemSlot]]
    """The slots changed by a legacy request."""
    var actions: List[InventoryAction]
    """The slot changes that together form the transaction."""
    var action_type: UInt32
    """One of the `USE_ITEM_ACTION_*` constants."""
    var trigger_type: UInt32
    """One of the `TRIGGER_TYPE_*` constants."""
    var block_position: BlockPos
    """The block that was interacted with."""
    var block_face: Int32
    """The face of the block that was clicked or last hit."""
    var hot_bar_slot: Int32
    """The hotbar slot held while clicking."""
    var hand: UInt8
    """The hand used, one of the `HAND_SLOT_*` constants."""
    var held_item: ItemInstance
    """The item held while clicking."""
    var position: Vec3
    """The player's position at the time."""
    var clicked_position: Vec3
    """The clicked position relative to the block."""
    var block_runtime_id: UInt32
    """The runtime ID of the clicked block."""
    var client_prediction: UInt8
    """One of the `CLIENT_PREDICTION_*` constants."""
    var client_cooldown_state: UInt8
    """One of the `CLIENT_COOLDOWN_STATE_*` constants."""

    def __init__(out self):
        """Creates empty data."""
        self.legacy_request_id = 0
        self.legacy_set_item_slots = None
        self.actions = List[InventoryAction]()
        self.action_type = 0
        self.trigger_type = 0
        self.block_position = BlockPos()
        self.block_face = 0
        self.hot_bar_slot = 0
        self.hand = 0
        self.held_item = ItemInstance()
        self.position = Vec3()
        self.clicked_position = Vec3()
        self.block_runtime_id = 0
        self.client_prediction = 0
        self.client_cooldown_state = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the transaction data fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var action_type = Int32(self.action_type)
        io.varint32(action_type)
        self.action_type = UInt32(action_type)
        var trigger_type = UInt8(self.trigger_type)
        io.uint8(trigger_type)
        self.trigger_type = UInt32(trigger_type)
        block_pos(io, self.block_position)
        var block_face = UInt8(self.block_face)
        io.uint8(block_face)
        self.block_face = Int32(block_face)
        io.varint32(self.hot_bar_slot)
        io.uint8(self.hand)
        item_instance(io, self.held_item)
        vec3(io, self.position)
        vec3(io, self.clicked_position)
        io.varuint32(self.block_runtime_id)
        io.uint8(self.client_prediction)
        io.uint8(self.client_cooldown_state)


struct UseItemOnEntityTransactionData(InventoryTransactionDataKind):
    """The data sent when the client uses an item on an entity."""

    comptime ID: UInt32 = INVENTORY_TRANSACTION_TYPE_USE_ITEM_ON_ENTITY
    """The data's type ID."""
    var target_entity_runtime_id: UInt64
    """The runtime ID of the entity clicked."""
    var action_type: Int32
    """One of the `USE_ITEM_ON_ENTITY_ACTION_*` constants."""
    var hot_bar_slot: Int32
    """The hotbar slot held while clicking."""
    var hand: UInt8
    """The hand used, one of the `HAND_SLOT_*` constants."""
    var held_item: ItemInstance
    """The item held while clicking."""
    var position: Vec3
    """The player's position at the time."""
    var clicked_position: Vec3
    """The clicked position relative to the entity."""

    def __init__(out self):
        """Creates empty data."""
        self.target_entity_runtime_id = 0
        self.action_type = 0
        self.hot_bar_slot = 0
        self.hand = 0
        self.held_item = ItemInstance()
        self.position = Vec3()
        self.clicked_position = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the data.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.target_entity_runtime_id)
        io.varint32(self.action_type)
        io.varint32(self.hot_bar_slot)
        io.uint8(self.hand)
        item_instance(io, self.held_item)
        vec3(io, self.position)
        vec3(io, self.clicked_position)


struct ReleaseItemTransactionData(InventoryTransactionDataKind):
    """The data sent when the client releases the item it was using."""

    comptime ID: UInt32 = INVENTORY_TRANSACTION_TYPE_RELEASE_ITEM
    """The data's type ID."""
    var action_type: Int32
    """One of the `RELEASE_ITEM_ACTION_*` constants; always 0 since 1.13."""
    var hot_bar_slot: Int32
    """The hotbar slot held while releasing."""
    var held_item: ItemInstance
    """The item released."""
    var head_position: Vec3
    """The position of the player's head at the time."""
    var hand: UInt8
    """The hand holding the item, one of the `HAND_SLOT_*` constants."""

    def __init__(out self):
        """Creates empty data."""
        self.action_type = 0
        self.hot_bar_slot = 0
        self.held_item = ItemInstance()
        self.head_position = Vec3()
        self.hand = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the data.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.action_type)
        io.varint32(self.hot_bar_slot)
        item_instance(io, self.held_item)
        vec3(io, self.head_position)
        io.uint8(self.hand)


struct InventoryTransactionData(Marshaler):
    """One of the concrete transaction data types (Go's
    `InventoryTransactionData`).

    `marshal` reads or writes only the held data; the type ID is marshalled
    separately with `transaction_data_type`.
    """

    comptime Kinds = Variant[
        NormalTransactionData,
        MismatchTransactionData,
        UseItemTransactionData,
        UseItemOnEntityTransactionData,
        ReleaseItemTransactionData,
    ]
    """The concrete data types."""
    var value: Self.Kinds
    """The held data."""

    def __init__(out self):
        """Creates normal (empty) transaction data."""
        self.value = NormalTransactionData()

    @implicit
    def __init__[T: InventoryTransactionDataKind](out self, var value: T):
        """Wraps concrete data.

        Parameters:
            T: The data type.

        Args:
            value: The data.
        """
        self.value = Self.Kinds(value^)

    def type_id(self) -> UInt32:
        """Gets the type ID of the held data (Go `lookupTransactionDataType`).

        Returns:
            One of the `INVENTORY_TRANSACTION_TYPE_*` constants.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[
                Self.Kinds.Ts[i], InventoryTransactionDataKind
            ]
            if self.value.isa[T]():
                return T.ID
        return INVENTORY_TRANSACTION_TYPE_NORMAL

    @staticmethod
    def from_type(id: UInt32) -> Optional[InventoryTransactionData]:
        """Creates empty data of a type (Go `lookupTransactionData`).

        Args:
            id: One of the `INVENTORY_TRANSACTION_TYPE_*` constants.

        Returns:
            The data, or `None` for an unknown type ID.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[
                Self.Kinds.Ts[i], InventoryTransactionDataKind
            ]
            if id == T.ID:
                return InventoryTransactionData(T())
        return None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the held data.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[
                Self.Kinds.Ts[i], InventoryTransactionDataKind
            ]
            if self.value.isa[T]():
                self.value[T].marshal(io)
                return


def transaction_data_type[
    I: IO
](mut io: I, mut x: InventoryTransactionData) raises:
    """Marshals the type ID of transaction data.

    This is gophertunnel `IO.TransactionDataType`.

    A reader replaces `x` with empty data of the decoded type, to be filled
    by `x.marshal` later.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the type ID is unknown or the input is malformed.
    """
    var id = x.type_id()
    io.varuint32(id)
    if io.reads():
        var data = InventoryTransactionData.from_type(id)
        if not data:
            unknown_enum_option(Int(id), "inventory transaction data type")
        x = data.value().copy()


def player_inventory_action[
    I: IO
](mut io: I, mut x: UseItemTransactionData) raises:
    """Marshals use-item data with its legacy slots and actions.

    This is gophertunnel `IO.PlayerInventoryAction`, used by
    `PlayerAuthInput`.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the input is malformed or a value is invalid.
    """
    io.varint32(x.legacy_request_id)
    var present = x.legacy_set_item_slots is not None
    io.bool(present)
    if present:
        var slots = x.legacy_set_item_slots.value().copy() if (
            x.legacy_set_item_slots
        ) else List[LegacySetItemSlot]()
        slice(io, slots)
        x.legacy_set_item_slots = slots^
    elif io.reads():
        x.legacy_set_item_slots = None
    slice(io, x.actions)
    x.marshal(io)


struct LegacySetItemSlot(Marshaler):
    """A slot changed by a legacy inventory transaction."""

    var container_id: UInt8
    """The container the slots are in."""
    var slots: List[UInt8]
    """The changed slots."""

    def __init__(out self):
        """Creates an empty slot list."""
        self.container_id = 0
        self.slots = List[UInt8]()

    def __init__(out self, container_id: UInt8, var slots: List[UInt8]):
        """Creates a slot list.

        Args:
            container_id: The container ID.
            slots: The changed slots.
        """
        self.container_id = container_id
        self.slots = slots^

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the slot list.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.container_id)
        io.byte_slice(self.slots)


def _optional_int8[I: IO](mut io: I, mut x: Optional[Int8]) raises:
    # OptionalFunc(r, x, r.Int8).
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.int8(v)
    x = v


def _optional_varuint32[I: IO](mut io: I, mut x: Optional[UInt32]) raises:
    # OptionalFunc(r, x, r.Varuint32).
    var present = x is not None
    io.bool(present)
    if not present:
        x = None
        return
    var v = x.or_else(0)
    io.varuint32(v)
    x = v
