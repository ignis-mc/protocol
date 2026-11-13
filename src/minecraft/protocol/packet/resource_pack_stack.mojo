"""The `ResourcePackStack` packet (gophertunnel `packet/resource_pack_stack.go`).
"""

from ..experiments import ExperimentData
from ..io import IO, slice, slice_uint32_length
from ..resource_pack import StackResourcePack
from .id import ID_RESOURCE_PACK_STACK
from .packet import Packet


struct ResourcePackStack(Packet):
    """Sent by the server with the order in which packs are applied."""

    comptime ID: UInt32 = ID_RESOURCE_PACK_STACK
    """The packet ID."""
    var texture_pack_required: Bool
    """Whether the client must accept the texture packs to join."""
    var texture_packs: List[StackResourcePack]
    """The texture packs, in the order they are applied."""
    var base_game_version: String
    """The vanilla version the client sets its pack stack to."""
    var experiments: List[ExperimentData]
    """The experiments enabled or disabled in the world."""
    var experiments_previously_toggled: Bool
    """Whether any experiments were toggled before in this world."""
    var include_editor_packs: Bool
    """Whether vanilla editor packs are included in editor worlds."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.texture_pack_required = False
        self.texture_packs = List[StackResourcePack]()
        self.base_game_version = String()
        self.experiments = List[ExperimentData]()
        self.experiments_previously_toggled = False
        self.include_editor_packs = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.bool(self.texture_pack_required)
        slice(io, self.texture_packs)
        io.string(self.base_game_version)
        slice_uint32_length(io, self.experiments)
        io.bool(self.experiments_previously_toggled)
        io.bool(self.include_editor_packs)
