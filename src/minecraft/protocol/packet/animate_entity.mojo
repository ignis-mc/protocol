"""The `AnimateEntity` packet (gophertunnel `packet/animate_entity.go`)."""

from ..io import IO, actor_runtime_id, func_slice
from .id import ID_ANIMATE_ENTITY
from .packet import Packet


struct AnimateEntity(Packet):
    """Sent by the server to animate entities client-side."""

    comptime ID: UInt32 = ID_ANIMATE_ENTITY
    """The packet ID."""
    var animation: String
    """The name of a single animation to play."""
    var next_state: String
    """The first animation controller state."""
    var stop_condition: String
    """A MoLang expression for when to stop."""
    var stop_condition_version: Int32
    """The MoLang stop condition version."""
    var controller: String
    """The animation controller managing the animations."""
    var blend_out_time: Float32
    """Unused by the client."""
    var entity_runtime_ids: List[UInt64]
    """The runtime IDs of the entities to animate."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.animation = String()
        self.next_state = String()
        self.stop_condition = String()
        self.stop_condition_version = 0
        self.controller = String()
        self.blend_out_time = 0
        self.entity_runtime_ids = List[UInt64]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.animation)
        io.string(self.next_state)
        io.string(self.stop_condition)
        io.int32(self.stop_condition_version)
        io.string(self.controller)
        io.float32(self.blend_out_time)
        func_slice[actor_runtime_id[I]](io, self.entity_runtime_ids)
