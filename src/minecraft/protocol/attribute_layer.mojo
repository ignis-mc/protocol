"""Environment attribute layers (gophertunnel `protocol/attribute_layer.go`).

Go keeps `AttributeData` and `EnvironmentAttributeData` as flat structs with
a type field and one field group per type; so does this port.
"""

from .entities_helpers import optional_func
from .io import IO, Marshaler, slice, unknown_enum_option

comptime ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_LAYERS: UInt32 = 0
"""The payload updates layers."""
comptime ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_SETTINGS: UInt32 = 1
"""The payload updates layer settings."""
comptime ATTRIBUTE_LAYER_PAYLOAD_TYPE_UPDATE_ENVIRONMENT: UInt32 = 2
"""The payload updates environment attributes."""
comptime ATTRIBUTE_LAYER_PAYLOAD_TYPE_REMOVE_ENVIRONMENT: UInt32 = 3
"""The payload removes environment attributes."""

comptime ATTRIBUTE_DATA_TYPE_BOOL: UInt32 = 0
"""A boolean attribute."""
comptime ATTRIBUTE_DATA_TYPE_FLOAT: UInt32 = 1
"""A float attribute."""
comptime ATTRIBUTE_DATA_TYPE_COLOUR: UInt32 = 2
"""A colour attribute."""

comptime ATTRIBUTE_BOOL_OPERATION_OVERRIDE: Int32 = 0
"""Replaces the value."""
comptime ATTRIBUTE_BOOL_OPERATION_ALPHA_BLEND: Int32 = 1
"""Blends by weight."""
comptime ATTRIBUTE_BOOL_OPERATION_AND: Int32 = 2
"""Logical and."""
comptime ATTRIBUTE_BOOL_OPERATION_NAND: Int32 = 3
"""Logical nand."""
comptime ATTRIBUTE_BOOL_OPERATION_OR: Int32 = 4
"""Logical or."""
comptime ATTRIBUTE_BOOL_OPERATION_NOR: Int32 = 5
"""Logical nor."""
comptime ATTRIBUTE_BOOL_OPERATION_XOR: Int32 = 6
"""Logical xor."""
comptime ATTRIBUTE_BOOL_OPERATION_XNOR: Int32 = 7
"""Logical xnor."""

comptime ATTRIBUTE_FLOAT_OPERATION_OVERRIDE: Int32 = 0
"""Replaces the value."""
comptime ATTRIBUTE_FLOAT_OPERATION_ALPHA_BLEND: Int32 = 1
"""Blends by weight."""
comptime ATTRIBUTE_FLOAT_OPERATION_ADD: Int32 = 2
"""Adds."""
comptime ATTRIBUTE_FLOAT_OPERATION_SUBTRACT: Int32 = 3
"""Subtracts."""
comptime ATTRIBUTE_FLOAT_OPERATION_MULTIPLY: Int32 = 4
"""Multiplies."""
comptime ATTRIBUTE_FLOAT_OPERATION_MINIMUM: Int32 = 5
"""Takes the minimum."""
comptime ATTRIBUTE_FLOAT_OPERATION_MAXIMUM: Int32 = 6
"""Takes the maximum."""

comptime ATTRIBUTE_COLOUR_OPERATION_OVERRIDE: Int32 = 0
"""Replaces the colour."""
comptime ATTRIBUTE_COLOUR_OPERATION_ALPHA_BLEND: Int32 = 1
"""Blends by alpha."""
comptime ATTRIBUTE_COLOUR_OPERATION_ADD: Int32 = 2
"""Adds."""
comptime ATTRIBUTE_COLOUR_OPERATION_SUBTRACT: Int32 = 3
"""Subtracts."""
comptime ATTRIBUTE_COLOUR_OPERATION_MULTIPLY: Int32 = 4
"""Multiplies."""

