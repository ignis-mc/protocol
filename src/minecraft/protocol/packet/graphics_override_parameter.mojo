"""The `GraphicsOverrideParameter` packet (gophertunnel `packet/graphics_override_parameter.go`)."""

from ..graphics import ParameterKeyframeValue
from ..io import IO, optional_float32, optional_string, optional_vec3, slice
from ..math import Vec3
from .id import ID_GRAPHICS_OVERRIDE_PARAMETER
from .packet import Packet


struct GraphicsOverrideParameter(Packet):
    """Sent by the server to override graphics parameters."""

    comptime ID: UInt32 = ID_GRAPHICS_OVERRIDE_PARAMETER
    """The packet ID."""
    var values: List[ParameterKeyframeValue]
    """A list of parameter keyframe values."""
    var float_value: Optional[Float32]
    """An optional single float graphics parameter to be overridden."""
    var vec3_value: Optional[Vec3]
    """An optional single Vec3 graphics parameter to be overridden."""
    var biome_identifier: String
    """The identifier of the biome for which the parameters apply."""
    var player_identifier: Optional[String]
    """The optional identifier of the player for which the override parameter
    applies.
    """
    var parameter_type: UInt8
    """The type of parameter being overridden."""
    var reset: Bool
    """Whether to reset the parameters."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.values = List[ParameterKeyframeValue]()
        self.float_value = None
        self.vec3_value = None
        self.biome_identifier = String()
        self.player_identifier = None
        self.parameter_type = 0
        self.reset = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.values)
        optional_float32(io, self.float_value)
        optional_vec3(io, self.vec3_value)
        io.string(self.biome_identifier)
        optional_string(io, self.player_identifier)
        io.uint8(self.parameter_type)
        io.bool(self.reset)
