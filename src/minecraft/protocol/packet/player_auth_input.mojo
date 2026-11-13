"""The `PlayerAuthInput` packet (gophertunnel `packet/player_auth_input.go`).
"""

from ..input_flags import InputFlags, input_flag_list
from ..inventory import UseItemTransactionData, player_inventory_action
from ..io import (
    IO,
    actor_unique_id,
    optional_func,
    optional_marshaler,
    slice,
    vec2,
    vec3,
)
from ..item_stack import ItemStackRequest
from ..math import Vec2, Vec3
from ..player import PlayerBlockAction
from .id import ID_PLAYER_AUTH_INPUT
from .packet import Packet

comptime INPUT_FLAG_ASCEND: Int = 0
"""Input flag: ascend."""
comptime INPUT_FLAG_DESCEND: Int = 1
"""Input flag: descend."""
comptime INPUT_FLAG_NORTH_JUMP: Int = 2
"""Input flag: north jump."""
comptime INPUT_FLAG_JUMP_DOWN: Int = 3
"""Input flag: jump down."""
comptime INPUT_FLAG_SPRINT_DOWN: Int = 4
"""Input flag: sprint down."""
comptime INPUT_FLAG_CHANGE_HEIGHT: Int = 5
"""Input flag: change height."""
comptime INPUT_FLAG_JUMPING: Int = 6
"""Input flag: jumping."""
comptime INPUT_FLAG_AUTO_JUMPING_IN_WATER: Int = 7
"""Input flag: auto jumping in water."""
comptime INPUT_FLAG_SNEAKING: Int = 8
"""Input flag: sneaking."""
comptime INPUT_FLAG_SNEAK_DOWN: Int = 9
"""Input flag: sneak down."""
comptime INPUT_FLAG_UP: Int = 10
"""Input flag: up."""
comptime INPUT_FLAG_DOWN: Int = 11
"""Input flag: down."""
comptime INPUT_FLAG_LEFT: Int = 12
"""Input flag: left."""
comptime INPUT_FLAG_RIGHT: Int = 13
"""Input flag: right."""
comptime INPUT_FLAG_UP_LEFT: Int = 14
"""Input flag: up left."""
comptime INPUT_FLAG_UP_RIGHT: Int = 15
"""Input flag: up right."""
comptime INPUT_FLAG_WANT_UP: Int = 16
"""Input flag: want up."""
comptime INPUT_FLAG_WANT_DOWN: Int = 17
"""Input flag: want down."""
comptime INPUT_FLAG_WANT_DOWN_SLOW: Int = 18
"""Input flag: want down slow."""
comptime INPUT_FLAG_WANT_UP_SLOW: Int = 19
"""Input flag: want up slow."""
comptime INPUT_FLAG_SPRINTING: Int = 20
"""Input flag: sprinting."""
comptime INPUT_FLAG_ASCEND_BLOCK: Int = 21
"""Input flag: ascend block."""
comptime INPUT_FLAG_DESCEND_BLOCK: Int = 22
"""Input flag: descend block."""
comptime INPUT_FLAG_SNEAK_TOGGLE_DOWN: Int = 23
"""Input flag: sneak toggle down."""
comptime INPUT_FLAG_PERSIST_SNEAK: Int = 24
"""Input flag: persist sneak."""
comptime INPUT_FLAG_START_SPRINTING: Int = 25
"""Input flag: start sprinting."""
comptime INPUT_FLAG_STOP_SPRINTING: Int = 26
"""Input flag: stop sprinting."""
comptime INPUT_FLAG_START_SNEAKING: Int = 27
"""Input flag: start sneaking."""
comptime INPUT_FLAG_STOP_SNEAKING: Int = 28
"""Input flag: stop sneaking."""
comptime INPUT_FLAG_START_SWIMMING: Int = 29
"""Input flag: start swimming."""
comptime INPUT_FLAG_STOP_SWIMMING: Int = 30
"""Input flag: stop swimming."""
comptime INPUT_FLAG_START_JUMPING: Int = 31
"""Input flag: start jumping."""
comptime INPUT_FLAG_START_GLIDING: Int = 32
"""Input flag: start gliding."""
comptime INPUT_FLAG_STOP_GLIDING: Int = 33
"""Input flag: stop gliding."""
comptime INPUT_FLAG_PERFORM_ITEM_INTERACTION: Int = 34
"""Input flag: perform item interaction."""
comptime INPUT_FLAG_PERFORM_BLOCK_ACTIONS: Int = 35
"""Input flag: perform block actions."""
comptime INPUT_FLAG_PERFORM_ITEM_STACK_REQUEST: Int = 36
"""Input flag: perform item stack request."""
comptime INPUT_FLAG_HANDLED_TELEPORT: Int = 37
"""Input flag: handled teleport."""
comptime INPUT_FLAG_EMOTING: Int = 38
"""Input flag: emoting."""
comptime INPUT_FLAG_MISSED_SWING: Int = 39
"""Input flag: missed swing."""
comptime INPUT_FLAG_START_CRAWLING: Int = 40
"""Input flag: start crawling."""
comptime INPUT_FLAG_STOP_CRAWLING: Int = 41
"""Input flag: stop crawling."""
comptime INPUT_FLAG_START_FLYING: Int = 42
"""Input flag: start flying."""
comptime INPUT_FLAG_STOP_FLYING: Int = 43
"""Input flag: stop flying."""
comptime INPUT_FLAG_CLIENT_ACK_SERVER_DATA: Int = 44
"""Input flag: client ack server data."""
comptime INPUT_FLAG_CLIENT_PREDICTED_VEHICLE: Int = 45
"""Input flag: client predicted vehicle."""
comptime INPUT_FLAG_PADDLING_LEFT: Int = 46
"""Input flag: paddling left."""
comptime INPUT_FLAG_PADDLING_RIGHT: Int = 47
"""Input flag: paddling right."""
comptime INPUT_FLAG_BLOCK_BREAKING_DELAY_ENABLED: Int = 48
"""Input flag: block breaking delay enabled."""
comptime INPUT_FLAG_HORIZONTAL_COLLISION: Int = 49
"""Input flag: horizontal collision."""
comptime INPUT_FLAG_VERTICAL_COLLISION: Int = 50
"""Input flag: vertical collision."""
comptime INPUT_FLAG_DOWN_LEFT: Int = 51
"""Input flag: down left."""
comptime INPUT_FLAG_DOWN_RIGHT: Int = 52
"""Input flag: down right."""
comptime INPUT_FLAG_START_USING_ITEM: Int = 53
"""Input flag: start using item."""
comptime INPUT_FLAG_CAMERA_RELATIVE_MOVEMENT_ENABLED: Int = 54
"""Input flag: camera relative movement enabled."""
comptime INPUT_FLAG_ROT_CONTROLLED_BY_MOVE_DIRECTION: Int = 55
"""Input flag: rot controlled by move direction."""
comptime INPUT_FLAG_START_SPIN_ATTACK: Int = 56
"""Input flag: start spin attack."""
comptime INPUT_FLAG_STOP_SPIN_ATTACK: Int = 57
"""Input flag: stop spin attack."""
comptime INPUT_FLAG_IS_HOTBAR_TOUCH_ONLY: Int = 58
"""Input flag: is hotbar touch only."""
comptime INPUT_FLAG_JUMP_RELEASED_RAW: Int = 59
"""Input flag: jump released raw."""
comptime INPUT_FLAG_JUMP_PRESSED_RAW: Int = 60
"""Input flag: jump pressed raw."""
comptime INPUT_FLAG_JUMP_CURRENT_RAW: Int = 61
"""Input flag: jump current raw."""
comptime INPUT_FLAG_SNEAK_RELEASED_RAW: Int = 62
"""Input flag: sneak released raw."""
comptime INPUT_FLAG_SNEAK_PRESSED_RAW: Int = 63
"""Input flag: sneak pressed raw."""
comptime INPUT_FLAG_SNEAK_CURRENT_RAW: Int = 64
"""Input flag: sneak current raw."""
comptime INPUT_FLAG_INTERNAL_UPDATE: Int = 65
"""Input flag: internal update."""
comptime INPUT_FLAG_COUNT: Int = 66
"""Input flag: count."""

