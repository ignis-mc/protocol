"""The `PlaySound` packet (gophertunnel `packet/play_sound.go`)."""

from ..io import IO, optional_func, sound_pos
from ..math import Vec3
from .id import ID_PLAY_SOUND
from .packet import Packet


struct PlaySound(Packet):
    """Sent by the server to play a sound to the client.

    Some sounds can only be started this way and must be stopped with
    `StopSound`.
    """

    comptime ID: UInt32 = ID_PLAY_SOUND
    """The packet ID."""
    var sound_name: String
    """The name of the sound."""
    var position: Vec3
    """Where the sound plays, sent in 1/8 block units."""
    var volume: Float32
    """The relative volume."""
    var pitch: Float32
    """The pitch."""
    var loop_count: Int32
    """How many times to loop the sound; -1 means no looping."""
    var bypass_listener_range_check: Bool
    """Whether the sound plays regardless of the player's distance."""
    var handle: Optional[UInt64]
    """An optional sound handle."""
    var playback_position_seconds: Optional[Float32]
    """An optional offset in seconds to start playback at."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.sound_name = String()
        self.position = Vec3()
        self.volume = 0
        self.pitch = 0
        self.loop_count = 0
        self.bypass_listener_range_check = False
        self.handle = None
        self.playback_position_seconds = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.sound_name)
        sound_pos(io, self.position)
        io.float32(self.volume)
        io.float32(self.pitch)
        io.varint32(self.loop_count)
        io.bool(self.bypass_listener_range_check)
        optional_func[I.uint64](io, self.handle)
        optional_func[I.float32](io, self.playback_position_seconds)
