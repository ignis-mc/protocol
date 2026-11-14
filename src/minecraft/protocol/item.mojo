"""Item stacks and instances (gophertunnel `protocol/item.go`).

Also holds the item encodings gophertunnel keeps on `Reader` and `Writer`:
`item` (`IO.Item`), `item_instance` (`IO.ItemInstance`),
`stack_request_item` (`IO.StackRequestItem`) and `material_reducer`
(`IO.MaterialReducer`). The item user data is a length-prefixed byte slice
with its own little-endian layout, so it is encoded with a nested `Reader`
or `Writer`.
"""

from ..nbt.nbt import (
    BIG_ENDIAN,
    LITTLE_ENDIAN,
    NBT,
    NETWORK_LITTLE_ENDIAN,
    TAG_COMPOUND,
    TAG_END,
    nbt,
)
from .io import (
    IO,
    MAX_SLICE_LENGTH,
    Marshaler,
    slice,
    unknown_enum_option,
)
from .reader import Reader
from .writer import Writer as ProtocolWriter

comptime ITEM_ENTRY_VERSION_LEGACY: Int32 = 0
"""A legacy item entry."""
comptime ITEM_ENTRY_VERSION_DATA_DRIVEN: Int32 = 1
"""A data-driven item entry."""
comptime ITEM_ENTRY_VERSION_NONE: Int32 = 2
"""An item entry without a version."""

comptime _SHIELD_IDENTIFIER = "minecraft:shield"


@fieldwise_init
struct ItemType(Copyable, Defaultable, Equatable, Writable):
    """A network ID and metadata value: the kind of an item."""

    var network_id: Int32
    """The numerical network ID of the item; may be negative."""
    var metadata_value: UInt32
    """The damage value, or the variant of the item."""

    def __init__(out self):
        """Creates the air item type."""
        self.network_id = 0
        self.metadata_value = 0


struct ItemStack(Marshaler):
    """An item stack as sent over the network.

    `marshal` uses the `IO.Item` encoding (`item`).
    """

    var item_type: ItemType
    """The network ID and metadata value (Go's embedded `ItemType`)."""
    var block_runtime_id: Int32
    """The runtime ID of the block the item represents, if any."""
    var count: UInt16
    """The number of items in the stack."""
    var nbt_data: NBT
    """The item's compound tag, in `LITTLE_ENDIAN` encoding."""
    var can_be_placed_on: List[String]
    """Block identifiers the item can be placed on."""
    var can_break: List[String]
    """Block identifiers the item can break."""
    var blocking_tick: Int64
    """The tick a shield started blocking; only sent for shields."""

    def __init__(out self):
        """Creates an empty (air) stack."""
        self.item_type = ItemType()
        self.block_runtime_id = 0
        self.count = 0
        self.nbt_data = NBT(List[UInt8](), LITTLE_ENDIAN)
        self.can_be_placed_on = List[String]()
        self.can_break = List[String]()
        self.blocking_tick = 0

    def __init__(
        out self,
        item_type: ItemType,
        count: UInt16,
        block_runtime_id: Int32 = 0,
    ):
        """Creates a stack with no user data."""
        self = Self()
        self.item_type = item_type.copy()
        self.count = count
        self.block_runtime_id = block_runtime_id

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the stack in the `IO.Item` encoding."""
        item(io, self)


struct ItemInstance(Marshaler):
    """An item stack with its persistent stack network ID.

    `marshal` uses the `IO.ItemInstance` encoding (`item_instance`).
    """

    var stack_network_id: Int32
    """The stack's network ID; 0 for an empty stack."""
    var stack: ItemStack
    """The item stack."""

    def __init__(out self):
        """Creates an empty instance."""
        self.stack_network_id = 0
        self.stack = ItemStack()

    def __init__(out self, stack_network_id: Int32, var stack: ItemStack):
        """Creates an instance."""
        self.stack_network_id = stack_network_id
        self.stack = stack^

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the instance in the `IO.ItemInstance` encoding."""
        item_instance(io, self)


struct StackRequestItem(Marshaler):
    """The named item format used by deprecated craft-result actions.

    `marshal` uses the `IO.StackRequestItem` encoding (`stack_request_item`).
    """

    var identifier: String
    """The namespaced item identifier; empty for no item."""
    var metadata_value: UInt32
    """The metadata or damage value of the item."""
    var block_runtime_id: Int32
    """The runtime ID of the block the item represents, if any."""
    var count: UInt16
    """The number of items in the stack."""
    var nbt_data: NBT
    """The item's compound tag, in `LITTLE_ENDIAN` encoding."""
    var can_be_placed_on: List[String]
    """Block identifiers the item can be placed on."""
    var can_break: List[String]
    """Block identifiers the item can break."""
    var blocking_tick: Int64
    """The tick a shield started blocking; only sent for shields."""

    def __init__(out self):
        """Creates an empty item."""
        self.identifier = String()
        self.metadata_value = 0
        self.block_runtime_id = 0
        self.count = 0
        self.nbt_data = NBT(List[UInt8](), LITTLE_ENDIAN)
        self.can_be_placed_on = List[String]()
        self.can_break = List[String]()
        self.blocking_tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the item in the `IO.StackRequestItem` encoding."""
        stack_request_item(io, self)


struct ItemEntry(Marshaler):
    """An entry of the item table: a name and the runtime ID it maps to."""

    var name: String
    """The item name, such as `minecraft:stick`."""
    var runtime_id: Int16
    """The ID that identifies the item over the network."""
    var component_based: Bool
    """Whether the item is a custom, component-based item."""
    var version: Int32
    """One of the `ITEM_ENTRY_VERSION_*` constants."""
    var data: NBT
    """The item's components and properties (network little-endian)."""

    def __init__(out self):
        """Creates an empty entry."""
        self.name = String()
        self.runtime_id = 0
        self.component_based = False
        self.version = ITEM_ENTRY_VERSION_LEGACY
        self.data = NBT()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry."""
        io.string(self.name)
        io.int16(self.runtime_id)
        io.bool(self.component_based)
        io.varint32(self.version)
        nbt(io, self.data, NETWORK_LITTLE_ENDIAN)


@fieldwise_init
struct MaterialReducerOutput(Marshaler):
    """An output of a material reducer."""

    var network_id: Int32
    """The network ID of the output."""
    var count: Int32
    """The quantity of the output."""

    def __init__(out self):
        """Creates an empty output."""
        self.network_id = 0
        self.count = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the output."""
        io.varint32(self.network_id)
        io.varint32(self.count)


