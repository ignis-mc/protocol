"""The `SetSpawnPosition` packet.

This is gophertunnel `packet/set_spawn_position.go`.
"""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_SET_SPAWN_POSITION
from .packet import Packet

comptime SPAWN_TYPE_PLAYER: Int32 = 0
"""The player's own spawn point."""
comptime SPAWN_TYPE_WORLD: Int32 = 1
"""The world spawn point."""


struct SetSpawnPosition(Packet):
    """Sent by the server to update the spawn position of a player."""

    comptime ID: UInt32 = ID_SET_SPAWN_POSITION
    """The packet ID."""
    var spawn_type: Int32
    """One of the `SPAWN_TYPE_*` values."""
    var position: BlockPos
    """The new spawn position."""
    var dimension: Int32
    """The dimension of the spawn position."""
    var spawn_position: BlockPos
    """The world spawn position."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.spawn_type = 0
        self.position = BlockPos()
        self.dimension = 0
        self.spawn_position = BlockPos()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.spawn_type)
        block_pos(io, self.position)
        io.varint32(self.dimension)
        block_pos(io, self.spawn_position)
