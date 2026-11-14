"""The `Animate` packet (gophertunnel `packet/animate.go`)."""

from ..io import IO, actor_runtime_id, invalid_value, optional_func
from .id import ID_ANIMATE
from .packet import Packet

comptime ANIMATE_ACTION_SWING_ARM: UInt8 = 1
"""Go `AnimateActionSwingArm`."""
comptime ANIMATE_ACTION_STOP_SLEEP: UInt8 = 3
"""Go `AnimateActionStopSleep`."""
comptime ANIMATE_ACTION_CRITICAL_HIT: UInt8 = 4
"""Go `AnimateActionCriticalHit`."""
comptime ANIMATE_ACTION_MAGIC_CRITICAL_HIT: UInt8 = 5
"""Go `AnimateActionMagicCriticalHit`."""
comptime ANIMATE_SWING_SOURCE_NONE: UInt8 = 1
"""Go `AnimateSwingSourceNone`."""
comptime ANIMATE_SWING_SOURCE_BUILD: UInt8 = 2
"""Go `AnimateSwingSourceBuild`."""
comptime ANIMATE_SWING_SOURCE_MINE: UInt8 = 3
"""Go `AnimateSwingSourceMine`."""
comptime ANIMATE_SWING_SOURCE_INTERACT: UInt8 = 4
"""Go `AnimateSwingSourceInteract`."""
comptime ANIMATE_SWING_SOURCE_ATTACK: UInt8 = 5
"""Go `AnimateSwingSourceAttack`."""
comptime ANIMATE_SWING_SOURCE_USE_ITEM: UInt8 = 6
"""Go `AnimateSwingSourceUseItem`."""
comptime ANIMATE_SWING_SOURCE_THROW_ITEM: UInt8 = 7
"""Go `AnimateSwingSourceThrowItem`."""
comptime ANIMATE_SWING_SOURCE_DROP_ITEM: UInt8 = 8
"""Go `AnimateSwingSourceDropItem`."""
comptime ANIMATE_SWING_SOURCE_EVENT: UInt8 = 9
"""Go `AnimateSwingSourceEvent`."""


struct Animate(Packet):
    """Sent by the server to show a player animation, such as an arm swing."""

    comptime ID: UInt32 = ID_ANIMATE
    """The packet ID."""
    var action_type: UInt8
    """One of the `ANIMATE_ACTION_*` values."""
    var entity_runtime_id: UInt64
    """The runtime ID of the player to animate."""
    var data: Float32
    """Action-specific data."""
    var swing_source: UInt8
    """One of the `ANIMATE_SWING_SOURCE_*` values, or 0 for none."""
    var hand: UInt8
    """The animating hand, one of the hand slot values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_type = 0
        self.entity_runtime_id = 0
        self.data = 0
        self.swing_source = 0
        self.hand = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        var swing_source: Optional[String] = None
        if self.swing_source != 0:
            swing_source = String(_swing_source_to_string(self.swing_source))
        io.uint8(self.action_type)
        actor_runtime_id(io, self.entity_runtime_id)
        io.float32(self.data)
        optional_func[I.string](io, swing_source)
        if case .Some(val) = swing_source:
            self.swing_source = _swing_source_from_string(val)
        io.uint8(self.hand)


def _swing_source_from_string(s: String) raises -> UInt8:
    if s == "none":
        return ANIMATE_SWING_SOURCE_NONE
    if s == "build":
        return ANIMATE_SWING_SOURCE_BUILD
    if s == "mine":
        return ANIMATE_SWING_SOURCE_MINE
    if s == "interact":
        return ANIMATE_SWING_SOURCE_INTERACT
    if s == "attack":
        return ANIMATE_SWING_SOURCE_ATTACK
    if s == "useitem":
        return ANIMATE_SWING_SOURCE_USE_ITEM
    if s == "throwitem":
        return ANIMATE_SWING_SOURCE_THROW_ITEM
    if s == "dropitem":
        return ANIMATE_SWING_SOURCE_DROP_ITEM
    if s == "event":
        return ANIMATE_SWING_SOURCE_EVENT
    invalid_value(s, "swingSource", "unknown source")
    return 0


def _swing_source_to_string(x: UInt8) -> StaticString:
    if x == ANIMATE_SWING_SOURCE_NONE:
        return "none"
    if x == ANIMATE_SWING_SOURCE_BUILD:
        return "build"
    if x == ANIMATE_SWING_SOURCE_MINE:
        return "mine"
    if x == ANIMATE_SWING_SOURCE_INTERACT:
        return "interact"
    if x == ANIMATE_SWING_SOURCE_ATTACK:
        return "attack"
    if x == ANIMATE_SWING_SOURCE_USE_ITEM:
        return "useitem"
    if x == ANIMATE_SWING_SOURCE_THROW_ITEM:
        return "throwitem"
    if x == ANIMATE_SWING_SOURCE_DROP_ITEM:
        return "dropitem"
    if x == ANIMATE_SWING_SOURCE_EVENT:
        return "event"
    return "unknown"
