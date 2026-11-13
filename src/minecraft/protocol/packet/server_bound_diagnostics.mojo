"""The `ServerBoundDiagnostics` packet (gophertunnel `packet/server_bound_diagnostics.go`).
"""

from ..io import IO, optional_func, slice
from ..memory_category import (
    EntityDiagnosticTimingInfo,
    MemoryCategoryCounter,
    SystemCategory,
    SystemDiagnosticTimingInfo,
    WhiskerScopeDataSummary,
)
from .id import ID_SERVER_BOUND_DIAGNOSTICS
from .packet import Packet


struct ServerBoundDiagnostics(Packet):
    """Sent by the client with its performance diagnostics.

    The client sends it about every 500 ms when "Creator > Enable Client
    Diagnostics" is on. Times are in milliseconds.
    """

    comptime ID: UInt32 = ID_SERVER_BOUND_DIAGNOSTICS
    """The packet ID."""
    var average_frames_per_second: Float32
    """The average frames per second."""
    var average_server_sim_tick_time: Float32
    """The average time the server spends on a tick."""
    var average_client_sim_tick_time: Float32
    """The average time the client spends on a tick."""
    var average_begin_frame_time: Float32
    """The average time spent beginning a frame."""
    var average_input_time: Float32
    """The average time spent processing input."""
    var average_render_time: Float32
    """The average time spent rendering."""
    var average_end_frame_time: Float32
    """The average time spent ending a frame."""
    var average_remainder_time_percent: Float32
    """The average percentage of time spent on other tasks."""
    var average_unaccounted_time_percent: Float32
    """The average percentage of unaccounted time."""
    var memory_category_values: List[MemoryCategoryCounter]
    """Memory category counters."""
    var entity_diagnostics: List[EntityDiagnosticTimingInfo]
    """Entity timing entries."""
    var system_diagnostics: List[SystemDiagnosticTimingInfo]
    """System timing entries."""
    var system_categories: Optional[List[SystemCategory]]
    """Diagnostics category names mapped to system indices, if sent."""
    var whisker_scopes: List[WhiskerScopeDataSummary]
    """Whisker profiler scope summaries."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.average_frames_per_second = 0
        self.average_server_sim_tick_time = 0
        self.average_client_sim_tick_time = 0
        self.average_begin_frame_time = 0
        self.average_input_time = 0
        self.average_render_time = 0
        self.average_end_frame_time = 0
        self.average_remainder_time_percent = 0
        self.average_unaccounted_time_percent = 0
        self.memory_category_values = List[MemoryCategoryCounter]()
        self.entity_diagnostics = List[EntityDiagnosticTimingInfo]()
        self.system_diagnostics = List[SystemDiagnosticTimingInfo]()
        self.system_categories = None
        self.whisker_scopes = List[WhiskerScopeDataSummary]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.average_frames_per_second)
        io.float32(self.average_server_sim_tick_time)
        io.float32(self.average_client_sim_tick_time)
        io.float32(self.average_begin_frame_time)
        io.float32(self.average_input_time)
        io.float32(self.average_render_time)
        io.float32(self.average_end_frame_time)
        io.float32(self.average_remainder_time_percent)
        io.float32(self.average_unaccounted_time_percent)
        slice(io, self.memory_category_values)
        slice(io, self.entity_diagnostics)
        slice(io, self.system_diagnostics)
        optional_func[slice[SystemCategory, I]](io, self.system_categories)
        slice(io, self.whisker_scopes)
