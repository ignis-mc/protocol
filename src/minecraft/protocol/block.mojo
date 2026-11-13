"""Custom block entries and block changes (gophertunnel `protocol/block.go`)."""

from ..nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from .block_pos import BlockPos
from .io import IO, Marshaler, block_pos


struct BlockEntry(Marshaler):
    """A custom block from the StartGame packet."""

    var name: String
    """The block's name."""
    var properties: NBT
    """The block's properties (a network little-endian compound)."""

    def __init__(out self):
        """Creates a zero value."""
        self.name = String()
        self.properties = NBT()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        nbt(io, self.properties, NETWORK_LITTLE_ENDIAN)


struct BlockChangeEntry(Marshaler):
    """A block change in the UpdateSubChunkBlocks packet."""

    var block_pos: BlockPos
    """The position of the block (embedded in Go)."""
    var block_runtime_id: UInt32
    """The runtime ID of the new block."""
    var flags: UInt32
    """Flags for how the client updates the block."""
    var synced_update_entity_unique_id: UInt64
    """The falling block entity of a synced change."""
    var synced_update_type: UInt32
    """The transition of a synced change."""

    def __init__(out self):
        """Creates a zero value."""
        self.block_pos = BlockPos()
        self.block_runtime_id = 0
        self.flags = 0
        self.synced_update_entity_unique_id = 0
        self.synced_update_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        block_pos(io, self.block_pos)
        io.varuint32(self.block_runtime_id)
        io.varuint32(self.flags)
        io.varuint64(self.synced_update_entity_unique_id)
        io.varuint32(self.synced_update_type)