comptime INPUT_MODE_UNDEFINED: UInt32 = 0
"""Input mode: undefined."""
comptime INPUT_MODE_MOUSE: UInt32 = 1
"""Input mode: mouse."""
comptime INPUT_MODE_TOUCH: UInt32 = 2
"""Input mode: touch."""
comptime INPUT_MODE_GAME_PAD: UInt32 = 3
"""Input mode: game pad."""
comptime INPUT_MODE_MOTION_CONTROLLER: UInt32 = 4
"""Input mode: motion controller."""
comptime INPUT_MODE_COUNT: UInt32 = 5
"""Input mode: count."""

comptime PLAY_MODE_NORMAL: UInt32 = 0
"""Play mode: normal."""
comptime PLAY_MODE_TEASER: UInt32 = 1
"""Play mode: teaser."""
comptime PLAY_MODE_SCREEN: UInt32 = 2
"""Play mode: screen."""
comptime PLAY_MODE_VIEWER: UInt32 = 3
"""Play mode: viewer."""
comptime PLAY_MODE_REALITY: UInt32 = 4
"""Play mode: reality."""
comptime PLAY_MODE_PLACEMENT: UInt32 = 5
"""Play mode: placement."""
comptime PLAY_MODE_LIVING_ROOM: UInt32 = 6
"""Play mode: living room."""
comptime PLAY_MODE_EXIT_LEVEL: UInt32 = 7
"""Play mode: exit level."""
comptime PLAY_MODE_EXIT_LEVEL_LIVING_ROOM: UInt32 = 8
"""Play mode: exit level living room."""
comptime PLAY_MODE_NUM_MODES: UInt32 = PLAY_MODE_EXIT_LEVEL_LIVING_ROOM + 1
"""The number of play modes."""