comptime NOISE_ALIGNMENT_TYPE_MIN_LOCAL_TRANSITION_END: UInt8 = 0
"""Aligns the noise to the end of the minimum local transition."""

comptime ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_CONSTANT: UInt32 = 0
"""The attribute holds a constant value."""
comptime ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_TRANSITION: UInt32 = 1
"""The attribute transitions between two values."""
comptime ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_NOISE_TRANSITION: UInt32 = 2
"""The attribute transitions between two values driven by noise."""


struct AttributeData(Marshaler):
    """A polymorphic attribute value: a bool, a float or a colour."""

    var type: UInt32
    """One of the `ATTRIBUTE_DATA_TYPE_*` values."""
    var bool_value: Bool
    """The value for the bool type."""
    var bool_operation: Optional[Int32]
    """The operation for the bool type."""
    var float_value: Float32
    """The value for the float type."""
    var float_operation: Optional[Int32]
    """The operation for the float type."""
    var float_constraint_min: Optional[Float32]
    """The minimum for the float type."""
    var float_constraint_max: Optional[Float32]
    """The maximum for the float type."""
    var colour_value: Int32
    """The value for the colour type."""
    var colour_operation: Optional[Int32]
    """The operation for the colour type."""

    def __init__(out self):
        """Creates a `False` bool attribute."""
        self.type = 0
        self.bool_value = False
        self.bool_operation = None
        self.float_value = 0
        self.float_operation = None
        self.float_constraint_min = None
        self.float_constraint_max = None
        self.colour_value = 0
        self.colour_operation = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the type and the fields of that type.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the type is unknown.
        """
        io.varuint32(self.type)
        if self.type == ATTRIBUTE_DATA_TYPE_BOOL:
            io.bool(self.bool_value)
            optional_func[I.int32](io, self.bool_operation)
        elif self.type == ATTRIBUTE_DATA_TYPE_FLOAT:
            io.float32(self.float_value)
            optional_func[I.int32](io, self.float_operation)
            optional_func[I.float32](io, self.float_constraint_min)
            optional_func[I.float32](io, self.float_constraint_max)
        elif self.type == ATTRIBUTE_DATA_TYPE_COLOUR:
            io.int32(self.colour_value)
            optional_func[I.int32](io, self.colour_operation)
        else:
            unknown_enum_option(Int(self.type), "attribute data type")


struct NoiseAlignment(Marshaler):
    """How the noise of an environment attribute transition is aligned."""

    var type: UInt8
    """One of the `NOISE_ALIGNMENT_TYPE_*` values."""
    var value: UInt32
    """The value the noise is aligned against."""

    def __init__(out self):
        """Creates a zero alignment."""
        self.type = 0
        self.value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the alignment.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.type)
        io.varuint32(self.value)


struct AttributeTransitionSettings(Marshaler):
    """The settings of a transition between two attribute values."""

    var total_transition_ticks: UInt32
    """The total length of the transition in ticks."""
    var current_transition_ticks: UInt32
    """The ticks elapsed in the current transition."""
    var ease_type: Int32
    """One of the `EASING_TYPE_*` values."""
    var clock_name: String
    """The name of the world clock that drives the transition."""

    def __init__(out self):
        """Creates zero settings."""
        self.total_transition_ticks = 0
        self.current_transition_ticks = 0
        self.ease_type = 0
        self.clock_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the settings.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.total_transition_ticks)
        io.varuint32(self.current_transition_ticks)
        io.varint32(self.ease_type)
        io.string(self.clock_name)


struct AttributeNoiseTransitionSettings(Marshaler):
    """The settings of a noise-driven transition between two values."""

    var total_transition_ticks: UInt32
    """The total length of the transition in ticks."""
    var current_transition_ticks: UInt32
    """The ticks elapsed in the current transition."""
    var ease_type: Int32
    """One of the `EASING_TYPE_*` values."""
    var clock_name: String
    """The name of the world clock that drives the transition."""
    var local_transition_ticks: UInt32
    """The ticks elapsed in the local transition."""
    var noise_name: String
    """The name of the noise."""
    var noise_alignment: NoiseAlignment
    """The alignment of the noise."""

    def __init__(out self):
        """Creates zero settings."""
        self.total_transition_ticks = 0
        self.current_transition_ticks = 0
        self.ease_type = 0
        self.clock_name = String()
        self.local_transition_ticks = 0
        self.noise_name = String()
        self.noise_alignment = NoiseAlignment()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the settings.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.total_transition_ticks)
        io.varuint32(self.current_transition_ticks)
        io.varint32(self.ease_type)
        io.string(self.clock_name)
        io.varuint32(self.local_transition_ticks)
        io.string(self.noise_name)
        self.noise_alignment.marshal(io)


struct EnvironmentAttributeData(Marshaler):
    """An environment attribute: a constant or a transition between values."""

    var attribute_name: String
    """The name of the attribute."""
    var payload_type: UInt32
    """One of the `ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_*` values."""
    var attribute: AttributeData
    """The value for the constant payload."""
    var from_attribute: AttributeData
    """The start value for the transition payloads."""
    var to_attribute: AttributeData
    """The target value for the transition payloads."""
    var transition_settings: AttributeTransitionSettings
    """The settings for the transition payload."""
    var noise_transition_settings: AttributeNoiseTransitionSettings
    """The settings for the noise transition payload."""

    def __init__(out self):
        """Creates a constant `False` attribute with no name."""
        self.attribute_name = String()
        self.payload_type = 0
        self.attribute = AttributeData()
        self.from_attribute = AttributeData()
        self.to_attribute = AttributeData()
        self.transition_settings = AttributeTransitionSettings()
        self.noise_transition_settings = AttributeNoiseTransitionSettings()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the name, the payload type and its fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the payload type is unknown.
        """
        io.string(self.attribute_name)
        io.varuint32(self.payload_type)
        if self.payload_type == ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_CONSTANT:
            self.attribute.marshal(io)
        elif self.payload_type == ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_TRANSITION:
            self.from_attribute.marshal(io)
            self.to_attribute.marshal(io)
            self.transition_settings.marshal(io)
        elif (
            self.payload_type
            == ENVIRONMENT_ATTRIBUTE_PAYLOAD_TYPE_NOISE_TRANSITION
        ):
            self.from_attribute.marshal(io)
            self.to_attribute.marshal(io)
            self.noise_transition_settings.marshal(io)
        else:
            unknown_enum_option(
                Int(self.payload_type), "environment attribute payload type"
            )


