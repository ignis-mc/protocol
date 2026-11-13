"""Audio content registration (gophertunnel `protocol/audio_content.go`)."""

from .io import IO, Marshaler

comptime AUDIO_CONTENT_PLAYBACK_TYPE_MUSIC: StaticString = "Music"
"""Audio content played back as music."""
comptime AUDIO_CONTENT_PLAYBACK_TYPE_SOUND: StaticString = "Sound"
"""Audio content played back as a sound."""


struct AudioContentRegistrationEntry(Marshaler):
    """Service-signed audio content the client registers for the session."""

    var audio_content_id: String
    """The ID of the audio content."""
    var shared_metadata: String
    """A compact JWT of metadata shared by client and server."""
    var server_content: String
    """A compact JWT of content for the server."""
    var playback_content: String
    """A compact JWT of content used for playback."""

    def __init__(out self):
        """Creates a zero value."""
        self.audio_content_id = String()
        self.shared_metadata = String()
        self.server_content = String()
        self.playback_content = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.audio_content_id)
        io.string(self.shared_metadata)
        io.string(self.server_content)
        io.string(self.playback_content)
