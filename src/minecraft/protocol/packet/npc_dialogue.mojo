"""The `NPCDialogue` packet (gophertunnel `packet/npc_dialogue.go`)."""

from ..io import IO
from .id import ID_NPC_DIALOGUE
from .packet import Packet

comptime NPC_DIALOGUE_ACTION_OPEN: Int32 = 0
"""Opens the dialogue."""
comptime NPC_DIALOGUE_ACTION_CLOSE: Int32 = 1
"""Closes the dialogue."""


struct NPCDialogue(Packet):
    """Makes the client show a dialogue box for interacting with an NPC."""

    comptime ID: UInt32 = ID_NPC_DIALOGUE
    """The packet ID."""
    var entity_unique_id: UInt64
    """The unique ID of the NPC, sent as a fixed-width `uint64`."""
    var action_type: Int32
    """One of the `NPC_DIALOGUE_ACTION_*` values."""
    var dialogue: String
    """The text the client shows."""
    var scene_name: String
    """The scene identifier; empty reuses the last scene."""
    var npc_name: String
    """The name of the NPC."""
    var action_json: String
    """The JSON of the buttons and actions."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.entity_unique_id = 0
        self.action_type = 0
        self.dialogue = String()
        self.scene_name = String()
        self.npc_name = String()
        self.action_json = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint64(self.entity_unique_id)  # Go: ActorUniqueIDUint64
        io.varint32(self.action_type)
        io.string(self.dialogue)
        io.string(self.scene_name)
        io.string(self.npc_name)
        io.string(self.action_json)
