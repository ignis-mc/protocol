"""Event data of the Event packet (gophertunnel `protocol/events.go`).

The Go `Event` interface becomes the `Event` struct holding an
`EventVariant` of the 32 concrete event structs. Each conforms to
`EventKind`, which carries its wire type and, if it has one, its ordinal.
`event_type` and `event_ordinal` port the Go `IO.EventType` and
`IO.EventOrdinal` methods; `Event.marshal` marshals only the event body, as
the Go packet calls `pk.Event.Marshal(io)` after those two.
"""

from std.utils import Variant

from .io import marshal_variant
from .io import IO, Marshaler, actor_unique_id, unknown_enum_option

comptime EVENT_TYPE_ACHIEVEMENT_AWARDED: Int32 = 0
"""The `AchievementAwardedEvent` event."""
comptime EVENT_TYPE_ENTITY_INTERACT: Int32 = 1
"""The `EntityInteractEvent` event."""
comptime EVENT_TYPE_PORTAL_BUILT: Int32 = 2
"""The `PortalBuiltEvent` event."""
comptime EVENT_TYPE_PORTAL_USED: Int32 = 3
"""The `PortalUsedEvent` event."""
comptime EVENT_TYPE_MOB_KILLED: Int32 = 4
"""The `MobKilledEvent` event."""
comptime EVENT_TYPE_CAULDRON_USED: Int32 = 5
"""The `CauldronUsedEvent` event."""
comptime EVENT_TYPE_PLAYER_DIED: Int32 = 6
"""The `PlayerDiedEvent` event."""
comptime EVENT_TYPE_BOSS_KILLED: Int32 = 7
"""The `BossKilledEvent` event."""
comptime EVENT_TYPE_AGENT_COMMAND: Int32 = 8
"""The `AgentCommandEvent` event."""
comptime EVENT_TYPE_AGENT_CREATED: Int32 = 9
"""The `AgentCreatedEvent` event."""
comptime EVENT_TYPE_PATTERN_REMOVED: Int32 = 10
"""The `PatternRemovedEvent` event."""
comptime EVENT_TYPE_SLASH_COMMAND_EXECUTED: Int32 = 11
"""The `SlashCommandExecutedEvent` event."""
comptime EVENT_TYPE_FISH_BUCKETED: Int32 = 12
"""The `FishBucketedEvent` event."""
comptime EVENT_TYPE_MOB_BORN: Int32 = 13
"""The `MobBornEvent` event."""
comptime EVENT_TYPE_PET_DIED: Int32 = 14
"""The `PetDiedEvent` event."""
comptime EVENT_TYPE_CAULDRON_INTERACT: Int32 = 15
"""The `CauldronInteractEvent` event."""
comptime EVENT_TYPE_COMPOSTER_INTERACT: Int32 = 16
"""The `ComposterInteractEvent` event."""
comptime EVENT_TYPE_BELL_USED: Int32 = 17
"""The `BellUsedEvent` event."""
comptime EVENT_TYPE_ENTITY_DEFINITION_TRIGGER: Int32 = 18
"""The `EntityDefinitionTriggerEvent` event."""
comptime EVENT_TYPE_RAID_UPDATE: Int32 = 19
"""The `RaidUpdateEvent` event."""
comptime EVENT_TYPE_MOVEMENT_ANOMALY: Int32 = 20
"""The `MovementAnomalyEvent` event."""
comptime EVENT_TYPE_MOVEMENT_CORRECTED: Int32 = 21
"""The `MovementCorrectedEvent` event."""
comptime EVENT_TYPE_EXTRACT_HONEY: Int32 = 22
"""The `ExtractHoneyEvent` event."""
comptime EVENT_TYPE_TARGET_BLOCK_HIT: Int32 = 23
"""The `TargetBlockHitEvent` event."""
comptime EVENT_TYPE_PIGLIN_BARTER: Int32 = 24
"""The `PiglinBarterEvent` event."""
comptime EVENT_TYPE_PLAYER_WAXED_OR_UNWAXED_COPPER: Int32 = 25
"""The `WaxedOrUnwaxedCopperEvent` event."""
comptime EVENT_TYPE_CODE_BUILDER_RUNTIME_ACTION: Int32 = 26
"""The `CodeBuilderRuntimeActionEvent` event."""
comptime EVENT_TYPE_CODE_BUILDER_SCOREBOARD: Int32 = 27
"""The `CodeBuilderScoreboardEvent` event."""
comptime EVENT_TYPE_STRIDER_RIDDEN_IN_LAVA_IN_OVERWORLD: Int32 = 28
"""The `StriderRiddenInLavaInOverworldEvent` event."""
comptime EVENT_TYPE_SNEAK_CLOSE_TO_SCULK_SENSOR: Int32 = 29
"""The `SneakCloseToSculkSensorEvent` event."""
comptime EVENT_TYPE_CAREFUL_RESTORATION: Int32 = 30
"""The `CarefulRestorationEvent` event."""
comptime EVENT_TYPE_ITEM_USED: Int32 = 31
"""The `ItemUsedEvent` event."""

