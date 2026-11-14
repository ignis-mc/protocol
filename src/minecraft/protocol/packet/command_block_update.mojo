"""The `CommandBlockUpdate` packet (gophertunnel `packet/command_block_update.go`)."""

from ..block_pos import BlockPos
from ..io import IO, actor_runtime_id, block_pos
from .id import ID_COMMAND_BLOCK_UPDATE
from .packet import Packet

comptime COMMAND_BLOCK_IMPULSE: UInt32 = 0
"""Go `CommandBlockImpulse`."""
comptime COMMAND_BLOCK_REPEATING: UInt32 = 1
"""Go `CommandBlockRepeating`."""
comptime COMMAND_BLOCK_CHAIN: UInt32 = 2
"""Go `CommandBlockChain`."""


struct CommandBlockUpdate(Packet):
    """Sent by the client to update a command block, a block or a minecart."""

    comptime ID: UInt32 = ID_COMMAND_BLOCK_UPDATE
    """The packet ID."""
    var block: Bool
    """Whether the command block is a block rather than a minecart."""
    var position: BlockPos
    """The position of the block, if `block`."""
    var mode: UInt32
    """One of the `COMMAND_BLOCK_*` values, if `block`."""
    var needs_redstone: Bool
    """Whether the block needs redstone power, if `block`."""
    var conditional: Bool
    """Whether it runs only after the previous block succeeded, if `block`."""
    var minecart_entity_runtime_id: UInt64
    """The runtime ID of the minecart, if not `block`."""
    var command: String
    """The command in the command block."""
    var last_output: String
    """The output of the last command run."""
    var name: String
    """The name shown above the command block."""
    var filtered_name: String
    """The profanity-filtered name."""
    var should_track_output: Bool
    """Whether the command block tracks output."""
    var tick_delay: UInt32
    """The delay in ticks between runs of a repeating block."""
    var execute_on_first_tick: Bool
    """Whether it runs on the tick it is enabled."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.block = False
        self.position = BlockPos()
        self.mode = 0
        self.needs_redstone = False
        self.conditional = False
        self.minecart_entity_runtime_id = 0
        self.command = String()
        self.last_output = String()
        self.name = String()
        self.filtered_name = String()
        self.should_track_output = False
        self.tick_delay = 0
        self.execute_on_first_tick = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.bool(self.block)
        if self.block:
            block_pos(io, self.position)
            io.varuint32(self.mode)
            io.bool(self.needs_redstone)
            io.bool(self.conditional)
        else:
            actor_runtime_id(io, self.minecart_entity_runtime_id)
        io.string(self.command)
        io.string(self.last_output)
        io.string(self.name)
        io.string(self.filtered_name)
        io.bool(self.should_track_output)
        io.uint32(self.tick_delay)
        io.bool(self.execute_on_first_tick)
