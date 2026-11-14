"""The `ClientBoundTextureShift` packet (gophertunnel `packet/clientbound_texture_shift.go`)."""

from ..io import IO, string_slice
from .id import ID_CLIENT_BOUND_TEXTURE_SHIFT
from .packet import Packet

comptime TEXTURE_SHIFT_ACTION_INVALID: UInt8 = 0
"""Go `TextureShiftActionInvalid`."""
comptime TEXTURE_SHIFT_ACTION_INITIALIZE: UInt8 = 1
"""Go `TextureShiftActionInitialize`."""
comptime TEXTURE_SHIFT_ACTION_START: UInt8 = 2
"""Go `TextureShiftActionStart`."""
comptime TEXTURE_SHIFT_ACTION_SET_ENABLED: UInt8 = 3
"""Go `TextureShiftActionSetEnabled`."""
comptime TEXTURE_SHIFT_ACTION_SYNC: UInt8 = 4
"""Go `TextureShiftActionSync`."""


struct ClientBoundTextureShift(Packet):
    """Sent by the server to control texture shift animations."""

    comptime ID: UInt32 = ID_CLIENT_BOUND_TEXTURE_SHIFT
    """The packet ID."""
    var action_id: UInt8
    """One of the `TEXTURE_SHIFT_ACTION_*` values."""
    var collection_name: String
    """The name of the texture shift collection."""
    var from_step: String
    """The step to shift from."""
    var to_step: String
    """The step to shift to."""
    var all_steps: List[String]
    """Every step of the shift."""
    var current_length_ticks: UInt64
    """The current length of the shift in ticks."""
    var total_length_ticks: UInt64
    """The total length of the shift in ticks."""
    var enabled: Bool
    """Whether the texture shift is enabled."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.action_id = 0
        self.collection_name = String()
        self.from_step = String()
        self.to_step = String()
        self.all_steps = List[String]()
        self.current_length_ticks = 0
        self.total_length_ticks = 0
        self.enabled = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.action_id)
        io.string(self.collection_name)
        io.string(self.from_step)
        io.string(self.to_step)
        string_slice(io, self.all_steps)
        io.varuint64(self.current_length_ticks)
        io.varuint64(self.total_length_ticks)
        io.bool(self.enabled)
