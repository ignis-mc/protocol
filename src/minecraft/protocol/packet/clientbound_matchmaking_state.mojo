"""The `ClientboundMatchmakingState` packet (gophertunnel `packet/clientbound_matchmaking_state.go`)."""

from ..io import IO, optional_marshaler
from ..matchmaking import MatchmakingStateOptions
from .id import ID_CLIENTBOUND_MATCHMAKING_STATE
from .packet import Packet

comptime MATCHMAKING_STATE_IDLE: UInt8 = 0
"""Go `MatchmakingStateIdle`."""
comptime MATCHMAKING_STATE_MATCHMAKING: UInt8 = 1
"""Go `MatchmakingStateMatchmaking`."""
comptime MATCHMAKING_STATE_MATCH_FOUND: UInt8 = 2
"""Go `MatchmakingStateMatchFound`."""
comptime MATCHMAKING_STATE_CANCELED: UInt8 = 3
"""Go `MatchmakingStateCanceled`."""
comptime MATCHMAKING_STATE_PLAYER_LEFT_PARTY: UInt8 = 4
"""Go `MatchmakingStatePlayerLeftParty`."""
comptime MATCHMAKING_STATE_PLAYER_LEFT_SERVER: UInt8 = 5
"""Go `MatchmakingStatePlayerLeftServer`."""
comptime MATCHMAKING_STATE_SERVER_SHUTDOWN: UInt8 = 6
"""Go `MatchmakingStateServerShutdown`."""
comptime MATCHMAKING_STATE_TIMED_OUT: UInt8 = 7
"""Go `MatchmakingStateTimedOut`."""
comptime MATCHMAKING_STATE_REQUEUE_AS_PARTY: UInt8 = 8
"""Go `MatchmakingStateRequeueAsParty`."""


struct ClientboundMatchmakingState(Packet):
    """Sent by the server with the client's matchmaking state."""

    comptime ID: UInt32 = ID_CLIENTBOUND_MATCHMAKING_STATE
    """The packet ID."""
    var state: UInt8
    """One of the `MATCHMAKING_STATE_*` values."""
    var destination_name: String
    """The destination the client is matched into."""
    var options: Optional[MatchmakingStateOptions]
    """What triggered the state change."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.state = 0
        self.destination_name = String()
        self.options = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.state)
        io.string(self.destination_name)
        optional_marshaler(io, self.options)
