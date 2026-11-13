"""Game data a client learns while joining (gophertunnel `game_data.go`).

The whole `StartGame` packet is kept rather than copying each field.
"""

from .protocol.item import ItemEntry
from .protocol.packet.start_game import StartGame


struct GameData(Copyable, Defaultable):
    """What the server sent while the client joined."""

    var start_game: StartGame
    """The `StartGame` packet."""
    var items: List[ItemEntry]
    """The item registry."""
    var entity_unique_id: Int64
    """The player's unique entity ID."""
    var entity_runtime_id: UInt64
    """The player's runtime entity ID, used in most player packets."""
    var chunk_radius: Int32
    """The view distance the server granted."""

    def __init__(out self):
        """Creates empty game data."""
        self.start_game = StartGame()
        self.items = List[ItemEntry]()
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.chunk_radius = 0
