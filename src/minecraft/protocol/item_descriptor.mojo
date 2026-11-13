"""Item descriptors (gophertunnel `protocol/item_descriptor.go`).

Go's `ItemDescriptor` interface becomes `ItemDescriptor`, a struct holding a
`Variant` of the four concrete descriptors. Each concrete descriptor carries
its wire type ID as `comptime ID`. The two `ItemDescriptorCount` encodings
(gophertunnel `IO.ItemDescriptorCount` and `StackRequestItemDescriptorCount`)
are the free functions `item_descriptor_count` and
`stack_request_item_descriptor_count`.
"""

from std.builtin.rebind import downcast
from std.utils import Variant

from .io import IO, Marshaler, unknown_enum_option

comptime ITEM_DESCRIPTOR_INVALID: UInt8 = 0
"""The type ID of `InvalidItemDescriptor`."""
comptime ITEM_DESCRIPTOR_DEFAULT: UInt8 = 1
"""The type ID of `DefaultItemDescriptor`."""
comptime ITEM_DESCRIPTOR_MO_LANG: UInt8 = 2
"""The type ID of `MoLangItemDescriptor`."""
comptime ITEM_DESCRIPTOR_ITEM_TAG: UInt8 = 3
"""The type ID of `ItemTagItemDescriptor`."""

# The aux value the game writes after invalid and item tag descriptors.
comptime _DESCRIPTOR_AUX: Int32 = 32767


trait ItemDescriptorKind(Marshaler):
    """A concrete item descriptor: one implementation of Go's `ItemDescriptor`.
    """

    comptime ID: UInt8
    """The descriptor's type ID, one of the `ITEM_DESCRIPTOR_*` constants."""
    comptime NAME: StaticString
    """The descriptor's name in the `IO.ItemDescriptorCount` encoding."""


struct InvalidItemDescriptor(ItemDescriptorKind):
    """An invalid descriptor, sent by vanilla for empty slots or ingredients."""

    comptime ID: UInt8 = ITEM_DESCRIPTOR_INVALID
    """The descriptor's type ID."""
    comptime NAME: StaticString = "empty"
    """The descriptor's name."""

    def __init__(out self):
        """Creates the descriptor."""
        pass

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes nothing: the descriptor has no fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            Never; `Marshaler` requires the signature.
        """
        pass


struct DefaultItemDescriptor(ItemDescriptorKind):
    """A descriptor for regular items, used for most items."""

    comptime ID: UInt8 = ITEM_DESCRIPTOR_DEFAULT
    """The descriptor's type ID."""
    comptime NAME: StaticString = "name"
    """The descriptor's name."""
    var name: String
    """The item identifier, such as `minecraft:stone`."""
    var metadata_value: Int32
    """The metadata (damage or variant) value of the item."""

    def __init__(out self):
        """Creates a descriptor with an empty name."""
        self.name = String()
        self.metadata_value = 0

    def __init__(out self, var name: String, metadata_value: Int32):
        """Creates a descriptor.

        Args:
            name: The item identifier.
            metadata_value: The metadata value.
        """
        self.name = name^
        self.metadata_value = metadata_value

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the descriptor.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        io.varint32(self.metadata_value)


struct MoLangItemDescriptor(ItemDescriptorKind):
    """A descriptor for items matched by a MoLang expression."""

    comptime ID: UInt8 = ITEM_DESCRIPTOR_MO_LANG
    """The descriptor's type ID."""
    comptime NAME: StaticString = "molang"
    """The descriptor's name."""
    var expression: String
    """The MoLang expression that identifies the item or its tag."""
    var version: Int16
    """The MoLang version to use."""

    def __init__(out self):
        """Creates a descriptor with an empty expression."""
        self.expression = String()
        self.version = 0

    def __init__(out self, var expression: String, version: Int16):
        """Creates a descriptor.

        Args:
            expression: The MoLang expression.
            version: The MoLang version.
        """
        self.expression = expression^
        self.version = version

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the descriptor.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.expression)
        io.int16(self.version)


struct ItemTagItemDescriptor(ItemDescriptorKind):
    """A descriptor that matches every item with a tag."""

    comptime ID: UInt8 = ITEM_DESCRIPTOR_ITEM_TAG
    """The descriptor's type ID."""
    comptime NAME: StaticString = "item_tag"
    """The descriptor's name."""
    var tag: String
    """The tag the item is part of."""

    def __init__(out self):
        """Creates a descriptor with an empty tag."""
        self.tag = String()

    def __init__(out self, var tag: String):
        """Creates a descriptor.

        Args:
            tag: The item tag.
        """
        self.tag = tag^

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the descriptor.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.tag)