struct MaterialReducer(Marshaler):
    """A craft in an Education Edition material reducer.

    `marshal` uses the `IO.MaterialReducer` encoding (`material_reducer`).
    """

    var input_item: ItemType
    """The starting item."""
    var outputs: List[MaterialReducerOutput]
    """The items it is reduced to."""

    def __init__(out self):
        """Creates an empty reducer."""
        self.input_item = ItemType()
        self.outputs = List[MaterialReducerOutput]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the reducer."""
        material_reducer(io, self)


# ===----------------------------------------------------------------------=== #
# IO methods
# ===----------------------------------------------------------------------=== #


def item_instance[I: IO](mut io: I, mut x: ItemInstance) raises:
    """Marshals an item instance (gophertunnel `IO.ItemInstance`).

    The network ID is sent as an `int16`, so IDs outside its range wrap.
    """
    ref s = x.stack
    var id = Int16(s.item_type.network_id)
    io.int16(id)
    s.item_type.network_id = Int32(id)
    io.uint16(s.count)
    io.varuint32(s.item_type.metadata_value)
    var has_net_id = x.stack_network_id != 0
    io.bool(has_net_id)
    if has_net_id:
        io.varint32(x.stack_network_id)
    else:
        x.stack_network_id = 0
    var block_runtime_id = UInt32(s.block_runtime_id)
    io.varuint32(block_runtime_id)
    s.block_runtime_id = Int32(block_runtime_id)
    var network_id = s.item_type.network_id
    _item_user_data(
        io,
        s.nbt_data,
        s.can_be_placed_on,
        s.can_break,
        s.blocking_tick,
        present=network_id != 0,
        shield=network_id == io.shield_id(),
    )


def item[I: IO](mut io: I, mut x: ItemStack) raises:
    """Marshals an item stack (gophertunnel `IO.Item`)."""
    io.varint32(x.item_type.network_id)
    io.uint16(x.count)
    io.varuint32(x.item_type.metadata_value)
    io.varint32(x.block_runtime_id)
    var network_id = x.item_type.network_id
    _item_user_data(
        io,
        x.nbt_data,
        x.can_be_placed_on,
        x.can_break,
        x.blocking_tick,
        present=network_id != 0,
        shield=network_id == io.shield_id(),
    )


def stack_request_item[I: IO](mut io: I, mut x: StackRequestItem) raises:
    """Marshals a named item (gophertunnel `IO.StackRequestItem`)."""
    var has_item = x.identifier.byte_length() != 0
    var variant = UInt32(1) if has_item else UInt32(0)
    io.varuint32(variant)
    var legacy_variant = UInt8(variant)
    io.uint8(legacy_variant)
    if io.reads():
        has_item = variant == 1
        if variant != 0 and not has_item:
            unknown_enum_option(Int(variant), "stack request item descriptor")
    if has_item:
        io.string(x.identifier)
        var metadata = Int32(x.metadata_value)
        io.varint32(metadata)
        x.metadata_value = UInt32(metadata)
    else:
        x.identifier = String()
        x.metadata_value = 0
    var count = Int16(x.count)
    io.int16(count)
    x.count = UInt16(count)
    var block_runtime_id = UInt32(x.block_runtime_id)
    io.varuint32(block_runtime_id)
    x.block_runtime_id = Int32(block_runtime_id)
    var shield = x.identifier == _SHIELD_IDENTIFIER
    _item_user_data(
        io,
        x.nbt_data,
        x.can_be_placed_on,
        x.can_break,
        x.blocking_tick,
        present=has_item,
        shield=shield,
    )


def material_reducer[I: IO](mut io: I, mut x: MaterialReducer) raises:
    """Marshals a material reducer (gophertunnel `IO.MaterialReducer`).

    The input is sent as `network_id << 16 | metadata_value`. gophertunnel's
    reader shifts the network ID left instead of right; this port decodes
    `mix >> 16` so that a written value reads back unchanged.
    """
    var mix = (x.input_item.network_id << 16) | Int32(
        x.input_item.metadata_value
    )
    io.varint32(mix)
    if io.reads():
        x.input_item = ItemType(mix >> 16, UInt32(mix & 0x7FFF))
    slice(io, x.outputs)


# ===----------------------------------------------------------------------=== #
# Item user data (gophertunnel itemUserData)
# ===----------------------------------------------------------------------=== #


def _item_user_data[
    I: IO
](
    mut io: I,
    mut nbt_data: NBT,
    mut can_be_placed_on: List[String],
    mut can_break: List[String],
    mut blocking_tick: Int64,
    present: Bool,
    shield: Bool,
) raises:
    if io.reads():
        var extra = List[UInt8]()
        io.byte_slice(extra)
        nbt_data = NBT(List[UInt8](), LITTLE_ENDIAN)
        can_be_placed_on = List[String]()
        can_break = List[String]()
        blocking_tick = 0
        if len(extra) == 0:
            return
        var r = Reader(Span(extra), io.shield_id())
        _item_user_data_body(
            r, nbt_data, can_be_placed_on, can_break, blocking_tick, shield
        )
        return
    if not present:
        var zero = UInt32(0)
        io.varuint32(zero)
        return
    var w = ProtocolWriter(io.shield_id())
    _item_user_data_body(
        w, nbt_data, can_be_placed_on, can_break, blocking_tick, shield
    )
    var extra = w.take()
    io.byte_slice(extra)


def _item_user_data_body[
    I: IO
](
    mut io: I,
    mut nbt_data: NBT,
    mut can_be_placed_on: List[String],
    mut can_break: List[String],
    mut blocking_tick: Int64,
    shield: Bool,
) raises:
    # -1 announces a versioned compound; 0 means no NBT. Readers accept any
    # other value as a bare compound, as gophertunnel does.
    var length = Int16(-1) if _nbt_has_entries(nbt_data) else Int16(0)
    io.int16(length)
    if length == -1:
        var version = UInt8(1)
        io.uint8(version)
        if version != 1:
            unknown_enum_option(Int(version), "item user data version")
        nbt(io, nbt_data, LITTLE_ENDIAN)
    elif length != 0:
        nbt(io, nbt_data, LITTLE_ENDIAN)
    _string_utf_slice_uint32_length(io, can_be_placed_on)
    _string_utf_slice_uint32_length(io, can_break)
    if shield:
        io.int64(blocking_tick)


def _string_utf_slice_uint32_length[
    I: IO
](mut io: I, mut x: List[String]) raises:
    # gophertunnel FuncSliceUint32Length(r, x, r.StringUTF).
    var count = UInt32(len(x))
    io.uint32(count)
    if io.reads():
        io.slice_length(count, MAX_SLICE_LENGTH)
        x = List[String](capacity=Int(count))
        for _ in range(Int(count)):
            var s = String()
            io.string_utf(s)
            x.append(s^)
        return
    for i in range(len(x)):
        io.string_utf(x[i])


def _nbt_has_entries(x: NBT) -> Bool:
    # Go writes the NBT only when the map has entries (`len(m) != 0`), so an
    # empty root compound counts as no NBT.
    if x.is_empty():
        return False
    if x.root_type() != TAG_COMPOUND:
        return True
    var pos: Int
    if x.encoding == NETWORK_LITTLE_ENDIAN:
        var n = 0
        var shift = 0
        pos = 1
        while pos < len(x.raw):
            var b = x.raw[pos]
            pos += 1
            n |= Int(b & 0x7F) << shift
            shift += 7
            if (b & 0x80) == 0 or shift >= 35:
                break
        pos += n
    elif len(x.raw) < 3:
        return True
    elif x.encoding == BIG_ENDIAN:
        pos = 3 + ((Int(x.raw[1]) << 8) | Int(x.raw[2]))
    else:
        pos = 3 + (Int(x.raw[1]) | (Int(x.raw[2]) << 8))
    return pos >= len(x.raw) or x.raw[pos] != TAG_END
