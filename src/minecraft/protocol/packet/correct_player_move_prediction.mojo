"""The `CorrectPlayerMovePrediction` packet (gophertunnel `packet/correct_player_move_prediction.go`)."""

from ..io import IO, optional_float32, vec2, vec3
from ..math import Vec2, Vec3
from .id import ID_CORRECT_PLAYER_MOVE_PREDICTION
from .packet import Packet

comptime PREDICTION_TYPE_PLAYER: UInt8 = 0
"""The correction is for the player."""
comptime PREDICTION_TYPE_VEHICLE: UInt8 = 1
"""The correction is for the vehicle the player rides."""


struct CorrectPlayerMovePrediction(Packet):
    """Sent by the server to correct the client's movement prediction.

    Only sent with server-authoritative movement with rewind.
    """

    comptime ID: UInt32 = ID_CORRECT_PLAYER_MOVE_PREDICTION
    """The packet ID."""
    var prediction_type: UInt8
    """The type of prediction that was corrected."""
    var position: Vec3
    """The position the player should have at `tick`."""
    var delta: Vec3
    """The change in position compared to what the client sent as its position
    at that specific tick.
    """
    var rotation: Vec2
    """The rotation of the player at `tick`."""
    var vehicle_angular_velocity: Optional[Float32]
    """The angular velocity of the vehicle that the rider is riding."""
    var on_ground: Bool
    """Whether the player was on the ground at `tick`."""
    var tick: UInt64
    """The tick of the movement which was corrected by this packet."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.prediction_type = 0
        self.position = Vec3()
        self.delta = Vec3()
        self.rotation = Vec2()
        self.vehicle_angular_velocity = None
        self.on_ground = False
        self.tick = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.prediction_type)
        vec3(io, self.position)
        vec3(io, self.delta)
        vec2(io, self.rotation)
        optional_float32(io, self.vehicle_angular_velocity)
        io.bool(self.on_ground)
        io.varuint64(self.tick)
