"""The `Text` packet (gophertunnel `packet/text.go`)."""

from ..io import IO, invalid_value, optional_string, string_slice
from .id import ID_TEXT
from .packet import Packet

comptime TEXT_TYPE_RAW: UInt8 = 0
"""Plain text."""
comptime TEXT_TYPE_CHAT: UInt8 = 1
"""A chat message from a player."""
comptime TEXT_TYPE_TRANSLATION: UInt8 = 2
"""A translation key with parameters."""
comptime TEXT_TYPE_POPUP: UInt8 = 3
"""A popup above the hotbar."""
comptime TEXT_TYPE_JUKEBOX_POPUP: UInt8 = 4
"""A jukebox "now playing" popup."""
comptime TEXT_TYPE_TIP: UInt8 = 5
"""A tip above the hotbar."""
comptime TEXT_TYPE_SYSTEM: UInt8 = 6
"""A system message."""
comptime TEXT_TYPE_WHISPER: UInt8 = 7
"""A whisper from a player."""
comptime TEXT_TYPE_ANNOUNCEMENT: UInt8 = 8
"""An announcement from a player."""
comptime TEXT_TYPE_OBJECT_WHISPER: UInt8 = 9
"""A JSON text object sent as a whisper."""
comptime TEXT_TYPE_OBJECT: UInt8 = 10
"""A JSON text object."""
comptime TEXT_TYPE_OBJECT_ANNOUNCEMENT: UInt8 = 11
"""A JSON text object sent as an announcement."""

comptime TEXT_CATEGORY_MESSAGE_ONLY: UInt8 = 0
"""The packet carries only a message."""
comptime TEXT_CATEGORY_AUTHORED_MESSAGE: UInt8 = 1
"""The packet carries a source name and a message."""
comptime TEXT_CATEGORY_MESSAGE_WITH_PARAMETERS: UInt8 = 2
"""The packet carries a message and parameters."""


def _is_authored(t: UInt8) -> Bool:
    return (
        t == TEXT_TYPE_CHAT
        or t == TEXT_TYPE_WHISPER
        or t == TEXT_TYPE_ANNOUNCEMENT
    )


def _is_message_only(t: UInt8) -> Bool:
    return (
        t == TEXT_TYPE_RAW
        or t == TEXT_TYPE_TIP
        or t == TEXT_TYPE_SYSTEM
        or t == TEXT_TYPE_OBJECT_WHISPER
        or t == TEXT_TYPE_OBJECT_ANNOUNCEMENT
        or t == TEXT_TYPE_OBJECT
    )


struct Text(Packet):
    """A chat message, a system message, or a translated popup."""

    comptime ID: UInt32 = ID_TEXT
    """The packet ID."""
    var text_type: UInt8
    """One of the `TEXT_TYPE_*` values."""
    var needs_translation: Bool
    """Whether the client should translate the message."""
    var source_name: String
    """The sender's name, for authored messages."""
    var message: String
    """The message, or the translation key."""
    var parameters: List[String]
    """Translation parameters, for translation and popup types."""
    var xuid: String
    """The sender's XUID."""
    var platform_chat_id: String
    """The sender's platform chat ID."""
    var filtered_message: Optional[String]
    """The profanity-filtered message, if any."""

    def __init__(out self):
        """Creates an empty raw message."""
        self.text_type = TEXT_TYPE_RAW
        self.needs_translation = False
        self.source_name = String()
        self.message = String()
        self.parameters = List[String]()
        self.xuid = String()
        self.platform_chat_id = String()
        self.filtered_message = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.needs_translation)
        var category: UInt8
        if _is_message_only(self.text_type):
            category = TEXT_CATEGORY_MESSAGE_ONLY
        elif _is_authored(self.text_type):
            category = TEXT_CATEGORY_AUTHORED_MESSAGE
        else:
            category = TEXT_CATEGORY_MESSAGE_WITH_PARAMETERS
        io.uint8(category)
        io.uint8(self.text_type)
        if _is_authored(self.text_type):
            io.string(self.source_name)
            if self.source_name.byte_length() > 256:
                invalid_value(
                    self.source_name, "source name", "string too long"
                )
            io.string(self.message)
        elif _is_message_only(self.text_type):
            io.string(self.message)
        elif (
            self.text_type == TEXT_TYPE_TRANSLATION
            or self.text_type == TEXT_TYPE_POPUP
            or self.text_type == TEXT_TYPE_JUKEBOX_POPUP
        ):
            io.string(self.message)
            string_slice(io, self.parameters)
            if len(self.parameters) > 4:
                invalid_value("...", "parameters", "too many parameters")
        if self.message.byte_length() == 0:
            invalid_value(self.message, "message", "string cannot be empty")
        if self.message.byte_length() > 65536:
            invalid_value("...", "message", "string too long")
        io.string(self.xuid)
        if self.xuid.byte_length() > 64:
            invalid_value(self.xuid, "XUID", "string too long")
        io.string(self.platform_chat_id)
        if self.platform_chat_id.byte_length() > 256:
            invalid_value(
                self.platform_chat_id, "platform chat ID", "string too long"
            )
        optional_string(io, self.filtered_message)
