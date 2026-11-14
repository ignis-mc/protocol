"""The `SyncWorldClocks` packet (gophertunnel `packet/sync_world_clocks.go`)."""

from ..clock import (
    CLOCK_PAYLOAD_TYPE_ADD_TIME_MARKER,
    CLOCK_PAYLOAD_TYPE_INITIALIZE_REGISTRY,
    CLOCK_PAYLOAD_TYPE_REMOVE_TIME_MARKER,
    CLOCK_PAYLOAD_TYPE_SYNC_STATE,
    SyncWorldClockStateData,
    TimeMarkerData,
    WorldClockData,
)
from ..io import IO, slice, unknown_enum_option, varuint64_slice
from .id import ID_SYNC_WORLD_CLOCKS
from .packet import Packet


struct SyncWorldClocks(Packet):
    """Sent by the server to set up and synchronise world clocks."""

    comptime ID: UInt32 = ID_SYNC_WORLD_CLOCKS
    """The packet ID."""
    var payload_type: UInt32
    """One of the `CLOCK_PAYLOAD_TYPE_*` values."""
    var sync_states: List[SyncWorldClockStateData]
    """Clock states, for a sync payload."""
    var clocks: List[WorldClockData]
    """Every clock, for a registry payload."""
    var add_clock_id: UInt64
    """The clock that gets the markers in `add_time_markers`."""
    var add_time_markers: List[TimeMarkerData]
    """Markers to add."""
    var remove_clock_id: UInt64
    """The clock that loses `remove_time_marker_ids`."""
    var remove_time_marker_ids: List[UInt64]
    """IDs of the markers to remove."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.payload_type = 0
        self.sync_states = List[SyncWorldClockStateData]()
        self.clocks = List[WorldClockData]()
        self.add_clock_id = 0
        self.add_time_markers = List[TimeMarkerData]()
        self.remove_clock_id = 0
        self.remove_time_marker_ids = List[UInt64]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varuint32(self.payload_type)
        if self.payload_type == CLOCK_PAYLOAD_TYPE_SYNC_STATE:
            slice(io, self.sync_states)
        elif self.payload_type == CLOCK_PAYLOAD_TYPE_INITIALIZE_REGISTRY:
            slice(io, self.clocks)
        elif self.payload_type == CLOCK_PAYLOAD_TYPE_ADD_TIME_MARKER:
            io.varuint64(self.add_clock_id)
            slice(io, self.add_time_markers)
        elif self.payload_type == CLOCK_PAYLOAD_TYPE_REMOVE_TIME_MARKER:
            io.varuint64(self.remove_clock_id)
            varuint64_slice(io, self.remove_time_marker_ids)
        else:
            unknown_enum_option(Int(self.payload_type), "clock payload type")
