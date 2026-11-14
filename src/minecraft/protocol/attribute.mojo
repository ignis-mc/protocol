"""Entity attributes (gophertunnel `protocol/attribute.go`)."""

from .io import IO, Marshaler, slice

comptime ATTRIBUTE_MODIFIER_OPERATION_ADDITION: Int32 = 0
"""Adds the amount to the value."""
comptime ATTRIBUTE_MODIFIER_OPERATION_MULTIPLY_BASE: Int32 = 1
"""Multiplies the base value by the amount."""
comptime ATTRIBUTE_MODIFIER_OPERATION_MULTIPLY_TOTAL: Int32 = 2
"""Multiplies the total value by the amount."""
comptime ATTRIBUTE_MODIFIER_OPERATION_CAP: Int32 = 3
"""Caps the value at the amount."""

comptime ATTRIBUTE_MODIFIER_OPERAND_MIN: Int32 = 0
"""The modifier applies to the minimum."""
comptime ATTRIBUTE_MODIFIER_OPERAND_MAX: Int32 = 1
"""The modifier applies to the maximum."""
comptime ATTRIBUTE_MODIFIER_OPERAND_CURRENT: Int32 = 2
"""The modifier applies to the current value."""


struct AttributeValue(Marshaler):
    """The value of an attribute with its bounds."""

    var name: String
    """The attribute name, such as `minecraft:health`."""
    var value: Float32
    """The current value."""
    var max: Float32
    """The upper bound of the value."""
    var min: Float32
    """The lower bound of the value."""

    def __init__(out self):
        """Creates a zero attribute value."""
        self.name = String()
        self.value = 0
        self.max = 0
        self.min = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value; the wire order is min, value, max."""
        io.string(self.name)
        io.float32(self.min)
        io.float32(self.value)
        io.float32(self.max)


struct AttributeModifier(Marshaler):
    """Buffs or debuffs an attribute until it is used, mostly for effects."""

    var id: String
    """The unique ID of the modifier."""
    var name: String
    """The name of the modified attribute."""
    var amount: Float32
    """The difference between the current and the new value."""
    var operation: Int32
    """One of the `ATTRIBUTE_MODIFIER_OPERATION_*` values."""
    var operand: Int32
    """One of the `ATTRIBUTE_MODIFIER_OPERAND_*` values."""
    var serializable: Bool
    """Purpose unknown."""

    def __init__(out self):
        """Creates a zero modifier."""
        self.id = String()
        self.name = String()
        self.amount = 0
        self.operation = 0
        self.operand = 0
        self.serializable = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the modifier."""
        io.string(self.id)
        io.string(self.name)
        io.float32(self.amount)
        io.int32(self.operation)
        io.int32(self.operand)
        io.bool(self.serializable)


struct Attribute(Marshaler):
    """An entity attribute such as health, with defaults and modifiers.

    Go embeds `AttributeValue`; its four fields come first here.
    """

    var name: String
    """The attribute name, such as `minecraft:health`."""
    var value: Float32
    """The current value."""
    var max: Float32
    """The upper bound of the value."""
    var min: Float32
    """The lower bound of the value."""
    var default_min: Float32
    """The default lower bound."""
    var default_max: Float32
    """The default upper bound."""
    var default: Float32
    """The default value."""
    var modifiers: List[AttributeModifier]
    """The modifiers applied to the attribute."""

    def __init__(out self):
        """Creates a zero attribute."""
        self.name = String()
        self.value = 0
        self.max = 0
        self.min = 0
        self.default_min = 0
        self.default_max = 0
        self.default = 0
        self.modifiers = List[AttributeModifier]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the attribute."""
        io.float32(self.min)
        io.float32(self.max)
        io.float32(self.value)
        io.float32(self.default_min)
        io.float32(self.default_max)
        io.float32(self.default)
        io.string(self.name)
        slice(io, self.modifiers)
