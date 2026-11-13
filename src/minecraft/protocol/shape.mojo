"""Debug shapes (gophertunnel `protocol/shape.go`).

The Go `ShapeData` interface becomes the `ShapeData` struct holding a
`ShapeDataVariant` of the ten concrete shapes. Each shape conforms to
`ShapeDataKind`, which carries its wire type ID; `shape_data` (Go
`IO.ShapeData`) writes that ID and dispatches on it when reading.
"""

from std.utils import Variant

from .color import RGBA
from .entities_helpers import marshal_variant, optional_func
from .io import (
    IO,
    Marshaler,
    actor_unique_id,
    be_argb,
    unknown_enum_option,
    vec2,
    vec3,
)
from .math import Vec2, Vec3

comptime SHAPE_DATA_LAST: UInt32 = 0
"""Reuses the last shape settings (`LastShape`)."""
comptime SHAPE_DATA_ARROW: UInt32 = 1
"""An arrow (`ArrowShape`)."""
comptime SHAPE_DATA_TEXT: UInt32 = 2
"""Text (`TextShape`)."""
comptime SHAPE_DATA_BOX: UInt32 = 3
"""A box (`BoxShape`)."""
comptime SHAPE_DATA_LINE: UInt32 = 4
"""A line (`LineShape`)."""
comptime SHAPE_DATA_SPHERE: UInt32 = 5
"""A circle or sphere (`SphereShape`)."""
comptime SHAPE_DATA_CYLINDER: UInt32 = 6
"""A cylinder (`CylinderShape`)."""
comptime SHAPE_DATA_PYRAMID: UInt32 = 7
"""A pyramid (`PyramidShape`)."""
comptime SHAPE_DATA_ELLIPSOID: UInt32 = 8
"""An ellipsoid (`EllipsoidShape`)."""
comptime SHAPE_DATA_CONE: UInt32 = 9
"""A cone (`ConeShape`)."""


trait ShapeDataKind(Marshaler):
    """A concrete debug shape data type."""

    comptime SHAPE_DATA_TYPE: UInt32
    """The wire type ID, one of the `SHAPE_DATA_*` values."""


struct LastShape(ShapeDataKind):
    """Reuses the last shape settings, or the default if none were set."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_LAST
    """The wire type ID."""

    def __init__(out self):
        """Creates the value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.
        """
        pass


struct LineShape(ShapeDataKind):
    """A line."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_LINE
    """The wire type ID."""
    var line_end_location: Vec3
    """The end of the line."""

    def __init__(out self):
        """Creates a zero line."""
        self.line_end_location = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec3(io, self.line_end_location)


struct TextShape(ShapeDataKind):
    """Text."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_TEXT
    """The wire type ID."""
    var text: String
    """The text."""
    var use_rotation: Bool
    """Uses the shape rotation instead of facing the camera."""
    var background_colour: Optional[RGBA]
    """The background colour; translucent black by default."""
    var line_gap_height: Float32
    """The gap between lines of multiline text."""
    var depth_test: Bool
    """Whether the text shows through walls; `True` by default."""
    var show_backface: Bool
    """Whether the background renders on the back side."""
    var show_backface_text: Bool
    """Whether the text renders on the back side."""

    def __init__(out self):
        """Creates empty text."""
        self.text = String()
        self.use_rotation = False
        self.background_colour = None
        self.line_gap_height = 0
        self.depth_test = False
        self.show_backface = False
        self.show_backface_text = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.text)
        io.bool(self.use_rotation)
        optional_func[be_argb[I]](io, self.background_colour)
        io.float32(self.line_gap_height)
        io.bool(self.depth_test)
        io.bool(self.show_backface)
        io.bool(self.show_backface_text)


struct BoxShape(ShapeDataKind):
    """A box."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_BOX
    """The wire type ID."""
    var box_bound: Vec3
    """The bound of the box."""

    def __init__(out self):
        """Creates a zero box."""
        self.box_bound = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec3(io, self.box_bound)


