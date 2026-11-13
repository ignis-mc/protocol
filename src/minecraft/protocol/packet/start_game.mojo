"""The `StartGame` packet (gophertunnel `packet/start_game.go`).

`property_data` starts as an empty compound, not an empty `NBT`, so the zero
packet encodes like Go's nil map (`0a 00 00`).
"""

from ...nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from ..block import BlockEntry
from ..block_pos import BlockPos
from ..education import EducationSharedResourceURI
from ..experiments import ExperimentData
from ..game_rule import GameRule, game_rule
from ..io import (
    IO,
    actor_runtime_id,
    actor_unique_id,
    block_pos,
    func_slice,
    optional_bool,
    optional_marshaler,
    slice,
    slice_uint32_length,
    uuid,
    vec3,
)
from ..math import Vec3
from ..player import PlayerMovementSettings, player_move_settings
from ..server_join_information import ServerJoinInformation
from ..uuid import UUID
from .id import ID_START_GAME
from .packet import Packet

comptime SPAWN_BIOME_TYPE_DEFAULT: Int16 = 0
"""The player spawns in a built-in biome."""
comptime SPAWN_BIOME_TYPE_USER_DEFINED: Int16 = 1
"""The player spawns in a biome defined by a behaviour pack."""

comptime XBL_BROADCAST_MODE_NO_MULTI_PLAY: Int32 = 0
"""The game is not broadcast."""
comptime XBL_BROADCAST_MODE_INVITE_ONLY: Int32 = 1
"""Only invited players can join."""
comptime XBL_BROADCAST_MODE_FRIENDS_ONLY: Int32 = 2
"""Friends can join."""
comptime XBL_BROADCAST_MODE_FRIENDS_OF_FRIENDS: Int32 = 3
"""Friends of friends can join."""
comptime XBL_BROADCAST_MODE_PUBLIC: Int32 = 4
"""Anyone can join."""

comptime CHAT_RESTRICTION_LEVEL_NONE: UInt8 = 0
"""Chat is not restricted."""
comptime CHAT_RESTRICTION_LEVEL_DROPPED: UInt8 = 1
"""Chat messages are dropped."""
comptime CHAT_RESTRICTION_LEVEL_DISABLED: UInt8 = 2
"""Chat is disabled."""

comptime EDITOR_WORLD_TYPE_NOT_EDITOR: Int32 = 0
"""The world is not an editor world."""
comptime EDITOR_WORLD_TYPE_PROJECT: Int32 = 1
"""The world is an editor project."""
comptime EDITOR_WORLD_TYPE_TEST_LEVEL: Int32 = 2
"""The world is an editor test level."""
comptime EDITOR_WORLD_TYPE_REALMS_UPLOAD: Int32 = 3
"""The world is an editor Realms upload."""

comptime EDITOR_LEVEL_MIGRATION_VERSION_LEGACY: Int8 = 0
"""No editor migrations were applied."""
comptime EDITOR_LEVEL_MIGRATION_VERSION_EDITOR_ACHIEVEMENTS: Int8 = 1
"""The editor achievements migration was applied."""


