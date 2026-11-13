"""Matchmaking state details (gophertunnel `protocol/matchmaking.go`)."""

from .io import IO, Marshaler, optional_bool, optional_string


struct MatchmakingStateOptions(Marshaler):
    """What triggered a change in matchmaking state."""

    var triggering_player_name: Optional[String]
    """The player that triggered the change."""
    var triggered_by_local_player: Optional[Bool]
    """Whether the local player triggered it."""

    def __init__(out self):
        """Creates a zero value."""
        self.triggering_player_name = None
        self.triggered_by_local_player = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the options.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        optional_string(io, self.triggering_player_name)
        optional_bool(io, self.triggered_by_local_player)
