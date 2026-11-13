"""The `Respawn` packet (gophertunnel `packet/respawn.go`)."""

from ..io import IO, actor_runtime_id, vec3
from ..math import Vec3
from .id import ID_RESPAWN
from .packet import Packet

comptime RESPAWN_STATE_SEARCHING_FOR_SPAWN: UInt8 = 0
"""The server is searching for a spawn position."""
comptime RESPAWN_STATE_READY_TO_SPAWN: UInt8 = 1
"""The server is ready for the player to spawn."""
comptime RESPAWN_STATE_CLIENT_READY_TO_SPAWN: UInt8 = 2
"""The client is ready to spawn."""


struct Respawn(Packet):
    """Makes a player respawn client-side.

    The server sends two of these with different states and the client
    answers with one to complete the respawn.
    """

    comptime ID: UInt32 = ID_RESPAWN
    """The packet ID."""
    var position: Vec3
    """The respawn position."""
    var state: UInt8
    """One of the `RESPAWN_STATE_*` values."""
    var entity_runtime_id: UInt64
    """The runtime ID of the player."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = Vec3()
        self.state = RESPAWN_STATE_SEARCHING_FOR_SPAWN
        self.entity_runtime_id = 0

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
        io.uint8(self.state)
        actor_runtime_id(io, self.entity_runtime_id)