struct SphereShape(ShapeDataKind):
    """A circle or sphere."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_SPHERE
    """The wire type ID."""
    var segments: UInt8
    """The number of segments."""

    def __init__(out self):
        """Creates a zero sphere."""
        self.segments = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.segments)


struct ArrowShape(ShapeDataKind):
    """An arrow."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_ARROW
    """The wire type ID."""
    var arrow_end_location: Optional[Vec3]
    """The end of the arrow."""
    var arrow_head_length: Optional[Float32]
    """The length of the arrow head."""
    var arrow_head_radius: Optional[Float32]
    """The radius of the arrow head."""
    var segments: Optional[UInt8]
    """The number of segments of the arrow head."""

    def __init__(out self):
        """Creates an arrow with nothing set."""
        self.arrow_end_location = None
        self.arrow_head_length = None
        self.arrow_head_radius = None
        self.segments = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        optional_func[vec3[I]](io, self.arrow_end_location)
        optional_func[I.float32](io, self.arrow_head_length)
        optional_func[I.float32](io, self.arrow_head_radius)
        optional_func[I.uint8](io, self.segments)


struct CylinderShape(ShapeDataKind):
    """A cylinder."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_CYLINDER
    """The wire type ID."""
    var radius_x: Vec2
    """The radius along X."""
    var radius_z: Vec2
    """The radius along Z."""
    var height: Float32
    """The height."""
    var num_segments: UInt8
    """The number of segments."""

    def __init__(out self):
        """Creates a zero cylinder."""
        self.radius_x = Vec2()
        self.radius_z = Vec2()
        self.height = 0
        self.num_segments = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec2(io, self.radius_x)
        vec2(io, self.radius_z)
        io.float32(self.height)
        io.uint8(self.num_segments)


struct PyramidShape(ShapeDataKind):
    """A pyramid."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_PYRAMID
    """The wire type ID."""
    var width: Float32
    """The width of the base along X."""
    var depth: Optional[Float32]
    """The depth of the base along Z; defaults to `width`."""
    var height: Float32
    """The height."""

    def __init__(out self):
        """Creates a zero pyramid."""
        self.width = 0
        self.depth = None
        self.height = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.width)
        optional_func[I.float32](io, self.depth)
        io.float32(self.height)


struct EllipsoidShape(ShapeDataKind):
    """An ellipsoid."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_ELLIPSOID
    """The wire type ID."""
    var radii: Vec3
    """The radii along X, Y and Z."""
    var segments_per_axis: UInt8
    """The number of segments per axis."""

    def __init__(out self):
        """Creates a zero ellipsoid."""
        self.radii = Vec3()
        self.segments_per_axis = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec3(io, self.radii)
        io.uint8(self.segments_per_axis)


struct ConeShape(ShapeDataKind):
    """A cone."""

    comptime SHAPE_DATA_TYPE: UInt32 = SHAPE_DATA_CONE
    """The wire type ID."""
    var radii: Vec2
    """The radii of the base along X and Z."""
    var height: Float32
    """The height."""
    var num_segments: UInt8
    """The number of segments."""

    def __init__(out self):
        """Creates a zero cone."""
        self.radii = Vec2()
        self.height = 0
        self.num_segments = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec2(io, self.radii)
        io.float32(self.height)
        io.uint8(self.num_segments)


comptime ShapeDataVariant = Variant[
    LastShape,
    ArrowShape,
    TextShape,
    BoxShape,
    LineShape,
    SphereShape,
    CylinderShape,
    PyramidShape,
    EllipsoidShape,
    ConeShape,
]
"""Every concrete debug shape, in `SHAPE_DATA_*` order."""


def _shape_data_type[*Ts: ShapeDataKind](x: Variant[*Ts]) -> UInt32:
    comptime for i in range(len(Ts)):
        if x.isa[Ts[i]]():
            return Ts[i].SHAPE_DATA_TYPE
    return 0


def _set_shape_data_type[
    *Ts: ShapeDataKind
](mut x: Variant[*Ts], t: UInt32) raises:
    comptime for i in range(len(Ts)):
        if t == Ts[i].SHAPE_DATA_TYPE:
            x = Variant[*Ts](Ts[i]())
            return
    unknown_enum_option(Int(t), "debug shape data type")


struct ShapeData(Marshaler):
    """Data specific to a debug shape type (Go interface `ShapeData`)."""

    var value: ShapeDataVariant
    """The concrete shape."""

    def __init__(out self):
        """Creates a `LastShape`."""
        self.value = LastShape()

    @implicit
    def __init__(out self, var value: ShapeDataVariant):
        """Wraps a concrete shape.

        Args:
            value: The shape.
        """
        self.value = value^

    def shape_data_type(self) -> UInt32:
        """Gets the wire type ID of the held shape.

        Returns:
            One of the `SHAPE_DATA_*` values.
        """
        return _shape_data_type(self.value)

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the type ID and the shape (see `shape_data`).

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the type is unknown.
        """
        shape_data(io, self)


