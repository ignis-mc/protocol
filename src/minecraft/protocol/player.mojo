"""Player list entries and player actions (gophertunnel `player.go`)."""

from .block_pos import BlockPos
from .color import RGBA
from .io import (
    IO,
    Marshaler,
    actor_unique_id,
    be_argb,
    block_pos,
    unknown_enum_option,
    uuid,
)
from .skin import Skin
from .uuid import UUID

comptime PLAYER_LIST_ACTION_ADD: UInt8 = 0
"""Player list action: Add."""
comptime PLAYER_LIST_ACTION_REMOVE: UInt8 = 1
"""Player list action: Remove."""

comptime PLAYER_ACTION_START_BREAK: Int32 = 0
"""Player action: Start Break."""
comptime PLAYER_ACTION_ABORT_BREAK: Int32 = 1
"""Player action: Abort Break."""
comptime PLAYER_ACTION_STOP_BREAK: Int32 = 2
"""Player action: Stop Break."""
comptime PLAYER_ACTION_GET_UPDATED_BLOCK: Int32 = 3
"""Player action: Get Updated Block."""
comptime PLAYER_ACTION_DROP_ITEM: Int32 = 4
"""Player action: Drop Item."""
comptime PLAYER_ACTION_START_SLEEPING: Int32 = 5
"""Player action: Start Sleeping."""
comptime PLAYER_ACTION_STOP_SLEEPING: Int32 = 6
"""Player action: Stop Sleeping."""
comptime PLAYER_ACTION_RESPAWN: Int32 = 7
"""Player action: Respawn."""
comptime PLAYER_ACTION_JUMP: Int32 = 8
"""Player action: Jump."""
comptime PLAYER_ACTION_START_SPRINT: Int32 = 9
"""Player action: Start Sprint."""
comptime PLAYER_ACTION_STOP_SPRINT: Int32 = 10
"""Player action: Stop Sprint."""
comptime PLAYER_ACTION_START_SNEAK: Int32 = 11
"""Player action: Start Sneak."""
comptime PLAYER_ACTION_STOP_SNEAK: Int32 = 12
"""Player action: Stop Sneak."""
comptime PLAYER_ACTION_CREATIVE_PLAYER_DESTROY_BLOCK: Int32 = 13
"""Player action: Creative Player Destroy Block."""
comptime PLAYER_ACTION_DIMENSION_CHANGE_DONE: Int32 = 14
"""Player action: Dimension Change Done."""
comptime PLAYER_ACTION_START_GLIDE: Int32 = 15
"""Player action: Start Glide."""
comptime PLAYER_ACTION_STOP_GLIDE: Int32 = 16
"""Player action: Stop Glide."""
comptime PLAYER_ACTION_BUILD_DENIED: Int32 = 17
"""Player action: Build Denied."""
comptime PLAYER_ACTION_CRACK_BREAK: Int32 = 18
"""Player action: Crack Break."""
comptime PLAYER_ACTION_CHANGE_SKIN: Int32 = 19
"""Player action: Change Skin."""
comptime PLAYER_ACTION_SET_ENCHANTMENT_SEED: Int32 = 20
"""Player action: Set Enchantment Seed."""
comptime PLAYER_ACTION_START_SWIMMING: Int32 = 21
"""Player action: Start Swimming."""
comptime PLAYER_ACTION_STOP_SWIMMING: Int32 = 22
"""Player action: Stop Swimming."""
comptime PLAYER_ACTION_START_SPIN_ATTACK: Int32 = 23
"""Player action: Start Spin Attack."""
comptime PLAYER_ACTION_STOP_SPIN_ATTACK: Int32 = 24
"""Player action: Stop Spin Attack."""
comptime PLAYER_ACTION_INTERACT_WITH_BLOCK: Int32 = 25
"""Player action: Interact With Block."""
comptime PLAYER_ACTION_PREDICT_DESTROY_BLOCK: Int32 = 26
"""Player action: Predict Destroy Block."""
comptime PLAYER_ACTION_CONTINUE_DESTROY_BLOCK: Int32 = 27
"""Player action: Continue Destroy Block."""
comptime PLAYER_ACTION_START_ITEM_USE_ON: Int32 = 28
"""Player action: Start Item Use On."""
comptime PLAYER_ACTION_STOP_ITEM_USE_ON: Int32 = 29
"""Player action: Stop Item Use On."""
comptime PLAYER_ACTION_HANDLED_TELEPORT: Int32 = 30
"""Player action: Handled Teleport."""
comptime PLAYER_ACTION_MISSED_SWING: Int32 = 31
"""Player action: Missed Swing."""
comptime PLAYER_ACTION_START_CRAWLING: Int32 = 32
"""Player action: Start Crawling."""
comptime PLAYER_ACTION_STOP_CRAWLING: Int32 = 33
"""Player action: Stop Crawling."""
comptime PLAYER_ACTION_START_FLYING: Int32 = 34
"""Player action: Start Flying."""
comptime PLAYER_ACTION_STOP_FLYING: Int32 = 35
"""Player action: Stop Flying."""
comptime PLAYER_ACTION_RECEIVED_SERVER_DATA: Int32 = 36
"""Player action: Received Server Data."""
comptime PLAYER_ACTION_START_USING_ITEM: Int32 = 37
"""Player action: Start Using Item."""
comptime PLAYER_ACTION_INTERNAL_UPDATE: Int32 = 38
"""Player action: Internal Update."""
comptime PLAYER_ACTION_COUNT: Int32 = 39
"""Player action: Count."""


