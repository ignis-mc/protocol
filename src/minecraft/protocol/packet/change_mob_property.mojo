"""The `ChangeMobProperty` packet (gophertunnel `packet/change_mob_property.go`)."""

from ..io import IO, actor_unique_id
from .id import ID_CHANGE_MOB_PROPERTY
from .packet import Packet


struct ChangeMobProperty(Packet):
    """Sent by the server to change a property of a mob client-side."""

    comptime ID: UInt32 = ID_CHANGE_MOB_PROPERTY
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity."""
    var property: String
    """The name of the property."""
    var bool_value: Bool
    """The value, if the property is a bool."""
    var string_value: String
    """The value, if the property is a string."""
    var int_value: Int32
    """The value, if the property is an int."""
    var float_value: Float32
    """The value, if the property is a float."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.property = String()
        self.bool_value = False
        self.string_value = String()
        self.int_value = 0
        self.float_value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.entity_unique_id)
        io.string(self.property)
        io.bool(self.bool_value)
        io.string(self.string_value)
        io.varint32(self.int_value)
        io.float32(self.float_value)
