"""The `CameraAimAssist` packet (gophertunnel `packet/camera_aim_assist.go`)."""

from ..io import IO, vec2
from ..math import Vec2
from .id import ID_CAMERA_AIM_ASSIST
from .packet import Packet

comptime CAMERA_AIM_ASSIST_ACTION_SET: UInt8 = 0
"""Go `CameraAimAssistActionSet`."""
comptime CAMERA_AIM_ASSIST_ACTION_CLEAR: UInt8 = 1
"""Go `CameraAimAssistActionClear`."""


struct CameraAimAssist(Packet):
    """Sent by the server to set up aim assist for the client's camera."""

    comptime ID: UInt32 = ID_CAMERA_AIM_ASSIST
    """The packet ID."""
    var preset: String
    """The ID of a preset from `CameraAimAssistPresets`."""
    var angle: Vec2
    """The maximum angle checked for a target in angle mode."""
    var distance: Float32
    """The maximum distance checked for a target in distance mode."""
    var target_mode: UInt8
    """One of the aim assist target mode values."""
    var action: UInt8
    """One of the `CAMERA_AIM_ASSIST_ACTION_*` values."""
    var show_debug_render: Bool
    """Whether to show the debug render."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.preset = String()
        self.angle = Vec2()
        self.distance = 0
        self.target_mode = 0
        self.action = 0
        self.show_debug_render = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.preset)
        vec2(io, self.angle)
        io.float32(self.distance)
        io.uint8(self.target_mode)
        io.uint8(self.action)
        io.bool(self.show_debug_render)
