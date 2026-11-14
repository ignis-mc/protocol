"""The `AgentAction` packet (gophertunnel `packet/agent_action.go`)."""

from ..io import IO
from .id import ID_AGENT_ACTION
from .packet import Packet

comptime AGENT_ACTION_TYPE_ATTACK: Int32 = 1
"""Go `AgentActionTypeAttack`."""
comptime AGENT_ACTION_TYPE_COLLECT: Int32 = 2
"""Go `AgentActionTypeCollect`."""
comptime AGENT_ACTION_TYPE_DESTROY: Int32 = 3
"""Go `AgentActionTypeDestroy`."""
comptime AGENT_ACTION_TYPE_DETECT_REDSTONE: Int32 = 4
"""Go `AgentActionTypeDetectRedstone`."""
comptime AGENT_ACTION_TYPE_DETECT_OBSTACLE: Int32 = 5
"""Go `AgentActionTypeDetectObstacle`."""
comptime AGENT_ACTION_TYPE_DROP: Int32 = 6
"""Go `AgentActionTypeDrop`."""
comptime AGENT_ACTION_TYPE_DROP_ALL: Int32 = 7
"""Go `AgentActionTypeDropAll`."""
comptime AGENT_ACTION_TYPE_INSPECT: Int32 = 8
"""Go `AgentActionTypeInspect`."""
comptime AGENT_ACTION_TYPE_INSPECT_DATA: Int32 = 9
"""Go `AgentActionTypeInspectData`."""
comptime AGENT_ACTION_TYPE_INSPECT_ITEM_COUNT: Int32 = 10
"""Go `AgentActionTypeInspectItemCount`."""
comptime AGENT_ACTION_TYPE_INSPECT_ITEM_DETAIL: Int32 = 11
"""Go `AgentActionTypeInspectItemDetail`."""
comptime AGENT_ACTION_TYPE_INSPECT_ITEM_SPACE: Int32 = 12
"""Go `AgentActionTypeInspectItemSpace`."""
comptime AGENT_ACTION_TYPE_INTERACT: Int32 = 13
"""Go `AgentActionTypeInteract`."""
comptime AGENT_ACTION_TYPE_MOVE: Int32 = 14
"""Go `AgentActionTypeMove`."""
comptime AGENT_ACTION_TYPE_PLACE_BLOCK: Int32 = 15
"""Go `AgentActionTypePlaceBlock`."""
comptime AGENT_ACTION_TYPE_TILL: Int32 = 16
"""Go `AgentActionTypeTill`."""
comptime AGENT_ACTION_TYPE_TRANSFER_ITEM_TO: Int32 = 17
"""Go `AgentActionTypeTransferItemTo`."""
comptime AGENT_ACTION_TYPE_TURN: Int32 = 18
"""Go `AgentActionTypeTurn`."""


struct AgentAction(Packet):
    """Education Edition: the server returns the response to an agent action."""

    comptime ID: UInt32 = ID_AGENT_ACTION
    """The packet ID."""
    var identifier: String
    """The JSON identifier referenced in the action."""
    var action: Int32
    """One of the `AGENT_ACTION_TYPE_*` values."""
    var response: List[UInt8]
    """The JSON response to the action."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.identifier = String()
        self.action = 0
        self.response = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.string(self.identifier)
        io.int32(self.action)
        io.byte_slice(self.response)
