"""The `PlayerLocation` packet (gophertunnel `packet/player_location.go`).

The type goes on the wire twice: first as a varuint32 (the variant index),
then as a varint32. A reader keeps the second value, as Go does.
"""

from ..io import IO, actor_unique_id, unknown_enum_option, vec3
from ..math import Vec3
from .id import ID_PLAYER_LOCATION
from .packet import Packet

comptime PLAYER_LOCATION_TYPE_COORDINATES: Int32 = 0
"""Sets the player's position on the locator bar."""
comptime PLAYER_LOCATION_TYPE_HIDE: Int32 = 1
"""Removes the player from the locator bar."""


struct PlayerLocation(Packet):
    """Sent by the server to update or remove a player on the locator bar."""

    comptime ID: UInt32 = ID_PLAYER_LOCATION
    """The packet ID."""
    var type: Int32
    """One of the `PLAYER_LOCATION_TYPE_*` values."""
    var entity_unique_id: Int64
    """The unique ID of the entity."""
    var position: Vec3
    """The position, only sent for `PLAYER_LOCATION_TYPE_COORDINATES`."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.type = PLAYER_LOCATION_TYPE_COORDINATES
        self.entity_unique_id = 0
        self.position = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_unique_id(io, self.entity_unique_id)
        var variant = UInt32(self.type)  # Go: IntegerFunc(..., Varuint32)
        io.varuint32(variant)
        self.type = Int32(variant)
        io.varint32(self.type)
        if self.type == PLAYER_LOCATION_TYPE_COORDINATES:
            vec3(io, self.position)
        elif self.type == PLAYER_LOCATION_TYPE_HIDE:
            pass
        else:
            unknown_enum_option(Int(self.type), "player location type")
