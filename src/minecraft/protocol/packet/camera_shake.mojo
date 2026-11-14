"""The `CameraShake` packet (gophertunnel `packet/camera_shake.go`)."""

from ..io import IO
from .id import ID_CAMERA_SHAKE
from .packet import Packet

comptime CAMERA_SHAKE_TYPE_POSITIONAL: UInt8 = 0
"""Go `CameraShakeTypePositional`."""
comptime CAMERA_SHAKE_TYPE_ROTATIONAL: UInt8 = 1
"""Go `CameraShakeTypeRotational`."""
comptime CAMERA_SHAKE_ACTION_ADD: UInt8 = 0
"""Go `CameraShakeActionAdd`."""
comptime CAMERA_SHAKE_ACTION_STOP: UInt8 = 1
"""Go `CameraShakeActionStop`."""


struct CameraShake(Packet):
    """Sent by the server to make the camera shake client-side."""

    comptime ID: UInt32 = ID_CAMERA_SHAKE
    """The packet ID."""
    var intensity: Float32
    """The intensity of the shaking; the client caps it at 4."""
    var duration: Float32
    """The number of seconds to shake for."""
    var type: UInt8
    """One of the `CAMERA_SHAKE_TYPE_*` values."""
    var action: UInt8
    """One of the `CAMERA_SHAKE_ACTION_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.intensity = 0
        self.duration = 0
        self.type = 0
        self.action = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.float32(self.intensity)
        io.float32(self.duration)
        io.uint8(self.type)
        io.uint8(self.action)
