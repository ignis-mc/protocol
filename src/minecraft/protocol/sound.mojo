"""Updates to playing sounds (gophertunnel `protocol/sound.go`)."""

from .io import IO, Marshaler, unknown_enum_option

comptime SOUND_DATA_UPDATE_STOP: UInt8 = 0
"""Sound update: Stop."""
comptime SOUND_DATA_UPDATE_SET_VOLUME: UInt8 = 1
"""Sound update: Set Volume."""
comptime SOUND_DATA_UPDATE_SET_PITCH: UInt8 = 2
"""Sound update: Set Pitch."""
comptime SOUND_DATA_UPDATE_FADE: UInt8 = 3
"""Sound update: Fade."""
comptime SOUND_DATA_UPDATE_SEEK_TO: UInt8 = 4
"""Sound update: Seek To."""
comptime SOUND_DATA_UPDATE_PAUSE: UInt8 = 5
"""Sound update: Pause."""
comptime SOUND_DATA_UPDATE_RESUME: UInt8 = 6
"""Sound update: Resume."""


struct SoundDataUpdate(Marshaler):
    """A single change to a playing sound."""

    var type: UInt8
    """One of the `SOUND_DATA_UPDATE_*` values."""
    var volume: Float32
    """The volume, for `SOUND_DATA_UPDATE_SET_VOLUME`."""
    var pitch: Float32
    """The pitch, for `SOUND_DATA_UPDATE_SET_PITCH`."""
    var duration: Float32
    """The fade duration in seconds, for `SOUND_DATA_UPDATE_FADE`."""
    var target_volume: Float32
    """The fade target volume, for `SOUND_DATA_UPDATE_FADE`."""
    var seconds: Float32
    """The position to seek to, for `SOUND_DATA_UPDATE_SEEK_TO`."""

    def __init__(out self):
        """Creates a zero value."""
        self.type = 0
        self.volume = 0
        self.pitch = 0
        self.duration = 0
        self.target_volume = 0
        self.seconds = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the update."""
        io.uint8(self.type)
        if (
            self.type == SOUND_DATA_UPDATE_STOP
            or self.type == SOUND_DATA_UPDATE_PAUSE
            or self.type == SOUND_DATA_UPDATE_RESUME
        ):
            pass
        elif self.type == SOUND_DATA_UPDATE_SET_VOLUME:
            io.float32(self.volume)
        elif self.type == SOUND_DATA_UPDATE_SET_PITCH:
            io.float32(self.pitch)
        elif self.type == SOUND_DATA_UPDATE_FADE:
            io.float32(self.duration)
            io.float32(self.target_volume)
        elif self.type == SOUND_DATA_UPDATE_SEEK_TO:
            io.float32(self.seconds)
        else:
            unknown_enum_option(Int(self.type), "sound data update type")
