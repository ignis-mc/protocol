"""Entity properties (gophertunnel `protocol/entity_properties.go`)."""

from .io import IO, Marshaler, slice


struct IntegerEntityProperty(Marshaler):
    """An entity property with an integer value."""

    var index: UInt32
    """The index of the property."""
    var value: Int32
    """The value of the property."""

    def __init__(out self):
        """Creates a zero property."""
        self.index = 0
        self.value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the property."""
        io.varuint32(self.index)
        io.varint32(self.value)


struct FloatEntityProperty(Marshaler):
    """An entity property with a float value."""

    var index: UInt32
    """The index of the property."""
    var value: Float32
    """The value of the property."""

    def __init__(out self):
        """Creates a zero property."""
        self.index = 0
        self.value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the property."""
        io.varuint32(self.index)
        io.float32(self.value)


struct EntityProperties(Marshaler):
    """The integer and float properties of an entity."""

    var integer_properties: List[IntegerEntityProperty]
    """The properties with integer values."""
    var float_properties: List[FloatEntityProperty]
    """The properties with float values."""

    def __init__(out self):
        """Creates an empty property set."""
        self.integer_properties = List[IntegerEntityProperty]()
        self.float_properties = List[FloatEntityProperty]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes both property lists."""
        slice(io, self.integer_properties)
        slice(io, self.float_properties)
