"""The `BlockActorData` packet (gophertunnel `packet/block_actor_data.go`)."""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..block_pos import BlockPos
from ..io import IO, block_pos
from .id import ID_BLOCK_ACTOR_DATA
from .packet import Packet


struct BlockActorData(Packet):
    """Sent by the server to update the data of a block entity."""

    comptime ID: UInt32 = ID_BLOCK_ACTOR_DATA
    """The packet ID."""
    var position: BlockPos
    """The position of the block entity."""
    var nbt_data: NBT
    """The full block entity data, a network NBT compound."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.position = BlockPos()
        self.nbt_data = NBT()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        block_pos(io, self.position)
        nbt(io, self.nbt_data, NETWORK_LITTLE_ENDIAN)
