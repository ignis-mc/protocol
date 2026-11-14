"""The `Emote` packet (gophertunnel `packet/emote.go`)."""

from ..io import IO, actor_runtime_id
from .id import ID_EMOTE
from .packet import Packet

comptime EMOTE_FLAG_SERVER_SIDE: UInt8 = 1
"""The server side emote flag."""
comptime EMOTE_FLAG_MUTE_CHAT: UInt8 = 2
"""The mute chat emote flag."""


struct Emote(Packet):
    """Sent by a client to emote, and by the server to broadcast the emote."""

    comptime ID: UInt32 = ID_EMOTE
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The entity that sent the emote."""
    var emote_length: UInt32
    """The number of ticks that the emote lasts for."""
    var emote_id: String
    """The ID of the emote to send."""
    var xuid: String
    """The Xbox User ID of the player that sent the emote."""
    var platform_id: String
    """An identifier only set for particular platforms when using an emote
    (presumably only for Nintendo Switch).
    """
    var flags: UInt8
    """A combination of flags that change the way the Emote packet operates."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.emote_length = 0
        self.emote_id = String()
        self.xuid = String()
        self.platform_id = String()
        self.flags = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        io.string(self.emote_id)
        io.varuint32(self.emote_length)
        io.string(self.xuid)
        io.string(self.platform_id)
        io.uint8(self.flags)
