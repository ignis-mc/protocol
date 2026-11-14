"""The `CameraAimAssistPresets` packet (gophertunnel `packet/camera_aim_assist_presets.go`).

Go misspells the operation constants as `CameraAunAssistPresetOperation*`; here
they are `CAMERA_AIM_ASSIST_PRESET_OPERATION_*`.
"""

from ..camera import CameraAimAssistCategory, CameraAimAssistPreset
from ..io import IO, slice
from .id import ID_CAMERA_AIM_ASSIST_PRESETS
from .packet import Packet

comptime CAMERA_AIM_ASSIST_PRESET_OPERATION_SET: UInt8 = 0
"""Go `CameraAunAssistPresetOperationSet`."""
comptime CAMERA_AIM_ASSIST_PRESET_OPERATION_ADD_TO_EXISTING: UInt8 = 1
"""Go `CameraAunAssistPresetOperationAddToExisting`."""


struct CameraAimAssistPresets(Packet):
    """Sent by the server with the aim assist categories and presets."""

    comptime ID: UInt32 = ID_CAMERA_AIM_ASSIST_PRESETS
    """The packet ID."""
    var categories: List[CameraAimAssistCategory]
    """The categories the presets may reference."""
    var presets: List[CameraAimAssistPreset]
    """The presets defining aim assist behaviour."""
    var operation: UInt8
    """One of the `CAMERA_AIM_ASSIST_PRESET_OPERATION_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.categories = List[CameraAimAssistCategory]()
        self.presets = List[CameraAimAssistPreset]()
        self.operation = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.categories)
        slice(io, self.presets)
        io.uint8(self.operation)
