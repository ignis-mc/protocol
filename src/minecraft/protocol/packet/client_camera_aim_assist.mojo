"""The `ClientCameraAimAssist` packet (gophertunnel `packet/client_camera_aim_assist.go`)."""

from ..io import IO
from .id import ID_CLIENT_CAMERA_AIM_ASSIST
from .packet import Packet

comptime CLIENT_CAMERA_AIM_ASSIST_ACTION_SET: UInt8 = 0
"""Go `ClientCameraAimAssistActionSet`."""
comptime CLIENT_CAMERA_AIM_ASSIST_ACTION_CLEAR: UInt8 = 1
"""Go `ClientCameraAimAssistActionClear`."""


struct ClientCameraAimAssist(Packet):
    """Sent by the server to set or clear the client's aim assist preset."""

    comptime ID: UInt32 = ID_CLIENT_CAMERA_AIM_ASSIST
    """The packet ID."""
    var preset_id: String
    """The ID of a preset from `CameraAimAssistPresets`."""
    var action: UInt8
    """One of the `CLIENT_CAMERA_AIM_ASSIST_ACTION_*` values."""
    var allow_aim_assist: Bool
    """Whether the client may use aim assist."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.preset_id = String()
        self.action = 0
        self.allow_aim_assist = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.preset_id)
        io.uint8(self.action)
        io.bool(self.allow_aim_assist)
