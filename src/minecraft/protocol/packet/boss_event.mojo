"""The `BossEvent` packet (gophertunnel `packet/boss_event.go`)."""

from ..io import IO, actor_unique_id
from .id import ID_BOSS_EVENT
from .packet import Packet

comptime BOSS_EVENT_SHOW: UInt8 = 0
"""Go `BossEventShow`."""
comptime BOSS_EVENT_REGISTER_PLAYER: UInt8 = 1
"""Go `BossEventRegisterPlayer`."""
comptime BOSS_EVENT_HIDE: UInt8 = 2
"""Go `BossEventHide`."""
comptime BOSS_EVENT_UNREGISTER_PLAYER: UInt8 = 3
"""Go `BossEventUnregisterPlayer`."""
comptime BOSS_EVENT_HEALTH_PERCENTAGE: UInt8 = 4
"""Go `BossEventHealthPercentage`."""
comptime BOSS_EVENT_TITLE: UInt8 = 5
"""Go `BossEventTitle`."""
comptime BOSS_EVENT_APPEARANCE_PROPERTIES: UInt8 = 6
"""Go `BossEventAppearanceProperties`."""
comptime BOSS_EVENT_TEXTURE: UInt8 = 7
"""Go `BossEventTexture`."""
comptime BOSS_EVENT_REQUEST: UInt8 = 8
"""Go `BossEventRequest`."""
comptime BOSS_EVENT_COLOUR_PINK: UInt8 = 0
"""Go `BossEventColourPink`."""
comptime BOSS_EVENT_COLOUR_BLUE: UInt8 = 1
"""Go `BossEventColourBlue`."""
comptime BOSS_EVENT_COLOUR_RED: UInt8 = 2
"""Go `BossEventColourRed`."""
comptime BOSS_EVENT_COLOUR_GREEN: UInt8 = 3
"""Go `BossEventColourGreen`."""
comptime BOSS_EVENT_COLOUR_YELLOW: UInt8 = 4
"""Go `BossEventColourYellow`."""
comptime BOSS_EVENT_COLOUR_PURPLE: UInt8 = 5
"""Go `BossEventColourPurple`."""
comptime BOSS_EVENT_COLOUR_REBECCA_PURPLE: UInt8 = 6
"""Go `BossEventColourRebeccaPurple`."""
comptime BOSS_EVENT_COLOUR_WHITE: UInt8 = 7
"""Go `BossEventColourWhite`."""
comptime BOSS_EVENT_OVERLAY_PROGRESS: UInt8 = 0
"""Go `BossEventOverlayProgress`."""
comptime BOSS_EVENT_OVERLAY_NOTCHED6: UInt8 = 1
"""Go `BossEventOverlayNotched6`."""
comptime BOSS_EVENT_OVERLAY_NOTCHED10: UInt8 = 2
"""Go `BossEventOverlayNotched10`."""
comptime BOSS_EVENT_OVERLAY_NOTCHED12: UInt8 = 3
"""Go `BossEventOverlayNotched12`."""
comptime BOSS_EVENT_OVERLAY_NOTCHED20: UInt8 = 4
"""Go `BossEventOverlayNotched20`."""


struct BossEvent(Packet):
    """Sent by the server for a boss event, such as showing a boss bar."""

    comptime ID: UInt32 = ID_BOSS_EVENT
    """The packet ID."""
    var boss_entity_unique_id: Int64
    """The unique ID of the boss entity."""
    var event_type: UInt8
    """One of the `BOSS_EVENT_*` event values."""
    var boss_bar_title: String
    """The title shown above the boss bar."""
    var filtered_boss_bar_title: String
    """The profanity-filtered title."""
    var health_percentage: Float32
    """The health shown in the bar, 0.0 to 1.0."""
    var colour: UInt8
    """One of the `BOSS_EVENT_COLOUR_*` values."""
    var overlay: UInt8
    """One of the `BOSS_EVENT_OVERLAY_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.boss_entity_unique_id = 0
        self.event_type = 0
        self.boss_bar_title = String()
        self.filtered_boss_bar_title = String()
        self.health_percentage = 0
        self.colour = 0
        self.overlay = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.boss_entity_unique_id)
        io.uint8(self.event_type)
        io.string(self.boss_bar_title)
        io.string(self.filtered_boss_bar_title)
        io.float32(self.health_percentage)
        io.uint8(self.colour)
        io.uint8(self.overlay)
