"""The `NPCRequest` packet (gophertunnel `packet/npc_request.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_NPC_REQUEST
from .packet import Packet

comptime NPC_REQUEST_ACTION_SET_ACTIONS: UInt8 = 0
"""Sets the NPC's actions."""
comptime NPC_REQUEST_ACTION_EXECUTE_ACTION: UInt8 = 1
"""Executes an action."""
comptime NPC_REQUEST_ACTION_EXECUTE_CLOSING_COMMANDS: UInt8 = 2
"""Executes the closing commands."""
comptime NPC_REQUEST_ACTION_SET_NAME: UInt8 = 3
"""Sets the NPC's name."""
comptime NPC_REQUEST_ACTION_SET_SKIN: UInt8 = 4
"""Sets the NPC's skin."""
comptime NPC_REQUEST_ACTION_SET_INTERACT_TEXT: UInt8 = 5
"""Sets the interaction text."""
comptime NPC_REQUEST_ACTION_EXECUTE_OPENING_COMMANDS: UInt8 = 6
"""Executes the opening commands."""


struct NPCRequest(Packet):
    """Sent by the client when it interacts with an NPC (Education Edition)."""

    comptime ID: UInt32 = ID_NPC_REQUEST
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the NPC."""
    var request_type: UInt8
    """One of the `NPC_REQUEST_ACTION_*` values."""
    var command_string: String
    """The command string set in the NPC."""
    var action_type: UInt8
    """The type of the action to execute."""
    var scene_name: String
    """The scene name; empty means the last scene sent."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.entity_runtime_id = 0
        self.request_type = 0
        self.command_string = String()
        self.action_type = 0
        self.scene_name = String()

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
        io.uint8(self.request_type)
        io.string(self.command_string)
        io.uint8(self.action_type)
        io.string(self.scene_name)
