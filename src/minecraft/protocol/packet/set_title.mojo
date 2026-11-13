"""The `SetTitle` packet (gophertunnel `packet/set_title.go`)."""

from ..io import IO
from .id import ID_SET_TITLE
from .packet import Packet

comptime TITLE_ACTION_CLEAR: Int32 = 0
"""Title action: clear."""
comptime TITLE_ACTION_RESET: Int32 = 1
"""Title action: reset."""
comptime TITLE_ACTION_SET_TITLE: Int32 = 2
"""Title action: set title."""
comptime TITLE_ACTION_SET_SUBTITLE: Int32 = 3
"""Title action: set subtitle."""
comptime TITLE_ACTION_SET_ACTION_BAR: Int32 = 4
"""Title action: set action bar."""
comptime TITLE_ACTION_SET_DURATIONS: Int32 = 5
"""Title action: set durations."""
comptime TITLE_ACTION_TITLE_TEXT_OBJECT: Int32 = 6
"""Title action: title text object."""
comptime TITLE_ACTION_SUBTITLE_TEXT_OBJECT: Int32 = 7
"""Title action: subtitle text object."""
comptime TITLE_ACTION_ACTIONBAR_TEXT_OBJECT: Int32 = 8
"""Title action: actionbar text object."""


struct SetTitle(Packet):
    """Sent by the server to show a title, subtitle or action bar."""

    comptime ID: UInt32 = ID_SET_TITLE
    """The packet ID."""
    var action_type: Int32
    """One of the `TITLE_ACTION_*` values."""
    var text: String
    """The text to show."""
    var fade_in_duration: Int32
    """The fade-in time in ticks."""
    var remain_duration: Int32
    """The time the title stays in ticks."""
    var fade_out_duration: Int32
    """The fade-out time in ticks."""
    var xuid: String
    """The XUID of the source player."""
    var platform_online_id: String
    """The platform online ID of the source player."""
    var filtered_message: String
    """The profanity-filtered text."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_type = 0
        self.text = String()
        self.fade_in_duration = 0
        self.remain_duration = 0
        self.fade_out_duration = 0
        self.xuid = String()
        self.platform_online_id = String()
        self.filtered_message = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.action_type)
        io.string(self.text)
        io.varint32(self.fade_in_duration)
        io.varint32(self.remain_duration)
        io.varint32(self.fade_out_duration)
        io.string(self.xuid)
        io.string(self.platform_online_id)
        io.string(self.filtered_message)