struct AttributeLayerSettings(Marshaler):
    """The settings of an attribute layer."""

    var priority: Int32
    """The priority of the layer."""
    var float_weight: Float32
    """The weight of the layer."""
    var enabled: Bool
    """Whether the layer is enabled."""
    var transitions_paused: Bool
    """Whether transitions are paused for the layer."""

    def __init__(out self):
        """Creates zero settings."""
        self.priority = 0
        self.float_weight = 0
        self.enabled = False
        self.transitions_paused = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the settings.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int32(self.priority)
        io.float32(self.float_weight)
        io.bool(self.enabled)
        io.bool(self.transitions_paused)


struct AttributeLayerData(Marshaler):
    """A complete attribute layer."""

    var name: String
    """The name of the layer."""
    var dimension_id: Int32
    """The dimension the layer applies to."""
    var settings: AttributeLayerSettings
    """The settings of the layer."""
    var environment_attributes: List[EnvironmentAttributeData]
    """The environment attributes in the layer."""

    def __init__(out self):
        """Creates an empty layer."""
        self.name = String()
        self.dimension_id = 0
        self.settings = AttributeLayerSettings()
        self.environment_attributes = List[EnvironmentAttributeData]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the layer.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        io.varint32(self.dimension_id)
        self.settings.marshal(io)
        slice(io, self.environment_attributes)