struct StartGame(Packet):
    """Sent by the server with the world the player spawns in."""

    comptime ID: UInt32 = ID_START_GAME
    """The packet ID."""
    var entity_unique_id: Int64
    """The unique ID of the player."""
    var entity_runtime_id: UInt64
    """The runtime ID of the player."""
    var player_game_mode: Int32
    """The player's game mode; 5 falls back to `world_game_mode`."""
    var player_position: Vec3
    """The spawn position of the player."""
    var pitch: Float32
    """The vertical rotation of the player in degrees."""
    var yaw: Float32
    """The horizontal rotation of the player in degrees."""
    var world_seed: Int64
    """The seed of the world."""
    var spawn_biome_type: Int16
    """One of the `SPAWN_BIOME_TYPE_*` values."""
    var user_defined_biome_name: String
    """The name of the biome the player spawns in."""
    var dimension: Int32
    """The dimension: 0 overworld, 1 nether, 2 end."""
    var generator: Int32
    """The world generator: 0 limited, 1 infinite, 2 flat, 3 nether, 4 end."""
    var world_game_mode: Int32
    """The default game mode of the world."""
    var hardcore: Bool
    """Whether the world is in hardcore mode."""
    var difficulty: Int32
    """The difficulty, 0 (peaceful) to 3 (hard)."""
    var world_spawn: BlockPos
    """The world spawn, used by compasses."""
    var achievements_disabled: Bool
    """Whether achievements are disabled."""
    var editor_world_type: Int32
    """One of the `EDITOR_WORLD_TYPE_*` values."""
    var created_in_editor: Bool
    """Whether the world was created in editor mode."""
    var exported_from_editor: Bool
    """Whether the world was exported from editor mode."""
    var editor_level_migration_version: Int8
    """One of the `EDITOR_LEVEL_MIGRATION_VERSION_*` values."""
    var server_editor_connection_policy: Int32
    """The editor connection policy."""
    var allow_anonymous_block_drops_in_editor_worlds: Bool
    """Whether hybrid editor worlds allow anonymous block drops."""
    var day_cycle_lock_time: Int32
    """The time the day cycle is locked at when it is disabled."""
    var education_edition_offer: UInt32
    """The Education Edition region: 0 none, 1 rest of world, 2 China."""
    var education_features_enabled: Bool
    """Whether Education Edition features are enabled."""
    var education_product_id: String
    """The ID of the Education Edition server instance."""
    var rain_level: Float32
    """The intensity of the rain."""
    var lightning_level: Float32
    """The intensity of the thunder."""
    var confirmed_platform_locked_content: Bool
    """Whether platform-locked content was confirmed."""
    var multi_player_game: Bool
    """Whether the world is a multiplayer game; true for servers."""
    var lan_broadcast_enabled: Bool
    """Whether LAN broadcast is enabled."""
    var xbl_broadcast_mode: Int32
    """One of the `XBL_BROADCAST_MODE_*` values for Xbox Live."""
    var platform_broadcast_mode: Int32
    """One of the `XBL_BROADCAST_MODE_*` values for the platform."""
    var commands_enabled: Bool
    """Whether the player can use commands."""
    var texture_pack_required: Bool
    """Whether the world's texture pack is required."""
    var game_rules: List[GameRule]
    """The active game rules."""
    var experiments: List[ExperimentData]
    """The experiments that are enabled or disabled."""
    var experiments_previously_toggled: Bool
    """Whether experiments were ever toggled in the world."""
    var bonus_chest_enabled: Bool
    """Whether the bonus chest setting was on."""
    var start_with_map_enabled: Bool
    """Whether players start with a map."""
    var player_permissions: UInt8
    """The permission level: 0 visitor, 1 member, 2 operator, 3 custom."""
    var server_chunk_tick_radius: Int32
    """The radius around the player in which chunks are ticked."""
    var has_locked_behaviour_pack: Bool
    """Whether the world's behaviour pack is locked."""
    var has_locked_texture_pack: Bool
    """Whether the world's texture pack is locked."""
    var from_locked_world_template: Bool
    """Whether the world came from a locked template."""
    var msa_gamer_tags_only: Bool
    """Whether only Microsoft account gamer tags are shown."""
    var from_world_template: Bool
    """Whether the world came from a template."""
    var world_template_settings_locked: Bool
    """Whether the template locks the world settings."""
    var only_spawn_v1_villagers: Bool
    """A legacy villager flag the client never reads."""
    var persona_disabled: Bool
    """Whether persona skins are disabled."""
    var custom_skins_disabled: Bool
    """Whether custom skins are disabled."""
    var emote_chat_muted: Bool
    """Whether emote chat messages are muted."""
    var base_game_version: String
    """The game version whose vanilla features are used."""
    var limited_world_width: Int32
    """The width of a limited world."""
    var limited_world_depth: Int32
    """The depth of a limited world."""
    var new_nether: Bool
    """Whether the 1.16 nether is used."""
    var education_shared_resource_uri: EducationSharedResourceURI
    """An Education Edition resource button."""
    var force_experimental_gameplay: Optional[Bool]
    """Forces experimental gameplay on or off; servers leave it empty."""
    var level_id: String
    """The base64 ID of the world."""
    var world_name: String
    """The name of the world, shown above the player list."""
    var template_content_identity: String
    """The UUID of the premium world template, if any."""
    var trial: Bool
    """Whether the world is a trial world."""
    var player_movement_settings: PlayerMovementSettings
    """The server-authoritative movement settings."""
    var time: Int64
    """The time elapsed since the start of the world."""
    var enchantment_seed: Int32
    """The seed of the enchantment table random."""
    var blocks: List[BlockEntry]
    """The custom blocks registered on the server."""
    var multi_player_correlation_id: String
    """A unique ID of the multiplayer session."""
    var server_authoritative_inventory: Bool
    """Whether the server-authoritative inventory is enabled."""
    var game_version: String
    """The game version of the server."""
    var property_data: NBT
    """Properties of the player (a network little-endian compound)."""
    var server_block_state_checksum: UInt64
    """A checksum of the block states, or 0 to skip the check."""
    var client_side_generation: Bool
    """Whether the client generates terrain itself."""
    var world_template_id: UUID
    """The template the world was generated from."""
    var chat_restriction_level: UInt8
    """One of the `CHAT_RESTRICTION_LEVEL_*` values."""
    var disable_player_interactions: Bool
    """Whether the client ignores other players when interacting."""
    var use_block_network_id_hashes: Bool
    """Whether block network IDs are name hashes instead of indices."""
    var server_authoritative_sound: Bool
    """Whether sounds are server-authoritative."""
    var server_join_information: Optional[ServerJoinInformation]
    """Information about the server being joined, if any."""
    var server_id: String
    """The server identifier for telemetry."""
    var scenario_id: String
    """The scenario identifier for telemetry."""
    var world_id: String
    """The world identifier for telemetry."""
    var owner_id: String
    """The owner identifier for telemetry."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.player_game_mode = 0
        self.player_position = Vec3()
        self.pitch = 0
        self.yaw = 0
        self.world_seed = 0
        self.spawn_biome_type = 0
        self.user_defined_biome_name = String()
        self.dimension = 0
        self.generator = 0
        self.world_game_mode = 0
        self.hardcore = False
        self.difficulty = 0
        self.world_spawn = BlockPos()
        self.achievements_disabled = False
        self.editor_world_type = 0
        self.created_in_editor = False
        self.exported_from_editor = False
        self.editor_level_migration_version = 0
        self.server_editor_connection_policy = 0
        self.allow_anonymous_block_drops_in_editor_worlds = False
        self.day_cycle_lock_time = 0
        self.education_edition_offer = 0
        self.education_features_enabled = False
        self.education_product_id = String()
        self.rain_level = 0
        self.lightning_level = 0
        self.confirmed_platform_locked_content = False
        self.multi_player_game = False
        self.lan_broadcast_enabled = False
        self.xbl_broadcast_mode = 0
        self.platform_broadcast_mode = 0
        self.commands_enabled = False
        self.texture_pack_required = False
        self.game_rules = List[GameRule]()
        self.experiments = List[ExperimentData]()
        self.experiments_previously_toggled = False
        self.bonus_chest_enabled = False
        self.start_with_map_enabled = False
        self.player_permissions = 0
        self.server_chunk_tick_radius = 0
        self.has_locked_behaviour_pack = False
        self.has_locked_texture_pack = False
        self.from_locked_world_template = False
        self.msa_gamer_tags_only = False
        self.from_world_template = False
        self.world_template_settings_locked = False
        self.only_spawn_v1_villagers = False
        self.persona_disabled = False
        self.custom_skins_disabled = False
        self.emote_chat_muted = False
        self.base_game_version = String()
        self.limited_world_width = 0
        self.limited_world_depth = 0
        self.new_nether = False
        self.education_shared_resource_uri = EducationSharedResourceURI()
        self.force_experimental_gameplay = None
        self.level_id = String()
        self.world_name = String()
        self.template_content_identity = String()
        self.trial = False
        self.player_movement_settings = PlayerMovementSettings()
        self.time = 0
        self.enchantment_seed = 0
        self.blocks = List[BlockEntry]()
        self.multi_player_correlation_id = String()
        self.server_authoritative_inventory = False
        self.game_version = String()
        self.property_data = NBT.empty_compound()
        self.server_block_state_checksum = 0
        self.client_side_generation = False
        self.world_template_id = UUID()
        self.chat_restriction_level = 0
        self.disable_player_interactions = False
        self.use_block_network_id_hashes = False
        self.server_authoritative_sound = False
        self.server_join_information = None
        self.server_id = String()
        self.scenario_id = String()
        self.world_id = String()
        self.owner_id = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        actor_unique_id(io, self.entity_unique_id)
        actor_runtime_id(io, self.entity_runtime_id)
        io.varint32(self.player_game_mode)
        vec3(io, self.player_position)
        io.float32(self.pitch)
        io.float32(self.yaw)
        io.int64(self.world_seed)
        io.int16(self.spawn_biome_type)
        io.string(self.user_defined_biome_name)
        io.varint32(self.dimension)
        io.varint32(self.generator)
        io.varint32(self.world_game_mode)
        io.bool(self.hardcore)
        io.varint32(self.difficulty)
        block_pos(io, self.world_spawn)
        io.bool(self.achievements_disabled)
        io.varint32(self.editor_world_type)
        io.bool(self.created_in_editor)
        io.bool(self.exported_from_editor)
        io.int8(self.editor_level_migration_version)
        io.varint32(self.day_cycle_lock_time)
        io.varuint32(self.education_edition_offer)
        io.bool(self.education_features_enabled)
        io.string(self.education_product_id)
        io.float32(self.rain_level)
        io.float32(self.lightning_level)
        io.bool(self.confirmed_platform_locked_content)
        io.bool(self.multi_player_game)
        io.bool(self.lan_broadcast_enabled)
        io.varint32(self.xbl_broadcast_mode)
        io.varint32(self.platform_broadcast_mode)
        io.bool(self.commands_enabled)
        io.bool(self.texture_pack_required)
        func_slice[game_rule[I]](io, self.game_rules)
        slice_uint32_length(io, self.experiments)
        io.bool(self.experiments_previously_toggled)
        io.bool(self.bonus_chest_enabled)
        io.bool(self.start_with_map_enabled)
        io.uint8(self.player_permissions)
        io.int32(self.server_chunk_tick_radius)
        io.bool(self.has_locked_behaviour_pack)
        io.bool(self.has_locked_texture_pack)
        io.bool(self.from_locked_world_template)
        io.bool(self.msa_gamer_tags_only)
        io.bool(self.from_world_template)
        io.bool(self.world_template_settings_locked)
        io.bool(self.only_spawn_v1_villagers)
        io.bool(self.persona_disabled)
        io.bool(self.custom_skins_disabled)
        io.bool(self.emote_chat_muted)
        io.string(self.base_game_version)
        io.int32(self.limited_world_width)
        io.int32(self.limited_world_depth)
        io.bool(self.new_nether)
        self.education_shared_resource_uri.marshal(io)
        optional_bool(io, self.force_experimental_gameplay)
        io.uint8(self.chat_restriction_level)
        io.bool(self.disable_player_interactions)
        io.varint32(self.server_editor_connection_policy)
        io.bool(self.allow_anonymous_block_drops_in_editor_worlds)
        io.string(self.level_id)
        io.string(self.world_name)
        io.string(self.template_content_identity)
        io.bool(self.trial)
        player_move_settings(io, self.player_movement_settings)
        io.int64(self.time)
        io.varint32(self.enchantment_seed)
        slice(io, self.blocks)
        io.string(self.multi_player_correlation_id)
        io.bool(self.server_authoritative_inventory)
        io.string(self.game_version)
        nbt(io, self.property_data, NETWORK_LITTLE_ENDIAN)
        io.uint64(self.server_block_state_checksum)
        uuid(io, self.world_template_id)
        io.bool(self.client_side_generation)
        io.bool(self.use_block_network_id_hashes)
        io.bool(self.server_authoritative_sound)
        optional_marshaler(io, self.server_join_information)
        io.string(self.server_id)
        io.string(self.scenario_id)
        io.string(self.world_id)
        io.string(self.owner_id)
