"""Camera presets and instructions (gophertunnel `protocol/camera.go`).

Go sends easing types by name; `_easing_type` converts in both directions
and fails on an unknown value when reading or writing, as Go does.
"""

from .color import RGBA
from .io import func_slice, optional_func
from .io import (
    IO,
    Marshaler,
    invalid_value,
    optional_marshaler,
    rgb,
    slice,
    string_slice,
    vec2,
    vec3,
)
from .math import Vec2, Vec3

comptime AIM_ASSIST_TARGET_MODE_ANGLE: Int32 = 0
"""Aim assist looks for targets within an angle of the cursor."""
comptime AIM_ASSIST_TARGET_MODE_DISTANCE: Int32 = 1
"""Aim assist looks for targets within a distance of the cursor."""

comptime AUDIO_LISTENER_CAMERA: UInt8 = 0
"""Audio is heard from the camera."""
comptime AUDIO_LISTENER_PLAYER: UInt8 = 1
"""Audio is heard from the player."""


comptime EASING_TYPE_LINEAR: Int32 = 0
"""The `linear` easing function."""
comptime EASING_TYPE_SPRING: Int32 = 1
"""The `spring` easing function."""
comptime EASING_TYPE_IN_QUAD: Int32 = 2
"""The `in_quad` easing function."""
comptime EASING_TYPE_OUT_QUAD: Int32 = 3
"""The `out_quad` easing function."""
comptime EASING_TYPE_IN_OUT_QUAD: Int32 = 4
"""The `in_out_quad` easing function."""
comptime EASING_TYPE_IN_CUBIC: Int32 = 5
"""The `in_cubic` easing function."""
comptime EASING_TYPE_OUT_CUBIC: Int32 = 6
"""The `out_cubic` easing function."""
comptime EASING_TYPE_IN_OUT_CUBIC: Int32 = 7
"""The `in_out_cubic` easing function."""
comptime EASING_TYPE_IN_QUART: Int32 = 8
"""The `in_quart` easing function."""
comptime EASING_TYPE_OUT_QUART: Int32 = 9
"""The `out_quart` easing function."""
comptime EASING_TYPE_IN_OUT_QUART: Int32 = 10
"""The `in_out_quart` easing function."""
comptime EASING_TYPE_IN_QUINT: Int32 = 11
"""The `in_quint` easing function."""
comptime EASING_TYPE_OUT_QUINT: Int32 = 12
"""The `out_quint` easing function."""
comptime EASING_TYPE_IN_OUT_QUINT: Int32 = 13
"""The `in_out_quint` easing function."""
comptime EASING_TYPE_IN_SINE: Int32 = 14
"""The `in_sine` easing function."""
comptime EASING_TYPE_OUT_SINE: Int32 = 15
"""The `out_sine` easing function."""
comptime EASING_TYPE_IN_OUT_SINE: Int32 = 16
"""The `in_out_sine` easing function."""
comptime EASING_TYPE_IN_EXPO: Int32 = 17
"""The `in_expo` easing function."""
comptime EASING_TYPE_OUT_EXPO: Int32 = 18
"""The `out_expo` easing function."""
comptime EASING_TYPE_IN_OUT_EXPO: Int32 = 19
"""The `in_out_expo` easing function."""
comptime EASING_TYPE_IN_CIRC: Int32 = 20
"""The `in_circ` easing function."""
comptime EASING_TYPE_OUT_CIRC: Int32 = 21
"""The `out_circ` easing function."""
comptime EASING_TYPE_IN_OUT_CIRC: Int32 = 22
"""The `in_out_circ` easing function."""
comptime EASING_TYPE_IN_BOUNCE: Int32 = 23
"""The `in_bounce` easing function."""
comptime EASING_TYPE_OUT_BOUNCE: Int32 = 24
"""The `out_bounce` easing function."""
comptime EASING_TYPE_IN_OUT_BOUNCE: Int32 = 25
"""The `in_out_bounce` easing function."""
comptime EASING_TYPE_IN_BACK: Int32 = 26
"""The `in_back` easing function."""
comptime EASING_TYPE_OUT_BACK: Int32 = 27
"""The `out_back` easing function."""
comptime EASING_TYPE_IN_OUT_BACK: Int32 = 28
"""The `in_out_back` easing function."""
comptime EASING_TYPE_IN_ELASTIC: Int32 = 29
"""The `in_elastic` easing function."""
comptime EASING_TYPE_OUT_ELASTIC: Int32 = 30
"""The `out_elastic` easing function."""
comptime EASING_TYPE_IN_OUT_ELASTIC: Int32 = 31
"""The `in_out_elastic` easing function."""
comptime EASING_TYPE_INVERSE_LERP: Int32 = 32
"""The `inverse_lerp` easing function."""

