"""The `ClientboundPlayAudioContent` packet (gophertunnel `packet/clientbound_play_audio_content.go`)."""

from ..io import IO
from .id import ID_CLIENTBOUND_PLAY_AUDIO_CONTENT
from .packet import Packet
from .play_sound import PlaySound


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
    var sound: PlaySound
    """The sound to play, as a `PlaySound` packet body."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.shared_metadata = String()
        self.playback_content = String()
        self.playback_type = String()
        self.sound = PlaySound()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.shared_metadata)
        io.string(self.playback_content)
        io.string(self.playback_type)
        self.sound.marshal(io)