comptime WAX_NOT_OXIDISED: UInt16 = 0xA609
"""Waxing a copper block that is not oxidised."""
comptime WAX_EXPOSED: UInt16 = 0xA809
"""Waxing an exposed copper block."""
comptime WAX_WEATHERED: UInt16 = 0xAA09
"""Waxing a weathered copper block."""
comptime WAX_OXIDISED: UInt16 = 0xAC09
"""Waxing an oxidised copper block."""
comptime UN_WAX_NOT_OXIDISED: UInt16 = 0xAE09
"""Unwaxing a copper block that is not oxidised."""
comptime UN_WAX_EXPOSED: UInt16 = 0xB009
"""Unwaxing an exposed copper block."""
comptime UN_WAX_WEATHERED: UInt16 = 0xB209
"""Unwaxing a weathered copper block."""
comptime UN_WAX_OXIDISED: UInt16 = 0xFA0A
"""Unwaxing an oxidised copper block."""


trait EventKind(Marshaler):
    """A concrete event data type."""

    comptime EVENT_TYPE: Int32
    """The wire type, one of the `EVENT_TYPE_*` values."""
    comptime EVENT_ORDINAL: Optional[UInt32]
    """The ordinal sent after the type; `None` if the event has none."""


struct AchievementAwardedEvent(EventKind):
    """The event data sent for achievements."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_ACHIEVEMENT_AWARDED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(0)
    """The wire ordinal."""
    var achievement_id: UInt8
    """The ID of the achievement."""

    def __init__(out self):
        """Creates the zero value."""
        self.achievement_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.uint8(self.achievement_id)


struct EntityInteractEvent(EventKind):
    """The event data sent for entity interactions."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_ENTITY_INTERACT
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(1)
    """The wire ordinal."""
    var interacted_entity_id: Int64
    """The interacted entity ID."""
    var interaction_type: UInt8
    """The interaction type."""
    var interaction_entity_type: Int32
    """The interaction entity type."""
    var entity_variant: Int32
    """The entity variant."""
    var entity_colour: UInt8
    """The entity colour."""

    def __init__(out self):
        """Creates the zero value."""
        self.interacted_entity_id = 0
        self.interaction_type = 0
        self.interaction_entity_type = 0
        self.entity_variant = 0
        self.entity_colour = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        actor_unique_id(io, self.interacted_entity_id)
        io.uint8(self.interaction_type)
        io.varint32(self.interaction_entity_type)
        io.varint32(self.entity_variant)
        io.uint8(self.entity_colour)