comptime INTERACTION_MODEL_TOUCH: Int32 = 0
"""Interaction model: touch."""
comptime INTERACTION_MODEL_CROSSHAIR: Int32 = 1
"""Interaction model: crosshair."""
comptime INTERACTION_MODEL_CLASSIC: Int32 = 2
"""Interaction model: classic."""
comptime INTERACTION_MODEL_COUNT: Int32 = 3
"""Interaction model: count."""


struct PlayerAuthInput(Packet):
    """Sent by the client every tick for server authoritative movement.

    The client sends it instead of `MovePlayer` when the `StartGame` packet
    enables server authoritative movement.
    """

    comptime ID: UInt32 = ID_PLAYER_AUTH_INPUT
    """The packet ID."""
    var pitch: Float32
    """The pitch the player reports."""
    var yaw: Float32
    """The yaw the player reports."""
    var position: Vec3
    """The position the player reports."""
    var move_vector: Vec2
    """The X/Z movement direction from WASD or the controller stick."""
    var head_yaw: Float32
    """The head yaw the player reports."""
    var input_data: InputFlags
    """The `INPUT_FLAG_*` flags for the last tick."""
    var input_mode: UInt32
    """One of the `INPUT_MODE_*` values."""
    var play_mode: UInt32
    """One of the `PLAY_MODE_*` values."""
    var interaction_model: Int32
    """One of the `INTERACTION_MODEL_*` values."""
    var interact_pitch: Float32
    """The pitch used for interactions (differs in VR or custom cameras)."""
    var interact_yaw: Float32
    """The yaw used for interactions."""
    var tick: UInt64
    """The server tick at which the packet was sent."""
    var delta: Vec3
    """The difference between the old and the new position."""
    var item_interaction_data: Optional[UseItemTransactionData]
    """The transaction, if the input includes an item interaction."""
    var item_stack_request: Optional[ItemStackRequest]
    """An inventory change, if any."""
    var block_actions: Optional[List[PlayerBlockAction]]
    """The block actions the client performed, if any."""
    var vehicle_rotation: Optional[Vec2]
    """The rotation of the player's vehicle, if any."""
    var client_predicted_vehicle: Optional[Int64]
    """The unique ID of the vehicle the client predicts the player is in."""
    var analogue_move_vector: Vec2
    """The X/Z movement direction from an analogue input."""
    var camera_orientation: Vec3
    """The camera's forward direction."""
    var raw_move_vector: Vec2
    """`move_vector` before input permissions, speeds and normalisation."""

    def __init__(out self):
        """Creates the packet with every field zero and no flags set."""
        self.pitch = 0
        self.yaw = 0
        self.position = Vec3()
        self.move_vector = Vec2()
        self.head_yaw = 0
        self.input_data = InputFlags(INPUT_FLAG_COUNT)
        self.input_mode = 0
        self.play_mode = 0
        self.interaction_model = 0
        self.interact_pitch = 0
        self.interact_yaw = 0
        self.tick = 0
        self.delta = Vec3()
        self.item_interaction_data = None
        self.item_stack_request = None
        self.block_actions = None
        self.vehicle_rotation = None
        self.client_predicted_vehicle = None
        self.analogue_move_vector = Vec2()
        self.camera_orientation = Vec3()
        self.raw_move_vector = Vec2()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.pitch)
        io.float32(self.yaw)
        vec3(io, self.position)
        vec2(io, self.move_vector)
        io.float32(self.head_yaw)
        input_flag_list(io, self.input_data, INPUT_FLAG_COUNT)
        io.varuint32(self.input_mode)
        io.varuint32(self.play_mode)
        io.varint32(self.interaction_model)
        io.float32(self.interact_pitch)
        io.float32(self.interact_yaw)
        io.varuint64(self.tick)
        vec3(io, self.delta)
        optional_func[player_inventory_action[I]](
            io, self.item_interaction_data
        )
        optional_marshaler(io, self.item_stack_request)
        optional_func[slice[PlayerBlockAction, I]](io, self.block_actions)
        optional_func[vec2[I]](io, self.vehicle_rotation)
        optional_func[actor_unique_id[I]](io, self.client_predicted_vehicle)
        vec2(io, self.analogue_move_vector)
        vec3(io, self.camera_orientation)
        vec2(io, self.raw_move_vector)
