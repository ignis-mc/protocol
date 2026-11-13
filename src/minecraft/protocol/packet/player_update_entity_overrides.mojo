"""The `PlayerUpdateEntityOverrides` packet (gophertunnel `packet/player_update_entity_overrides.go`).
"""

from ..io import IO, actor_unique_id, unknown_enum_option
from .id import ID_PLAYER_UPDATE_ENTITY_OVERRIDES
from .packet import Packet

comptime PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_CLEAR_ALL: UInt32 = 0
"""Clears every override."""
comptime PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_REMOVE: UInt32 = 1
"""Removes the override of one property."""
comptime PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_INT: UInt32 = 2
"""Sets an integer override."""
comptime PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_FLOAT: UInt32 = 3
"""Sets a float override."""


def _type_name(t: UInt32) -> String:
    if t == PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_CLEAR_ALL:
        return "clearoverrides"
    if t == PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_REMOVE:
        return "removeoverride"
    if t == PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_INT:
        return "setintoverride"
    return "setfloatoverride"


struct PlayerUpdateEntityOverrides(Packet):
    """Sent by the server to override one of an entity's properties."""

    comptime ID: UInt32 = ID_PLAYER_UPDATE_ENTITY_OVERRIDES
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the entity."""
    var property_index: UInt32
    """The index of the property to modify."""
    var type: UInt32
    """One of the `PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_*` values."""
    var int_value: Int32
    """The new value, for `PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_INT`."""
    var float_value: Float32
    """The new value, for `PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_FLOAT`."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.property_index = 0
        self.type = PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_CLEAR_ALL
        self.int_value = 0
        self.float_value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        After the type comes its name as a string; a reader ignores it.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the type is unknown or the input is malformed.
        """
        actor_unique_id(io, self.entity_unique_id)
        io.varuint32(self.property_index)
        io.varuint32(self.type)
        if self.type > PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_FLOAT:
            unknown_enum_option(Int(self.type), "entity override type")
        var name = _type_name(self.type)
        io.string(name)
        if self.type == PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_INT:
            io.int32(self.int_value)
        elif self.type == PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_FLOAT:
            io.float32(self.float_value)