comptime _EASING_TYPE_NAMES: List[StaticString] = [
    "linear",
    "spring",
    "in_quad",
    "out_quad",
    "in_out_quad",
    "in_cubic",
    "out_cubic",
    "in_out_cubic",
    "in_quart",
    "out_quart",
    "in_out_quart",
    "in_quint",
    "out_quint",
    "in_out_quint",
    "in_sine",
    "out_sine",
    "in_out_sine",
    "in_expo",
    "out_expo",
    "in_out_expo",
    "in_circ",
    "out_circ",
    "in_out_circ",
    "in_bounce",
    "out_bounce",
    "in_out_bounce",
    "in_back",
    "out_back",
    "in_out_back",
    "in_elastic",
    "out_elastic",
    "in_out_elastic",
    "inverse_lerp",
]


def _easing_type_to_string(x: Int32) -> String:
    ref names = materialize[_EASING_TYPE_NAMES]()
    if x < 0 or Int(x) >= len(names):
        return "unknown"
    return String(names[Int(x)])


def _easing_type_from_string(s: String) raises -> Int32:
    ref names = materialize[_EASING_TYPE_NAMES]()
    for i in range(len(names)):
        if s == names[i]:
            return Int32(i)
    invalid_value(s, "easingType", "unknown easing type")
    return 0


def _easing_type[I: IO](mut io: I, mut x: Int32) raises:
    """Marshals an easing type as its name (Go `easingTypeToString` and
    `easingTypeFromString`)."""
    var name = _easing_type_to_string(x)
    io.string(name)
    x = _easing_type_from_string(name)


comptime SPLINE_TYPE_CATMULL_ROM: StaticString = "catmullrom"
"""A Catmull-Rom spline."""
comptime SPLINE_TYPE_LINEAR: StaticString = "linear"
"""A linear spline."""


struct CameraEase(Marshaler):
    """An easing function used by a `CameraInstructionSet`."""

    var type: UInt8
    """One of the `EASING_TYPE_*` values."""
    var duration: Float32
    """The duration in seconds."""

    def __init__(out self):
        """Creates the zero value."""
        self.type = 0
        self.duration = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.uint8(self.type)
        io.float32(self.duration)


struct CameraInstructionSet(Marshaler):
    """Sets the camera to a preset, optionally eased, moved and rotated."""

    var preset: UInt32
    """The index of the preset in the CameraPresets packet."""
    var ease: Optional[CameraEase]
    """The easing function."""
    var position: Optional[Vec3]
    """The position of the camera."""
    var rotation: Optional[Vec2]
    """The rotation of the camera."""
    var facing: Optional[Vec3]
    """A point the camera keeps facing."""
    var view_offset: Optional[Vec2]
    """An offset from a pivot point to the player."""
    var entity_offset: Optional[Vec3]
    """An offset from the entity the camera renders at."""
    var default: Optional[Bool]
    """Whether the camera is a default camera."""
    var ignore_starting_values_component: Bool
    """Purpose unknown."""

    def __init__(out self):
        """Creates the zero value."""
        self.preset = 0
        self.ease = None
        self.position = None
        self.rotation = None
        self.facing = None
        self.view_offset = None
        self.entity_offset = None
        self.default = None
        self.ignore_starting_values_component = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.uint32(self.preset)
        optional_marshaler(io, self.ease)
        optional_func[vec3[I]](io, self.position)
        optional_func[vec2[I]](io, self.rotation)
        optional_func[vec3[I]](io, self.facing)
        optional_func[vec2[I]](io, self.view_offset)
        optional_func[vec3[I]](io, self.entity_offset)
        optional_func[I.bool](io, self.default)
        io.bool(self.ignore_starting_values_component)


