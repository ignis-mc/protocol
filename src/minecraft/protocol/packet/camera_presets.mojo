"""The `CameraPresets` packet (gophertunnel `packet/camera_presets.go`)."""

from ..camera import CameraPreset
from ..io import IO, slice
from .id import ID_CAMERA_PRESETS
from .packet import Packet


struct CameraPresets(Packet):
    """Gives the client a list of custom camera presets."""

    comptime ID: UInt32 = ID_CAMERA_PRESETS
    """The packet ID."""
    var presets: List[CameraPreset]
    """The presets; instructions refer to them by index."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.presets = List[CameraPreset]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.presets)
