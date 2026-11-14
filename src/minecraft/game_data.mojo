"""Game data for spawning a player (gophertunnel `game_data.go`).

A server fills `GameData` and passes it to `Conn.start_game`, which turns it
into `StartGame`, `ItemRegistry` and the packets around them. A client gets
it filled from the server's `StartGame`, `ItemRegistry` and
`ChunkRadiusUpdated`.
"""

from .nbt.nbt import NBT
from .protocol.block import BlockEntry
from .protocol.block_pos import BlockPos
from .protocol.experiments import ExperimentData
from .protocol.game_rule import GameRule
from .protocol.item import ItemEntry
from .protocol.math import Vec3
from .protocol.packet.start_game import StartGame
from .protocol.player import PlayerMovementSettings
from .protocol.world import DimensionDefinition


struct GameData(Copyable, Defaultable):
    """Data sent to a player in `StartGame` and the packets after it."""

    var world_name: String
    """The name of the world, shown in the pause menu."""
    var world_seed: Int64
    """The seed of the world, used client-side for a few effects only."""
    var difficulty: Int32
    """The difficulty: 0 peaceful, 1 easy, 2 normal, 3 hard."""
    var entity_unique_id: Int64
    """The player's unique entity ID."""
    var entity_runtime_id: UInt64
    """The player's runtime entity ID, used in most player packets."""
    var player_game_mode: Int32
    """The player's game mode; 5 (default) uses `world_game_mode`."""
    var persona_disabled: Bool
    """Whether persona skins are disabled."""
    var custom_skins_disabled: Bool
    """Whether custom skins are disabled."""
    var emote_chat_muted: Bool
    """Whether emote chat messages are hidden."""
    var base_game_version: String
    """The version of the game the world was created with, for example
    `1.21.0`; `*` uses the client's version."""
    var player_position: Vec3
    """The player's spawn position."""
    var pitch: Float32
    """The player's vertical rotation."""
    var yaw: Float32
    """The player's horizontal rotation."""
    var dimension: Int32
    """The dimension: 0 overworld, 1 nether, 2 end."""
    var world_spawn: BlockPos
    """The world spawn, where compasses point."""
    var editor_world_type: Int32
    """The editor world type; 0 for a normal world."""
    var created_in_editor: Bool
    """Whether the world was created in Editor mode."""
    var exported_from_editor: Bool
    """Whether the world was exported from Editor mode."""
    var world_game_mode: Int32
    """The default game mode of the world."""
    var hardcore: Bool
    """Whether the world is in hardcore mode."""
    var xbl_broadcast_mode: Int32
    """How the world is shown to Xbox Live friends."""
    var game_rules: List[GameRule]
    """The game rules the client should know about."""
    var time: Int64
    """The world time in ticks."""
    var day_cycle_lock_time: Int32
    """The time the day cycle is locked to, if it is."""
    var server_block_state_checksum: UInt64
    """A checksum over the block states; not sent by servers."""
    var custom_blocks: List[BlockEntry]
    """Custom blocks, with their properties."""
    var items: List[ItemEntry]
    """The item registry, sent in `ItemRegistry`."""
    var player_movement_settings: PlayerMovementSettings
    """The movement authority settings."""
    var server_authoritative_inventory: Bool
    """Whether the server handles inventory with item stack requests."""
    var experiments: List[ExperimentData]
    """The experiments enabled on the world."""
    var player_permissions: UInt8
    """The player's permission level."""
    var chunk_radius: Int32
    """The view distance. A server may set it to cap what clients request;
    a client gets the radius the server granted."""
    var client_side_generation: Bool
    """Whether the client generates chunks itself."""
    var chat_restriction_level: UInt8
    """Limits on chat: 0 none, 1 dropped, 2 disabled."""
    var disable_player_interactions: Bool
    """Whether the player cannot interact with other players."""
    var use_block_network_id_hashes: Bool
    """Whether block runtime IDs are hashes of the block state."""
    var property_data: NBT
    """Player property data sent in `StartGame`."""
    var dimensions: List[DimensionDefinition]
    """Dimension definitions; if not empty they are sent in `DimensionData`
    before `StartGame`."""

    def __init__(out self):
        """Creates game data with every field zero."""
        self.world_name = String()
        self.world_seed = 0
        self.difficulty = 0
        self.entity_unique_id = 0
        self.entity_runtime_id = 0
        self.player_game_mode = 0
        self.persona_disabled = False
        self.custom_skins_disabled = False
        self.emote_chat_muted = False
        self.base_game_version = String()
        self.player_position = Vec3()
        self.pitch = 0
        self.yaw = 0
        self.dimension = 0
        self.world_spawn = BlockPos()
        self.editor_world_type = 0
        self.created_in_editor = False
        self.exported_from_editor = False
        self.world_game_mode = 0
        self.hardcore = False
        self.xbl_broadcast_mode = 0
        self.game_rules = List[GameRule]()
        self.time = 0
        self.day_cycle_lock_time = 0
        self.server_block_state_checksum = 0
        self.custom_blocks = List[BlockEntry]()
        self.items = List[ItemEntry]()
        self.player_movement_settings = PlayerMovementSettings()
        self.server_authoritative_inventory = False
        self.experiments = List[ExperimentData]()
        self.player_permissions = 0
        self.chunk_radius = 0
        self.client_side_generation = False
        self.chat_restriction_level = 0
        self.disable_player_interactions = False
        self.use_block_network_id_hashes = False
        self.property_data = NBT.empty_compound()
        self.dimensions = List[DimensionDefinition]()

    def set_from_start_game(mut self, pk: StartGame):
        """Fills the fields a client learns from `StartGame` (gophertunnel
        `handleStartGame`); `items`, `chunk_radius` and `dimensions` are kept.
        """
        self.difficulty = pk.difficulty
        self.world_name = pk.world_name.copy()
        self.world_seed = pk.world_seed
        self.entity_unique_id = pk.entity_unique_id
        self.entity_runtime_id = pk.entity_runtime_id
        self.player_game_mode = pk.player_game_mode
        self.base_game_version = pk.base_game_version.copy()
        self.player_position = pk.player_position
        self.pitch = pk.pitch
        self.yaw = pk.yaw
        self.dimension = pk.dimension
        self.world_spawn = pk.world_spawn
        self.editor_world_type = pk.editor_world_type
        self.created_in_editor = pk.created_in_editor
        self.exported_from_editor = pk.exported_from_editor
        self.persona_disabled = pk.persona_disabled
        self.custom_skins_disabled = pk.custom_skins_disabled
        self.emote_chat_muted = pk.emote_chat_muted
        self.game_rules = pk.game_rules.copy()
        self.time = pk.time
        self.day_cycle_lock_time = pk.day_cycle_lock_time
        self.server_block_state_checksum = pk.server_block_state_checksum
        self.custom_blocks = pk.blocks.copy()
        self.player_movement_settings = pk.player_movement_settings.copy()
        self.world_game_mode = pk.world_game_mode
        self.hardcore = pk.hardcore
        self.xbl_broadcast_mode = pk.xbl_broadcast_mode
        self.server_authoritative_inventory = pk.server_authoritative_inventory
        self.player_permissions = pk.player_permissions
        self.chat_restriction_level = pk.chat_restriction_level
        self.disable_player_interactions = pk.disable_player_interactions
        self.client_side_generation = pk.client_side_generation
        self.experiments = pk.experiments.copy()
        self.use_block_network_id_hashes = pk.use_block_network_id_hashes
        self.property_data = pk.property_data.copy()
