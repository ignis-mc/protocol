"""The `ServerPlayerPostMovePosition` packet (gophertunnel `packet/server_player_post_move_position.go`).
"""

from ..io import IO, vec3
from ..math import Vec3
from .id import ID_SERVER_PLAYER_POST_MOVE_POSITION
from .packet import Packet


struct ServerPlayerPostMovePosition(Packet):
    """Sent by the server with the player's position after movement
    processing."""

    comptime ID: UInt32 = ID_SERVER_PLAYER_POST_MOVE_POSITION
    """The packet ID."""
    var position: Vec3
    """The player's position after the server processed movement."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        vec3(io, self.position)