struct PortalBuiltEvent(EventKind):
    """The event data sent when a portal is built."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PORTAL_BUILT
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(2)
    """The wire ordinal."""
    var dimension_id: Int32
    """The dimension ID."""

    def __init__(out self):
        """Creates the zero value."""
        self.dimension_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.dimension_id)


struct PortalUsedEvent(EventKind):
    """The event data sent when a portal is used."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PORTAL_USED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(3)
    """The wire ordinal."""
    var from_dimension_id: Int32
    """The from dimension ID."""
    var to_dimension_id: Int32
    """The to dimension ID."""

    def __init__(out self):
        """Creates the zero value."""
        self.from_dimension_id = 0
        self.to_dimension_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.from_dimension_id)
        io.varint32(self.to_dimension_id)


struct MobKilledEvent(EventKind):
    """The event data sent when a mob is killed."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_MOB_KILLED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(4)
    """The wire ordinal."""
    var killer_entity_unique_id: Int64
    """The killer entity unique ID."""
    var victim_entity_unique_id: Int64
    """The victim entity unique ID."""
    var killer_entity_type: Int32
    """The killer entity type."""
    var entity_damage_cause: Int32
    """The entity damage cause."""
    var villager_trade_tier: Int32
    """The villager trade tier; -1 if not a trading actor."""
    var villager_display_name: String
    """The villager display name; empty if not a trading actor."""

    def __init__(out self):
        """Creates the zero value."""
        self.killer_entity_unique_id = 0
        self.victim_entity_unique_id = 0
        self.killer_entity_type = 0
        self.entity_damage_cause = 0
        self.villager_trade_tier = 0
        self.villager_display_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        actor_unique_id(io, self.killer_entity_unique_id)
        actor_unique_id(io, self.victim_entity_unique_id)
        io.varint32(self.killer_entity_type)
        io.varint32(self.entity_damage_cause)
        io.varint32(self.villager_trade_tier)
        io.string(self.villager_display_name)


struct CauldronUsedEvent(EventKind):
    """The event data sent when a cauldron is used."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_CAULDRON_USED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(5)
    """The wire ordinal."""
    var colour: UInt32
    """The colour."""
    var potion_id: Int16
    """The potion ID."""
    var fill_level: Int16
    """The fill level."""

    def __init__(out self):
        """Creates the zero value."""
        self.colour = 0
        self.potion_id = 0
        self.fill_level = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varuint32(self.colour)
        io.int16(self.potion_id)
        io.int16(self.fill_level)


struct PlayerDiedEvent(EventKind):
    """The event data sent when a player dies."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PLAYER_DIED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(6)
    """The wire ordinal."""
    var attacker_entity_id: Int32
    """The attacker entity ID."""
    var attacker_variant: Int32
    """The attacker variant."""
    var entity_damage_cause: Int32
    """The entity damage cause."""
    var in_raid: Bool
    """The in raid."""

    def __init__(out self):
        """Creates the zero value."""
        self.attacker_entity_id = 0
        self.attacker_variant = 0
        self.entity_damage_cause = 0
        self.in_raid = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.attacker_entity_id)
        io.varint32(self.attacker_variant)
        io.varint32(self.entity_damage_cause)
        io.bool(self.in_raid)


struct BossKilledEvent(EventKind):
    """The event data sent when a boss dies."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_BOSS_KILLED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(7)
    """The wire ordinal."""
    var boss_entity_unique_id: Int64
    """The boss entity unique ID."""
    var player_party_size: Int32
    """The player party size."""
    var interaction_entity_type: Int32
    """The interaction entity type."""

    def __init__(out self):
        """Creates the zero value."""
        self.boss_entity_unique_id = 0
        self.player_party_size = 0
        self.interaction_entity_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        actor_unique_id(io, self.boss_entity_unique_id)
        io.varint32(self.player_party_size)
        io.varint32(self.interaction_entity_type)