struct ItemDescriptor(Marshaler):
    """One of the concrete item descriptors (Go's `ItemDescriptor` interface).

    `marshal` reads or writes only the held descriptor's fields, like Go's
    `ItemDescriptor.Marshal`; the type ID is part of the enclosing encoding.
    """

    comptime Kinds = Variant[
        InvalidItemDescriptor,
        DefaultItemDescriptor,
        MoLangItemDescriptor,
        ItemTagItemDescriptor,
    ]
    """The concrete descriptor types."""
    var value: Self.Kinds
    """The held descriptor."""

    def __init__(out self):
        """Creates an invalid descriptor (Go's `nil`)."""
        self.value = InvalidItemDescriptor()

    @implicit
    def __init__[T: ItemDescriptorKind](out self, var value: T):
        """Wraps a concrete descriptor.

        Parameters:
            T: The descriptor type.

        Args:
            value: The descriptor.
        """
        self.value = Self.Kinds(value^)

    def type_id(self) -> UInt8:
        """Gets the type ID of the held descriptor.

        Returns:
            One of the `ITEM_DESCRIPTOR_*` constants.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[Self.Kinds.Ts[i], ItemDescriptorKind]
            if self.value.isa[T]():
                return T.ID
        return ITEM_DESCRIPTOR_INVALID

    def type_name(self) -> String:
        """Gets the name of the held descriptor in the default encoding.

        Returns:
            `empty`, `name`, `molang` or `item_tag`.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[Self.Kinds.Ts[i], ItemDescriptorKind]
            if self.value.isa[T]():
                return String(T.NAME)
        return String(InvalidItemDescriptor.NAME)

    @staticmethod
    def from_type(id: UInt8) -> Optional[ItemDescriptor]:
        """Creates an empty descriptor of a type (Go `itemDescriptorFromType`).

        Args:
            id: One of the `ITEM_DESCRIPTOR_*` constants.

        Returns:
            The descriptor, or `None` for an unknown type ID.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[Self.Kinds.Ts[i], ItemDescriptorKind]
            if id == T.ID:
                return ItemDescriptor(T())
        return None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the held descriptor's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        comptime for i in range(len(Self.Kinds.Ts)):
            comptime T = downcast[Self.Kinds.Ts[i], ItemDescriptorKind]
            if self.value.isa[T]():
                self.value[T].marshal(io)
                return


struct ItemDescriptorCount(Marshaler):
    """An item descriptor with a count, such as a recipe ingredient.

    `marshal` uses the default encoding (`item_descriptor_count`).
    """

    var descriptor: ItemDescriptor
    """How the item is described."""
    var count: Int32
    """The number of items required."""

    def __init__(out self):
        """Creates an invalid descriptor with a zero count."""
        self.descriptor = ItemDescriptor()
        self.count = 0

    def __init__(out self, var descriptor: ItemDescriptor, count: Int32):
        """Creates a descriptor with a count.

        Args:
            descriptor: The descriptor.
            count: The count.
        """
        self.descriptor = descriptor^
        self.count = count

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the descriptor in the default encoding.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        item_descriptor_count(io, self)


def item_descriptor_count[I: IO](mut io: I, mut x: ItemDescriptorCount) raises:
    """Marshals an item descriptor with a count.

    This is gophertunnel `IO.ItemDescriptorCount`.

    Only invalid and default descriptors have their own variant; the others
    are sent as the default variant followed by their name. The aux value
    after invalid and item tag descriptors is written as 32767 and ignored
    when reading.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the variant or descriptor name is unknown, or the input is
        malformed.
    """
    var variant = UInt32(min(x.descriptor.type_id(), ITEM_DESCRIPTOR_DEFAULT))
    io.varuint32(variant)
    if variant == UInt32(ITEM_DESCRIPTOR_INVALID):
        if io.reads():
            x.descriptor = InvalidItemDescriptor()
        var aux = _DESCRIPTOR_AUX
        io.varint32(aux)
    else:
        if variant != UInt32(ITEM_DESCRIPTOR_DEFAULT):
            unknown_enum_option(Int(variant), "item descriptor variant")
        var name = x.descriptor.type_name()
        io.string(name)
        if io.reads():
            var id: UInt8
            if name == DefaultItemDescriptor.NAME:
                id = ITEM_DESCRIPTOR_DEFAULT
            elif name == MoLangItemDescriptor.NAME:
                id = ITEM_DESCRIPTOR_MO_LANG
            elif name == ItemTagItemDescriptor.NAME:
                id = ITEM_DESCRIPTOR_ITEM_TAG
            else:
                raise Error(
                    t"unknown value '{name}' for enum type 'item descriptor"
                    t" type'"
                )
            x.descriptor = ItemDescriptor.from_type(id).value().copy()
        x.descriptor.marshal(io)
        if x.descriptor.type_id() == ITEM_DESCRIPTOR_ITEM_TAG:
            var aux = _DESCRIPTOR_AUX
            io.varint32(aux)
    io.varint32(x.count)


def stack_request_item_descriptor_count[
    I: IO
](mut io: I, mut x: ItemDescriptorCount) raises:
    """Marshals the descriptor encoding used by auto-craft actions.

    This is gophertunnel `StackRequestItemDescriptorCount`: a varuint32
    variant, the same ID as a byte, the descriptor and a `uint16` count.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The value.

    Raises:
        If the descriptor type is unknown or the input is malformed.
    """
    var id = x.descriptor.type_id()
    var variant = UInt32(id)
    io.varuint32(variant)
    var legacy_id = id
    io.uint8(legacy_id)
    if variant > UInt32(ITEM_DESCRIPTOR_ITEM_TAG):
        unknown_enum_option(Int(variant), "stack request item descriptor type")
    if UInt32(id) != variant:
        x.descriptor = ItemDescriptor.from_type(UInt8(variant)).value().copy()
    x.descriptor.marshal(io)
    var count = UInt16(x.count)
    io.uint16(count)
    x.count = Int32(count)
