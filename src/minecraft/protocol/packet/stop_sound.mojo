"""The `StopSound` packet (gophertunnel `packet/stop_sound.go`)."""

from ..io import IO
from .id import ID_STOP_SOUND
from .packet import Packet


struct StopSound(Packet):
    """Sent by the server to stop a sound playing to the player."""

    comptime ID: UInt32 = ID_STOP_SOUND
    """The packet ID."""
    var sound_name: String
    """The name of the sound to stop."""
    var stop_all: Bool
    """Whether every sound is stopped."""
    var stop_music_legacy: Bool
    """Whether legacy music is stopped too."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.sound_name = String()
        self.stop_all = False
        self.stop_music_legacy = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.sound_name)
        io.bool(self.stop_all)
        io.bool(self.stop_music_legacy)