struct AgentCommandEvent(EventKind):
    """An event used in Education Edition."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_AGENT_COMMAND
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""
    var agent_result: Int32
    """The agent result."""
    var data_value: Int32
    """The data value."""
    var command: String
    """The command."""
    var data_key: String
    """The data key."""
    var output: String
    """The output."""

    def __init__(out self):
        """Creates the zero value."""
        self.agent_result = 0
        self.data_value = 0
        self.command = String()
        self.data_key = String()
        self.output = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.agent_result)
        io.varint32(self.data_value)
        io.string(self.command)
        io.string(self.data_key)
        io.string(self.output)


struct AgentCreatedEvent(EventKind):
    """The event data sent when an agent is created."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_AGENT_CREATED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct PatternRemovedEvent(EventKind):
    """The event data sent when a pattern is removed."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PATTERN_REMOVED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct SlashCommandExecutedEvent(EventKind):
    """The event data sent when a slash command is executed."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_SLASH_COMMAND_EXECUTED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(8)
    """The wire ordinal."""
    var success_count: Int32
    """The success count."""
    var message_count: Int32
    """The message count: it indicates the amount of OutputMessages present."""
    var command_name: String
    """The command name."""
    var output_messages: String
    """The output messages; is a list of messages joint with ;."""

    def __init__(out self):
        """Creates the zero value."""
        self.success_count = 0
        self.message_count = 0
        self.command_name = String()
        self.output_messages = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.success_count)
        io.varint32(self.message_count)
        io.string(self.command_name)
        io.string(self.output_messages)


struct FishBucketedEvent(EventKind):
    """The event data sent when a fish is bucketed."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_FISH_BUCKETED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct MobBornEvent(EventKind):
    """The event data sent when a mob is born."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_MOB_BORN
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(9)
    """The wire ordinal."""
    var entity_type: Int32
    """The entity type."""
    var variant: Int32
    """The variant."""
    var colour: UInt8
    """The colour."""

    def __init__(out self):
        """Creates the zero value."""
        self.entity_type = 0
        self.variant = 0
        self.colour = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.entity_type)
        io.varint32(self.variant)
        io.uint8(self.colour)


struct PetDiedEvent(EventKind):
    """The event data sent when a pet dies."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PET_DIED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct CauldronInteractEvent(EventKind):
    """The event data sent when a cauldron is interacted with."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_CAULDRON_INTERACT
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(10)
    """The wire ordinal."""
    var block_interaction_type: UInt8
    """The block interaction type."""
    var item_id: Int16
    """The item ID."""

    def __init__(out self):
        """Creates the zero value."""
        self.block_interaction_type = 0
        self.item_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.uint8(self.block_interaction_type)
        io.int16(self.item_id)


struct ComposterInteractEvent(EventKind):
    """The event data sent when a composter is interacted with."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_COMPOSTER_INTERACT
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(11)
    """The wire ordinal."""
    var block_interaction_type: UInt8
    """The block interaction type."""
    var item_id: Int16
    """The item ID."""

    def __init__(out self):
        """Creates the zero value."""
        self.block_interaction_type = 0
        self.item_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.uint8(self.block_interaction_type)
        io.int16(self.item_id)


struct BellUsedEvent(EventKind):
    """The event data sent when a bell is used."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_BELL_USED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(12)
    """The wire ordinal."""
    var item_id: Int16
    """The item ID."""

    def __init__(out self):
        """Creates the zero value."""
        self.item_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.int16(self.item_id)


struct EntityDefinitionTriggerEvent(EventKind):
    """An event used for an unknown purpose."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_ENTITY_DEFINITION_TRIGGER
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(13)
    """The wire ordinal."""
    var event_name: String
    """The event name."""

    def __init__(out self):
        """Creates the zero value."""
        self.event_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.string(self.event_name)


struct RaidUpdateEvent(EventKind):
    """An event used to update a raids progress client side."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_RAID_UPDATE
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(14)
    """The wire ordinal."""
    var current_raid_wave: Int32
    """The current raid wave."""
    var total_raid_waves: Int32
    """The total raid waves."""
    var won_raid: Bool
    """The won raid."""

    def __init__(out self):
        """Creates the zero value."""
        self.current_raid_wave = 0
        self.total_raid_waves = 0
        self.won_raid = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.current_raid_wave)
        io.varint32(self.total_raid_waves)
        io.bool(self.won_raid)


