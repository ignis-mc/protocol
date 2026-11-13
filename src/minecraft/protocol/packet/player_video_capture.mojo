"""The `PlayerVideoCapture` packet (gophertunnel `packet/player_video_capture.go`).
"""

from ..io import IO
from .id import ID_PLAYER_VIDEO_CAPTURE
from .packet import Packet

comptime PLAYER_VIDEO_CAPTURE_ACTION_STOP: UInt8 = 0
"""Stops recording."""
comptime PLAYER_VIDEO_CAPTURE_ACTION_START: UInt8 = 1
"""Starts recording."""


struct PlayerVideoCapture(Packet):
    """Sent by the server to start or stop recording frames on the client.

    It only works on development builds; frames are saved as
    `{file_prefix}{index}.png` in `/LocalCache/minecraftpe`.
    """

    comptime ID: UInt32 = ID_PLAYER_VIDEO_CAPTURE
    """The packet ID."""
    var action: UInt8
    """One of the `PLAYER_VIDEO_CAPTURE_ACTION_*` values."""
    var frame_rate: Int32
    """The frame rate, only sent when starting."""
    var file_prefix: String
    """The prefix of the frame file names, only sent when starting."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.action = PLAYER_VIDEO_CAPTURE_ACTION_STOP
        self.frame_rate = 0
        self.file_prefix = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.action)
        if self.action == PLAYER_VIDEO_CAPTURE_ACTION_START:
            io.int32(self.frame_rate)
            io.string(self.file_prefix)
