"""What a listener announces about itself (gophertunnel
`server_status_provider.go`).

gophertunnel formats a RakNet pong string from the status; NetherNet's HTTP
endpoint and LAN discovery parse it back into their own shapes. There is no
RakNet here, so `ServerStatus` converts to those shapes directly:
`endpoint_status()` for `GET /v1/join` and `server_data()` for LAN
discovery, with the same field mapping (the sub-name becomes the level name).

The pong string carries the game type by name, and go-nethernet only parses
survival, creative and adventure, so a spectator server's status is never
updated there. Here spectator is announced as survival, the closest mode
both shapes can carry.

`ForeignStatusProvider` pings another server over RakNet and is not ported.
"""

from nethernet.discovery.server_data import ServerData
from nethernet.signaling.endpoint import EndpointStatus

from .protocol.info import CURRENT_PROTOCOL, CURRENT_VERSION
from .protocol.packet.set_player_game_type import (
    GAME_TYPE_ADVENTURE,
    GAME_TYPE_CREATIVE,
    GAME_TYPE_SPECTATOR,
)


struct ServerStatus(Copyable, Defaultable):
    """The status shown in the server list."""

    var server_name: String
    """The name, the first line in the server list."""
    var server_sub_name: String
    """The second line; NetherNet shows it as the level name."""
    var player_count: Int
    """The number of players online."""
    var max_players: Int
    """The player limit."""
    var game_type: Int
    """The game mode, one of the `GAME_TYPE_*` constants."""

    def __init__(out self):
        """Creates an empty status."""
        self.server_name = String()
        self.server_sub_name = String()
        self.player_count = 0
        self.max_players = 0
        self.game_type = 0

    def endpoint_status(self) -> EndpointStatus:
        """Converts the status to the body of the HTTP `GET /v1/join` probe.

        Returns:
            The status as go-nethernet's endpoint derives it from the pong.
        """
        var s = EndpointStatus()
        s.name = self.server_name.copy()
        s.protocol = Int(CURRENT_PROTOCOL)
        s.version = String(CURRENT_VERSION)
        s.level = self.server_sub_name.copy()
        s.players = self.player_count
        s.max_players = self.max_players
        s.game_type = _nethernet_game_type(self.game_type)
        return s^

    def server_data(self) -> ServerData:
        """Converts the status to the LAN discovery server data.

        go-nethernet leaves the protocol and version empty; they are filled
        here so that clients can tell whether they can join.

        Returns:
            The server data.
        """
        var d = ServerData()
        d.server_name = self.server_name.copy()
        d.protocol = CURRENT_PROTOCOL
        d.version = String(CURRENT_VERSION)
        d.level_name = self.server_sub_name.copy()
        d.player_count = Int32(self.player_count)
        d.max_player_count = Int32(self.max_players)
        d.game_type = Int32(_nethernet_game_type(self.game_type))
        return d^


def _nethernet_game_type(game_type: Int) -> Int:
    if game_type == Int(GAME_TYPE_CREATIVE):
        return 1
    if game_type == Int(GAME_TYPE_ADVENTURE):
        return 2
    return 0


def game_type_name(game_type: Int) -> String:
    """Names a game type as the pong string does (`gameTypeName`).

    Args:
        game_type: One of the `GAME_TYPE_*` constants.

    Returns:
        `Creative`, `Adventure`, `Spectator` or `Survival`.
    """
    if game_type == Int(GAME_TYPE_CREATIVE):
        return "Creative"
    if game_type == Int(GAME_TYPE_ADVENTURE):
        return "Adventure"
    if game_type == Int(GAME_TYPE_SPECTATOR):
        return "Spectator"
    return "Survival"


struct ListenerStatusProvider(Copyable, Defaultable):
    """The default status provider: a fixed name and sub-name with the
    listener's player counts."""

    var name: String
    """The server name."""
    var sub_name: String
    """The sub-name."""

    def __init__(out self):
        """Creates the provider gophertunnel's listener uses by default."""
        self.name = "Minecraft Server"
        self.sub_name = "Gophertunnel"

    def __init__(
        out self, var server_name: String, var server_sub_name: String
    ):
        """Creates a provider (`NewStatusProvider`).

        Args:
            server_name: The name shown in the server list.
            server_sub_name: The sub-name.
        """
        self.name = server_name^
        self.sub_name = server_sub_name^

    def server_status(
        self, player_count: Int, max_players: Int
    ) -> ServerStatus:
        """Builds the status for the current player counts.

        Args:
            player_count: The players online.
            max_players: The player limit, 0 for none.

        Returns:
            The status.
        """
        var s = ServerStatus()
        s.server_name = self.name.copy()
        s.server_sub_name = self.sub_name.copy()
        s.player_count = player_count
        s.max_players = max_players
        return s^