struct MovementAnomalyEvent(EventKind):
    """An event used to detect movement anomalies."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_MOVEMENT_ANOMALY
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct MovementCorrectedEvent(EventKind):
    """An event used to correct movement anomalies."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_MOVEMENT_CORRECTED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct ExtractHoneyEvent(EventKind):
    """An event used to extract honey from a hive."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_EXTRACT_HONEY
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = None
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct TargetBlockHitEvent(EventKind):
    """An event used when a target block is hit by an arrow."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_TARGET_BLOCK_HIT
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(15)
    """The wire ordinal."""
    var redstone_level: Int32
    """The redstone level."""

    def __init__(out self):
        """Creates the zero value."""
        self.redstone_level = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.redstone_level)


struct PiglinBarterEvent(EventKind):
    """Called when a player drops gold ingots to a piglin to initiate a trade
    for an item.
    """

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PIGLIN_BARTER
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(16)
    """The wire ordinal."""
    var item_id: Int32
    """The item ID."""
    var was_targeting_bartering_player: Bool
    """The was targeting bartering player."""

    def __init__(out self):
        """Creates the zero value."""
        self.item_id = 0
        self.was_targeting_bartering_player = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.item_id)
        io.bool(self.was_targeting_bartering_player)


struct WaxedOrUnwaxedCopperEvent(EventKind):
    """An event sent by the server when a copper block is waxed or unwaxed."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_PLAYER_WAXED_OR_UNWAXED_COPPER
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(17)
    """The wire ordinal."""
    var copper_block_id: Int32
    """The copper block ID."""

    def __init__(out self):
        """Creates the zero value."""
        self.copper_block_id = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.varint32(self.copper_block_id)


struct CodeBuilderRuntimeActionEvent(EventKind):
    """An event sent by the server when a code builder runtime action is
    performed.
    """

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_CODE_BUILDER_RUNTIME_ACTION
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(18)
    """The wire ordinal."""
    var action: String
    """The action."""

    def __init__(out self):
        """Creates the zero value."""
        self.action = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.string(self.action)


struct CodeBuilderScoreboardEvent(EventKind):
    """An event sent by the server when a code builder scoreboard is updated."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_CODE_BUILDER_SCOREBOARD
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(19)
    """The wire ordinal."""
    var objective_name: String
    """The objective name."""
    var score: Int32
    """The score."""

    def __init__(out self):
        """Creates the zero value."""
        self.objective_name = String()
        self.score = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.string(self.objective_name)
        io.varint32(self.score)


struct StriderRiddenInLavaInOverworldEvent(EventKind):
    """An event sent by the server when a strider is ridden in lava in the
    overworld.
    """

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_STRIDER_RIDDEN_IN_LAVA_IN_OVERWORLD
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(21)
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct SneakCloseToSculkSensorEvent(EventKind):
    """An event sent by the server when a player sneaks close to a sculk sensor.
    """

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_SNEAK_CLOSE_TO_SCULK_SENSOR
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(21)
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct CarefulRestorationEvent(EventKind):
    """An event sent by the server when a player performs a careful restoration.
    """

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_CAREFUL_RESTORATION
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(21)
    """The wire ordinal."""

    def __init__(out self):
        """Creates the zero value."""
        pass

    def marshal[I: IO](mut self, mut io: I):
        """Marshals nothing."""
        pass


