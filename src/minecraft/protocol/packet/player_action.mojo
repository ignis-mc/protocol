"""The `PlayerAction` packet (gophertunnel `packet/player_action.go`)."""

from ..block_pos import BlockPos
from ..io import IO, actor_runtime_id, block_pos
from .id import ID_PLAYER_ACTION
from .packet import Packet


struct PlayerAction(Packet):
    """Sent by the client when it performs an action, such as sprinting."""

    comptime ID: UInt32 = ID_PLAYER_ACTION
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the player."""
    var action_type: Int32
    """One of the `PLAYER_ACTION_*` values in `protocol/player.mojo`."""
    var block_position: BlockPos
    """The target block, or zero if the action concerns no block."""
    var result_position: BlockPos
    """The position of the action's result, such as a placed block."""
    var block_face: Int32
    """The face of the target block, or 0."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.action_type = 0
        self.block_position = BlockPos()
        self.result_position = BlockPos()
        self.block_face = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_runtime_id(io, self.entity_runtime_id)
        io.varint32(self.action_type)
        block_pos(io, self.block_position)
        block_pos(io, self.result_position)
        io.varint32(self.block_face)