def shape_data[I: IO](mut io: I, mut x: ShapeData) raises:
    """Marshals a varuint32 shape type, then the shape of that type.

    This is gophertunnel `IO.ShapeData`.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The shape data.

    Raises:
        If the input is malformed or the type is unknown.
    """
    var t = x.shape_data_type()
    io.varuint32(t)
    if io.reads():
        _set_shape_data_type(x.value, t)
    marshal_variant(io, x.value)


comptime PRIMITIVE_SHAPE_LINE: UInt8 = 0
"""A line."""
comptime PRIMITIVE_SHAPE_BOX: UInt8 = 1
"""A box."""
comptime PRIMITIVE_SHAPE_SPHERE: UInt8 = 2
"""A sphere."""
comptime PRIMITIVE_SHAPE_CIRCLE: UInt8 = 3
"""A circle."""
comptime PRIMITIVE_SHAPE_TEXT: UInt8 = 4
"""Text."""
comptime PRIMITIVE_SHAPE_ARROW: UInt8 = 5
"""An arrow."""
comptime PRIMITIVE_SHAPE_CYLINDER: UInt8 = 6
"""A cylinder."""
comptime PRIMITIVE_SHAPE_PYRAMID: UInt8 = 7
"""A pyramid."""
comptime PRIMITIVE_SHAPE_ELLIPSOID: UInt8 = 8
"""An ellipsoid."""
comptime PRIMITIVE_SHAPE_CONE: UInt8 = 9
"""A cone."""


struct PrimitiveShape(Marshaler):
    """One shape rendered on the client, identified by its network ID."""

    var network_id: UInt64
    """The network ID of the shape."""
    var dimension_id: Optional[Int32]
    """The dimension the shape renders in."""
    var attached_to_entity_id: Optional[Int64]
    """The unique ID of the entity the shape is attached to."""
    var type: Optional[UInt8]
    """One of the `PRIMITIVE_SHAPE_*` values; unset clears the shape."""
    var location: Optional[Vec3]
    """The location."""
    var scale: Optional[Float32]
    """The scale."""
    var rotation: Optional[Vec3]
    """The rotation."""
    var total_time_left: Optional[Float32]
    """The time left before the shape disappears."""
    var max_render_distance: Optional[Float32]
    """The furthest distance from the camera the shape renders at."""
    var colour: Optional[RGBA]
    """The colour."""
    var extra_shape_data: ShapeData
    """Data specific to the shape type, such as the text of a text shape."""

    def __init__(out self):
        """Creates a shape with nothing set."""
        self.network_id = 0
        self.dimension_id = None
        self.attached_to_entity_id = None
        self.type = None
        self.location = None
        self.scale = None
        self.rotation = None
        self.total_time_left = None
        self.max_render_distance = None
        self.colour = None
        self.extra_shape_data = ShapeData()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the shape; the wire order differs from the fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint64(self.network_id)
        optional_func[I.uint8](io, self.type)
        optional_func[vec3[I]](io, self.location)
        optional_func[I.float32](io, self.scale)
        optional_func[vec3[I]](io, self.rotation)
        optional_func[I.float32](io, self.total_time_left)
        optional_func[I.float32](io, self.max_render_distance)
        optional_func[be_argb[I]](io, self.colour)
        optional_func[I.varint32](io, self.dimension_id)
        optional_func[actor_unique_id[I]](io, self.attached_to_entity_id)
        shape_data(io, self.extra_shape_data)