struct PlayerListEntry(Marshaler):
    """One player in the `PlayerList` packet."""

    var action_type: UInt8
    """The action to perform, one of the `PLAYER_LIST_ACTION_*` values."""
    var uuid: UUID
    """The player's UUID from the Login packet."""
    var entity_unique_id: Int64
    """The player's unique entity ID."""
    var username: String
    """The name shown in the player list."""
    var xuid: String
    """The player's XBOX Live user ID."""
    var play_fab_id: String
    """The server-verified PlayFab ID, if available."""
    var platform_chat_id: String
    """An identifier used for chatting on some platforms."""
    var build_platform: Int32
    """The player's platform from the Login packet."""
    var skin: Skin
    """The player's skin."""
    var teacher: Bool
    """Whether the player is a teacher (Education Edition)."""
    var host: Bool
    """Whether the player is the host of the game."""
    var sub_client: Bool
    """Whether the player is a sub-client of another player."""
    var player_colour: RGBA
    """The player's colour in UI elements such as the locator bar."""

    def __init__(out self):
        """Creates an "add" entry with zero fields."""
        self.action_type = PLAYER_LIST_ACTION_ADD
        self.uuid = UUID()
        self.entity_unique_id = 0
        self.username = String()
        self.xuid = String()
        self.play_fab_id = String()
        self.platform_chat_id = String()
        self.build_platform = 0
        self.skin = Skin()
        self.teacher = False
        self.host = False
        self.sub_client = False
        self.player_colour = RGBA()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry; a removal carries only the UUID."""
        _player_list_action(io, self.action_type)
        uuid(io, self.uuid)
        if self.action_type == PLAYER_LIST_ACTION_REMOVE:
            return
        actor_unique_id(io, self.entity_unique_id)
        io.string(self.username)
        io.string(self.xuid)
        io.string(self.play_fab_id)
        io.string(self.platform_chat_id)
        io.int32(self.build_platform)
        self.skin.marshal(io)
        io.bool(self.teacher)
        io.bool(self.host)
        io.bool(self.sub_client)
        be_argb(io, self.player_colour)


def _player_list_action[I: IO](mut io: I, mut action: UInt8) raises:
    # A varuint32 variant (1 for add, 0 for remove) followed by the legacy
    # action byte, which readers ignore.
    var variant = UInt32(1) if action == PLAYER_LIST_ACTION_ADD else UInt32(0)
    io.varuint32(variant)
    var legacy_action = action
    io.uint8(legacy_action)
    action = PLAYER_LIST_ACTION_REMOVE
    if variant == 1:
        action = PLAYER_LIST_ACTION_ADD
    elif variant != 0:
        unknown_enum_option(Int(variant), "player list entry variant")


struct PlayerMovementSettings(Copyable, Defaultable):
    """The server-authoritative movement settings."""

    var rewind_history_size: Int32
    """The maximum amount of history to keep."""
    var server_authoritative_block_breaking: Bool
    """Whether block breaking goes through `PlayerAuthInput`."""

    def __init__(out self):
        """Creates zero settings."""
        self.rewind_history_size = 0
        self.server_authoritative_block_breaking = False


def player_move_settings[
    I: IO
](mut io: I, mut x: PlayerMovementSettings) raises:
    """Marshals movement settings (gophertunnel `PlayerMoveSettings`)."""
    io.varint32(x.rewind_history_size)
    io.bool(x.server_authoritative_block_breaking)


struct PlayerBlockAction(Marshaler):
    """A block action performed by a player."""

    var action: Int32
    """One of the `PLAYER_ACTION_*` values."""
    var block_pos: BlockPos
    """The block interacted with."""
    var face: Int32
    """The face of the block interacted with."""

    def __init__(out self):
        """Creates a zero action."""
        self.action = 0
        self.block_pos = BlockPos()
        self.face = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the action."""
        io.varint32(self.action)
        block_pos(io, self.block_pos)
        io.varint32(self.face)


struct PlayerArmourDamageEntry(Marshaler):
    """Damage to apply to one armour slot."""

    var armour_slot: Int32
    """The index of the armour slot."""
    var damage: Int16
    """The damage to apply."""

    def __init__(out self):
        """Creates a zero entry."""
        self.armour_slot = 0
        self.damage = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry."""
        io.varint32(self.armour_slot)
        io.int16(self.damage)


struct TeleportData(Marshaler):
    """Extra information about a `MovePlayer` teleport."""

    var teleport_cause: Int32
    """Why the teleport happened (the packet's `TELEPORT_CAUSE_*` values)."""
    var teleport_source_entity_type: Int32
    """The entity type that caused the teleport, such as an ender pearl."""

    def __init__(out self):
        """Creates zero data."""
        self.teleport_cause = 0
        self.teleport_source_entity_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the data."""
        io.int32(self.teleport_cause)
        io.int32(self.teleport_source_entity_type)
