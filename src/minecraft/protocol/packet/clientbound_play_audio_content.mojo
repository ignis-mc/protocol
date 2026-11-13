"""The `ClientboundPlayAudioContent` packet (gophertunnel `packet/clientbound_play_audio_content.go`).

The `Sound` field (a `PlaySound` packet body) is missing until the
`play_sound.mojo` port is merged; until then a full packet decodes with unread
bytes left over.
"""

from ..io import IO
from .id import ID_CLIENTBOUND_PLAY_AUDIO_CONTENT
from .packet import Packet


struct ClientboundPlayAudioContent(Packet):
    """Sent by the server to play signed audio content."""

    comptime ID: UInt32 = ID_CLIENTBOUND_PLAY_AUDIO_CONTENT
    """The packet ID."""
    var shared_metadata: String
    """A compact JWT with the signed metadata."""
    var playback_content: String
    """A compact JWT with the signed playback content."""
    var playback_type: String
    """One of the audio content playback type values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.shared_metadata = String()
        self.playback_content = String()
        self.playback_type = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.shared_metadata)
        io.string(self.playback_content)
        io.string(self.playback_type)
        # TODO(packets3): marshal `sound: PlaySound` here once `play_sound.mojo`
        # is merged: `self.sound.marshal(io)`.