struct ItemUsedEvent(EventKind):
    """When a player right clicks an item."""

    comptime EVENT_TYPE: Int32 = EVENT_TYPE_ITEM_USED
    """The wire type."""
    comptime EVENT_ORDINAL: Optional[UInt32] = UInt32(20)
    """The wire ordinal."""
    var item_id: Int16
    """The item ID."""
    var item_aux: Int32
    """The item aux."""
    var use_method: Int32
    """The use method."""
    var use_count: Int32
    """The use count."""

    def __init__(out self):
        """Creates the zero value."""
        self.item_id = 0
        self.item_aux = 0
        self.use_method = 0
        self.use_count = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the event body."""
        io.int16(self.item_id)
        io.int32(self.item_aux)
        io.int32(self.use_method)
        io.int32(self.use_count)


comptime EventVariant = Variant[
    AchievementAwardedEvent,
    EntityInteractEvent,
    PortalBuiltEvent,
    PortalUsedEvent,
    MobKilledEvent,
    CauldronUsedEvent,
    PlayerDiedEvent,
    BossKilledEvent,
    AgentCommandEvent,
    AgentCreatedEvent,
    PatternRemovedEvent,
    SlashCommandExecutedEvent,
    FishBucketedEvent,
    MobBornEvent,
    PetDiedEvent,
    CauldronInteractEvent,
    ComposterInteractEvent,
    BellUsedEvent,
    EntityDefinitionTriggerEvent,
    RaidUpdateEvent,
    MovementAnomalyEvent,
    MovementCorrectedEvent,
    ExtractHoneyEvent,
    TargetBlockHitEvent,
    PiglinBarterEvent,
    WaxedOrUnwaxedCopperEvent,
    CodeBuilderRuntimeActionEvent,
    CodeBuilderScoreboardEvent,
    StriderRiddenInLavaInOverworldEvent,
    SneakCloseToSculkSensorEvent,
    CarefulRestorationEvent,
    ItemUsedEvent,
]
"""Every concrete event, in `EVENT_TYPE_*` order."""


def _event_type[*Ts: EventKind](x: Variant[*Ts]) -> Int32:
    comptime for i in range(len(Ts)):
        if x.isa[Ts[i]]():
            return Ts[i].EVENT_TYPE
    return 0


def _event_ordinal[*Ts: EventKind](x: Variant[*Ts]) -> Optional[UInt32]:
    comptime for i in range(len(Ts)):
        if x.isa[Ts[i]]():
            return materialize[Ts[i].EVENT_ORDINAL]()
    return None


def _set_event_type[*Ts: EventKind](mut x: Variant[*Ts], t: Int32) raises:
    comptime for i in range(len(Ts)):
        if t == Ts[i].EVENT_TYPE:
            x = Variant[*Ts](Ts[i]())
            return
    unknown_enum_option(Int(t), "event packet event type")


struct Event(Marshaler):
    """The data of an Event packet (Go interface `Event`)."""

    var value: EventVariant
    """The concrete event."""

    def __init__(out self):
        """Creates an `AchievementAwardedEvent`."""
        self.value = AchievementAwardedEvent()

    @implicit
    def __init__(out self, var value: EventVariant):
        """Wraps a concrete event."""
        self.value = value^

    def event_type(self) -> Int32:
        """Gets the wire type of the held event."""
        return _event_type(self.value)

    def event_ordinal(self) -> Optional[UInt32]:
        """Gets the wire ordinal of the held event."""
        return _event_ordinal(self.value)

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the body of the held event."""
        marshal_variant(io, self.value)


def event_type[I: IO](mut io: I, mut x: Event) raises:
    """Marshals the varint32 event type (gophertunnel `IO.EventType`).

    Reading replaces `x` with a zero event of that type.
    """
    var t = x.event_type()
    io.varint32(t)
    if io.reads():
        _set_event_type(x.value, t)


def event_ordinal[I: IO](mut io: I, mut x: Event) raises:
    """Marshals the varuint32 event ordinal (gophertunnel `IO.EventOrdinal`).

    The ordinal follows from the event already set by `event_type`; a read
    ordinal is not checked, as in Go.
    """
    var ordinal = x.event_ordinal()
    if ordinal is None:
        unknown_enum_option(Int(x.event_type()), "event packet event ordinal")
        return
    var o = ordinal.value()
    io.varuint32(o)
