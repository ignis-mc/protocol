"""The `AnvilDamage` packet (gophertunnel `packet/anvil_damage.go`)."""

from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_ANVIL_DAMAGE
from .packet import Packet


struct AnvilDamage(Packet):
    """Sent by the client to damage an anvil; servers should ignore it."""

    comptime ID: UInt32 = ID_ANVIL_DAMAGE
    """The packet ID."""
    var anvil_position: BlockPos
    """The position of the anvil."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.anvil_position = BlockPos()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        block_pos(io, self.anvil_position)
