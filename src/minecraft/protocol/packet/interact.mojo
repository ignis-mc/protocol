"""The `Interact` packet (gophertunnel `packet/interact.go`)."""

from ..io import IO, actor_runtime_id, optional_vec3
from ..math import Vec3
from .id import ID_INTERACT
from .packet import Packet

comptime INTERACT_ACTION_LEAVE_VEHICLE: UInt8 = 3
"""The leave vehicle interaction."""
comptime INTERACT_ACTION_MOUSE_OVER_ENTITY: UInt8 = 4
"""The mouse over entity interaction."""
comptime INTERACT_ACTION_NPC_OPEN: UInt8 = 5
"""The npc open interaction."""
comptime INTERACT_ACTION_OPEN_INVENTORY: UInt8 = 6
"""The open inventory interaction."""


struct Interact(Packet):
    """Sent by the client when it interacts with another entity in some way."""

    comptime ID: UInt32 = ID_INTERACT
    """The packet ID."""
    var action_type: UInt8
    """The action the player executed, an `INTERACT_ACTION_*` value."""
    var target_entity_runtime_id: UInt64
    """The runtime ID of the entity that the player interacted with."""
    var position: Optional[Vec3]
    """The position associated with the action."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_type = 0
        self.target_entity_runtime_id = 0
        self.position = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.action_type)
        actor_runtime_id(io, self.target_entity_runtime_id)
        optional_vec3(io, self.position)
