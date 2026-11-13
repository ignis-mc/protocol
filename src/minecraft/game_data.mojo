"""Game data a client learns while joining (gophertunnel `game_data.go`).

TODO: fill the remaining `StartGame` fields once the full packet is ported.
"""


struct GameData(Copyable, Defaultable):
    """The parts of `StartGame` and the join sequence a client keeps."""

    var entity_unique_id: Int64
    """The player's unique entity ID."""
    var entity_runtime_id: UInt64
    """The player's runtime entity ID, used in most player packets."""
    var chunk_radius: Int32
    """The view distance the server granted."""

    def __init__(out self):
        """Creates empty game data."""
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.chunk_radius = 0