struct CameraFadeTimeData(Marshaler):
    """The timing of a `CameraInstructionFade`."""

    var fade_in_duration: Float32
    """Seconds to fully fade in."""
    var wait_duration: Float32
    """Seconds to wait before fading out."""
    var fade_out_duration: Float32
    """Seconds to fully fade out."""

    def __init__(out self):
        """Creates the zero value."""
        self.fade_in_duration = 0
        self.wait_duration = 0
        self.fade_out_duration = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.float32(self.fade_in_duration)
        io.float32(self.wait_duration)
        io.float32(self.fade_out_duration)


struct CameraInstructionFade(Marshaler):
    """Fades the screen to a colour."""

    var time_data: Optional[CameraFadeTimeData]
    """The fade timing."""
    var colour: Optional[RGBA]
    """The colour; only red, green and blue are used."""

    def __init__(out self):
        """Creates the zero value."""
        self.time_data = None
        self.colour = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        optional_marshaler(io, self.time_data)
        optional_func[rgb[I]](io, self.colour)


struct CameraInstructionTarget(Marshaler):
    """Makes the camera target an entity."""

    var center_offset: Optional[Vec3]
    """The offset from the centre of the entity."""
    var entity_unique_id: Int64
    """The unique ID of the targeted entity."""

    def __init__(out self):
        """Creates the zero value."""
        self.center_offset = None
        self.entity_unique_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        optional_func[vec3[I]](io, self.center_offset)
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        io.int64(self.entity_unique_id)


struct CameraInstructionFieldOfView(Marshaler):
    """Changes the field of view."""

    var field_of_view: Float32
    """The field of view."""
    var ease_time: Float32
    """The easing duration in seconds."""
    var ease_type: Int32
    """One of the `EASING_TYPE_*` values; sent by name."""
    var clear: Bool
    """Clears the current instruction."""

    def __init__(out self):
        """Creates the zero value."""
        self.field_of_view = 0
        self.ease_time = 0
        self.ease_type = 0
        self.clear = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.float32(self.field_of_view)
        io.float32(self.ease_time)
        _easing_type(io, self.ease_type)
        io.bool(self.clear)


