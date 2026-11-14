"""World clocks (gophertunnel `protocol/clock.go`)."""

from .io import IO, Marshaler, optional_int32, slice

comptime CLOCK_PAYLOAD_TYPE_SYNC_STATE: UInt32 = 0
"""World clock payload: Sync State."""
comptime CLOCK_PAYLOAD_TYPE_INITIALIZE_REGISTRY: UInt32 = 1
"""World clock payload: Initialize Registry."""
comptime CLOCK_PAYLOAD_TYPE_ADD_TIME_MARKER: UInt32 = 2
"""World clock payload: Add Time Marker."""
comptime CLOCK_PAYLOAD_TYPE_REMOVE_TIME_MARKER: UInt32 = 3
"""World clock payload: Remove Time Marker."""


struct SyncWorldClockStateData(Marshaler):
    """The state used to synchronise a world clock."""

    var clock_id: UInt64
    """The clock's identifier."""
    var time: Int32
    """The clock's current time."""
    var paused: Bool
    """Whether the clock is paused."""

    def __init__(out self):
        """Creates a zero value."""
        self.clock_id = 0
        self.time = 0
        self.paused = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value."""
        io.varuint64(self.clock_id)
        io.varint32(self.time)
        io.bool(self.paused)


struct TimeMarkerData(Marshaler):
    """A time marker of a world clock."""

    var id: UInt64
    """The marker's identifier."""
    var name: String
    """The marker's name."""
    var time: Int32
    """The time the marker is set at."""
    var period: Optional[Int32]
    """The marker's period, if any."""

    def __init__(out self):
        """Creates a zero value."""
        self.id = 0
        self.name = String()
        self.time = 0
        self.period = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value."""
        io.varuint64(self.id)
        io.string(self.name)
        io.varint32(self.time)
        optional_int32(io, self.period)


struct WorldClockData(Marshaler):
    """A world clock with its time markers."""

    var id: UInt64
    """The clock's identifier."""
    var name: String
    """The clock's name."""
    var time: Int32
    """The clock's current time."""
    var paused: Bool
    """Whether the clock is paused."""
    var time_markers: List[TimeMarkerData]
    """The clock's time markers."""

    def __init__(out self):
        """Creates a zero value."""
        self.id = 0
        self.name = String()
        self.time = 0
        self.paused = False
        self.time_markers = List[TimeMarkerData]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value."""
        io.varuint64(self.id)
        io.string(self.name)
        io.varint32(self.time)
        io.bool(self.paused)
        slice(io, self.time_markers)
