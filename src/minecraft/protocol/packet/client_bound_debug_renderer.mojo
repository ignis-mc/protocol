"""The `ClientBoundDebugRenderer` packet (gophertunnel `packet/client_bound_debug_renderer.go`)."""

from ..color import RGBA
from ..io import IO, Marshaler, be_argb, invalid_value, optional_marshaler, vec3
from ..math import Vec3
from .id import ID_CLIENT_BOUND_DEBUG_RENDERER
from .packet import Packet

comptime CLIENT_BOUND_DEBUG_RENDERER_CLEAR: UInt32 = 0
"""Go `ClientBoundDebugRendererClear`."""
comptime CLIENT_BOUND_DEBUG_RENDERER_ADD_CUBE: UInt32 = 1
"""Go `ClientBoundDebugRendererAddCube`."""


struct DebugMarkerData(Marshaler):
    """A debug marker cube spawned by `ClientBoundDebugRenderer`."""

    var text: String
    """The text shown above the marker."""
    var position: Vec3
    """The position of the marker."""
    var colour: RGBA
    """The colour of the marker, an ARGB `uint32` on the wire."""
    var duration: UInt64
    """How long the marker lasts, in milliseconds."""

    def __init__(out self):
        """Creates an empty marker."""
        self.text = String()
        self.position = Vec3()
        self.colour = RGBA()
        self.duration = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the marker."""
        io.string(self.text)
        vec3(io, self.position)
        be_argb(io, self.colour)
        io.uint64(self.duration)


struct ClientBoundDebugRenderer(Packet):
    """Sent by the server to spawn an outlined cube client-side."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_DEBUG_RENDERER
    """The packet ID."""
    var type: UInt32
    """One of the `CLIENT_BOUND_DEBUG_RENDERER_*` values."""
    var data: Optional[DebugMarkerData]
    """The marker data, for adding a cube."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.type = 0
        self.data = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        var typ = String(_client_bound_debug_render_to_string(self.type))
        io.string(typ)
        self.type = _client_bound_debug_render_from_string(typ)
        optional_marshaler(io, self.data)


def _client_bound_debug_render_to_string(x: UInt32) -> StaticString:
    if x == CLIENT_BOUND_DEBUG_RENDERER_CLEAR:
        return "cleardebugmarkers"
    if x == CLIENT_BOUND_DEBUG_RENDERER_ADD_CUBE:
        return "adddebugmarkercube"
    return "unknown"


def _client_bound_debug_render_from_string(s: String) raises -> UInt32:
    if s == "cleardebugmarkers":
        return CLIENT_BOUND_DEBUG_RENDERER_CLEAR
    if s == "adddebugmarkercube":
        return CLIENT_BOUND_DEBUG_RENDERER_ADD_CUBE
    invalid_value(s, "type", "unknown type")
    return 0