struct CameraPreset(Marshaler):
    """A basic preset that more complex instructions extend."""

    var name: String
    """The unique name of the preset."""
    var parent: String
    """The name of the preset this one extends; may be empty."""
    var pos_x: Optional[Float32]
    """The default X position."""
    var pos_y: Optional[Float32]
    """The default Y position."""
    var pos_z: Optional[Float32]
    """The default Z position."""
    var rot_x: Optional[Float32]
    """The default pitch."""
    var rot_y: Optional[Float32]
    """The default yaw."""
    var rotation_speed: Optional[Float32]
    """The rotation speed."""
    var snap_to_target: Optional[Bool]
    """Whether the camera snaps to the target entity."""
    var horizontal_rotation_limit: Optional[Vec2]
    """The horizontal rotation limit."""
    var vertical_rotation_limit: Optional[Vec2]
    """The vertical rotation limit."""
    var continue_targeting: Optional[Bool]
    """Whether targeting continues with aim assist."""
    var tracking_radius: Optional[Float32]
    """The radius in which aim assist tracks targets."""
    var view_offset: Optional[Vec2]
    """The pivot offset of a follow_orbit camera."""
    var entity_offset: Optional[Vec3]
    """The offset from the entity the camera renders at."""
    var radius: Optional[Float32]
    """The distance of a follow_orbit camera from the player."""
    var min_yaw_limit: Optional[Float32]
    """The minimum yaw."""
    var max_yaw_limit: Optional[Float32]
    """The maximum yaw."""
    var audio_listener: Optional[UInt8]
    """One of the `AUDIO_LISTENER_*` values."""
    var player_effects: Optional[Bool]
    """Purpose unknown."""
    var aim_assist: Optional[CameraPresetAimAssist]
    """The aim assist of the preset."""
    var control_scheme: Optional[UInt8]
    """The control scheme used in this camera."""
    var apply_inherited_starting_rotation: Bool
    """Starts at the parent preset's rotation instead of `starting_rotation`."""
    var starting_rotation: Optional[Vec2]
    """The rotation the camera starts at."""

    def __init__(out self):
        """Creates the zero value."""
        self.name = String()
        self.parent = String()
        self.pos_x = None
        self.pos_y = None
        self.pos_z = None
        self.rot_x = None
        self.rot_y = None
        self.rotation_speed = None
        self.snap_to_target = None
        self.horizontal_rotation_limit = None
        self.vertical_rotation_limit = None
        self.continue_targeting = None
        self.tracking_radius = None
        self.view_offset = None
        self.entity_offset = None
        self.radius = None
        self.min_yaw_limit = None
        self.max_yaw_limit = None
        self.audio_listener = None
        self.player_effects = None
        self.aim_assist = None
        self.control_scheme = None
        self.apply_inherited_starting_rotation = False
        self.starting_rotation = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.string(self.name)
        io.string(self.parent)
        optional_func[I.float32](io, self.pos_x)
        optional_func[I.float32](io, self.pos_y)
        optional_func[I.float32](io, self.pos_z)
        optional_func[I.float32](io, self.rot_x)
        optional_func[I.float32](io, self.rot_y)
        optional_func[I.float32](io, self.rotation_speed)
        optional_func[I.bool](io, self.snap_to_target)
        optional_func[vec2[I]](io, self.horizontal_rotation_limit)
        optional_func[vec2[I]](io, self.vertical_rotation_limit)
        optional_func[I.bool](io, self.continue_targeting)
        optional_func[I.float32](io, self.tracking_radius)
        optional_func[vec2[I]](io, self.view_offset)
        optional_func[vec3[I]](io, self.entity_offset)
        optional_func[I.float32](io, self.radius)
        optional_func[I.float32](io, self.min_yaw_limit)
        optional_func[I.float32](io, self.max_yaw_limit)
        optional_func[I.uint8](io, self.audio_listener)
        optional_func[I.bool](io, self.player_effects)
        optional_marshaler(io, self.aim_assist)
        optional_func[I.uint8](io, self.control_scheme)
        io.bool(self.apply_inherited_starting_rotation)
        optional_func[vec2[I]](io, self.starting_rotation)


struct CameraPresetAimAssist(Marshaler):
    """The aim assist settings of a camera preset."""

    var preset: Optional[String]
    """The ID of a preset from the CameraAimAssistPresets packet."""
    var target_mode: Optional[Int32]
    """One of the `AIM_ASSIST_TARGET_MODE_*` values."""
    var angle: Optional[Vec2]
    """The largest angle around the cursor to check, for the angle mode."""
    var distance: Optional[Float32]
    """The largest distance from the cursor to check, for the distance mode."""

    def __init__(out self):
        """Creates the zero value."""
        self.preset = None
        self.target_mode = None
        self.angle = None
        self.distance = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        optional_func[I.string](io, self.preset)
        optional_func[I.int32](io, self.target_mode)
        optional_func[vec2[I]](io, self.angle)
        optional_func[I.float32](io, self.distance)


struct CameraAimAssistCategory(Marshaler):
    """An aim assist category with block and entity priorities."""

    var name: String
    """The name presets refer to the category by."""
    var priorities: CameraAimAssistPriorities
    """The priorities of the category."""

    def __init__(out self):
        """Creates the zero value."""
        self.name = String()
        self.priorities = CameraAimAssistPriorities()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.string(self.name)
        self.priorities.marshal(io)


struct CameraAimAssistPriorities(Marshaler):
    """Block and entity priorities for aim assist targeting."""

    var entities: List[CameraAimAssistPriority]
    """Priorities of entity identifiers."""
    var blocks: List[CameraAimAssistPriority]
    """Priorities of block identifiers."""
    var block_tags: List[CameraAimAssistPriority]
    """Priorities of block tags."""
    var entity_type_families: List[CameraAimAssistPriority]
    """Priorities of entity type families."""
    var entity_default: Optional[Int32]
    """The default entity priority."""
    var block_default: Optional[Int32]
    """The default block priority."""

    def __init__(out self):
        """Creates the zero value."""
        self.entities = List[CameraAimAssistPriority]()
        self.blocks = List[CameraAimAssistPriority]()
        self.block_tags = List[CameraAimAssistPriority]()
        self.entity_type_families = List[CameraAimAssistPriority]()
        self.entity_default = None
        self.block_default = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        slice(io, self.entities)
        slice(io, self.blocks)
        slice(io, self.block_tags)
        slice(io, self.entity_type_families)
        optional_func[I.int32](io, self.entity_default)
        optional_func[I.int32](io, self.block_default)


struct CameraAimAssistPriority(Marshaler):
    """The priority of one aim assist target."""

    var identifier: String
    """The identifier of the target."""
    var priority: Int32
    """The priority."""

    def __init__(out self):
        """Creates the zero value."""
        self.identifier = String()
        self.priority = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.string(self.identifier)
        io.int32(self.priority)


struct CameraAimAssistPreset(Marshaler):
    """A base aim assist preset."""

    var identifier: String
    """The identifier of the preset."""
    var block_exclusions: List[String]
    """Block identifiers aim assist ignores."""
    var entity_exclusions: List[String]
    """Entity identifiers aim assist ignores."""
    var block_tag_exclusions: List[String]
    """Block tags aim assist ignores."""
    var entity_type_family_exclusions: List[String]
    """Entity type families aim assist ignores."""
    var liquid_targets: List[String]
    """Entity identifiers targeted inside liquids."""
    var item_settings: List[CameraAimAssistItemSettings]
    """Settings for specific items."""
    var default_item_settings: Optional[String]
    """The category used for items not in `item_settings`."""
    var hand_settings: Optional[String]
    """The category used when no item is held."""

    def __init__(out self):
        """Creates the zero value."""
        self.identifier = String()
        self.block_exclusions = List[String]()
        self.entity_exclusions = List[String]()
        self.block_tag_exclusions = List[String]()
        self.entity_type_family_exclusions = List[String]()
        self.liquid_targets = List[String]()
        self.item_settings = List[CameraAimAssistItemSettings]()
        self.default_item_settings = None
        self.hand_settings = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.string(self.identifier)
        string_slice(io, self.block_exclusions)
        string_slice(io, self.entity_exclusions)
        string_slice(io, self.block_tag_exclusions)
        string_slice(io, self.entity_type_family_exclusions)
        string_slice(io, self.liquid_targets)
        slice(io, self.item_settings)
        optional_func[I.string](io, self.default_item_settings)
        optional_func[I.string](io, self.hand_settings)


struct CameraAimAssistItemSettings(Marshaler):
    """The aim assist category used for an item."""

    var item: String
    """The item identifier."""
    var category: String
    """The category identifier."""

    def __init__(out self):
        """Creates the zero value."""
        self.item = String()
        self.category = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.string(self.item)
        io.string(self.category)


struct CameraRotationOption(Marshaler):
    """A rotation key frame of a camera spline."""

    var value: Vec3
    """The rotation."""
    var time: Float32
    """The time of the key frame."""
    var ease_type: Int32
    """One of the `EASING_TYPE_*` values; sent by name."""

    def __init__(out self):
        """Creates the zero value."""
        self.value = Vec3()
        self.time = 0
        self.ease_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        vec3(io, self.value)
        io.float32(self.time)
        _easing_type(io, self.ease_type)


struct CameraProgressOption(Marshaler):
    """A progress key frame of a camera spline."""

    var value: Float32
    """The progress."""
    var time: Float32
    """The time of the key frame."""
    var ease_type: Int32
    """One of the `EASING_TYPE_*` values; sent by name."""

    def __init__(out self):
        """Creates the zero value."""
        self.value = 0
        self.time = 0
        self.ease_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.float32(self.value)
        io.float32(self.time)
        _easing_type(io, self.ease_type)


struct CameraSplineInstruction(Marshaler):
    """Moves the camera along a spline."""

    var total_time: Float32
    """The length of the animation."""
    var spline_type: Optional[UInt8]
    """The interpolation type."""
    var curve: List[Vec3]
    """The points of the curve."""
    var progress_key_frames: List[CameraProgressOption]
    """The progress key frames."""
    var rotation_options: List[CameraRotationOption]
    """The rotation key frames."""
    var spline_identifier: Optional[String]
    """A name to refer to the spline by."""
    var load_from_json: Optional[Bool]
    """Whether to load the spline from a JSON definition."""

    def __init__(out self):
        """Creates the zero value."""
        self.total_time = 0
        self.spline_type = None
        self.curve = List[Vec3]()
        self.progress_key_frames = List[CameraProgressOption]()
        self.rotation_options = List[CameraRotationOption]()
        self.spline_identifier = None
        self.load_from_json = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.float32(self.total_time)
        optional_func[I.uint8](io, self.spline_type)
        func_slice[vec3[I]](io, self.curve)
        slice(io, self.progress_key_frames)
        slice(io, self.rotation_options)
        optional_func[I.string](io, self.spline_identifier)
        optional_func[I.bool](io, self.load_from_json)


struct CameraSplineDefinition(Marshaler):
    """A named camera spline."""

    var name: String
    """The name of the spline."""
    var total_time: Float32
    """The length of the animation."""
    var spline_type: Optional[String]
    """One of the `SPLINE_TYPE_*` values."""
    var control_points: List[Vec3]
    """The points of the curve."""
    var progress_key_frames: List[CameraProgressOption]
    """The progress key frames."""
    var rotation_key_frames: List[CameraRotationOption]
    """The rotation key frames."""

    def __init__(out self):
        """Creates the zero value."""
        self.name = String()
        self.total_time = 0
        self.spline_type = None
        self.control_points = List[Vec3]()
        self.progress_key_frames = List[CameraProgressOption]()
        self.rotation_key_frames = List[CameraRotationOption]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.string(self.name)
        io.float32(self.total_time)
        optional_func[I.string](io, self.spline_type)
        func_slice[vec3[I]](io, self.control_points)
        slice(io, self.progress_key_frames)
        slice(io, self.rotation_key_frames)


struct CameraAimAssistActorPriorityData(Marshaler):
    """The aim assist priority of an actor."""

    var preset_index: Int32
    """The index of the aim assist preset."""
    var category_index: Int32
    """The index of the aim assist category."""
    var actor_index: Int32
    """The index of the actor."""
    var priority: Int32
    """The priority."""

    def __init__(out self):
        """Creates the zero value."""
        self.preset_index = 0
        self.category_index = 0
        self.actor_index = 0
        self.priority = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field."""
        io.int32(self.preset_index)
        io.int32(self.category_index)
        io.int32(self.actor_index)
        io.int32(self.priority)
