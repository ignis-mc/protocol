"""Entity metadata (gophertunnel `protocol/entity_metadata.go`).

Go keeps metadata in a `map[uint32]any`. Here `EntityMetadata` is a `List` of
`EntityMetadataEntry` key/value pairs, kept in the order they were read or
set; `EntityDataValue` is a `Variant` of the nine wire value types.
`entity_metadata` ports the Go `IO.EntityMetadata` method. Like the Go
writer it encodes the entries sorted by key (NPC dialogue breaks otherwise),
and if a key occurs more than once only the last entry is written, which is
what decoding into a Go map would have kept.
"""

from std.utils import Variant

from ..nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN, nbt
from .block_pos import BlockPos
from .io import (
    IO,
    Marshaler,
    block_pos,
    invalid_value,
    unknown_enum_option,
    vec3,
)
from .math import Vec3

comptime ENTITY_DATA_KEY_FLAGS: UInt32 = 0
"""Go `EntityDataKeyFlags`."""
comptime ENTITY_DATA_KEY_STRUCTURAL_INTEGRITY: UInt32 = 1
"""Go `EntityDataKeyStructuralIntegrity`."""
comptime ENTITY_DATA_KEY_VARIANT: UInt32 = 2
"""Go `EntityDataKeyVariant`."""
comptime ENTITY_DATA_KEY_COLOR_INDEX: UInt32 = 3
"""Go `EntityDataKeyColorIndex`."""
comptime ENTITY_DATA_KEY_NAME: UInt32 = 4
"""Go `EntityDataKeyName`."""
comptime ENTITY_DATA_KEY_OWNER: UInt32 = 5
"""Go `EntityDataKeyOwner`."""
comptime ENTITY_DATA_KEY_TARGET: UInt32 = 6
"""Go `EntityDataKeyTarget`."""
comptime ENTITY_DATA_KEY_AIR_SUPPLY: UInt32 = 7
"""Go `EntityDataKeyAirSupply`."""
comptime ENTITY_DATA_KEY_EFFECT_COLOR: UInt32 = 8
"""Go `EntityDataKeyEffectColor`."""
comptime ENTITY_DATA_KEY_EFFECT_AMBIENCE: UInt32 = 9
"""Go `EntityDataKeyEffectAmbience`."""
comptime ENTITY_DATA_KEY_JUMP_DURATION: UInt32 = 10
"""Go `EntityDataKeyJumpDuration`."""
comptime ENTITY_DATA_KEY_HURT: UInt32 = 11
"""Go `EntityDataKeyHurt`."""
comptime ENTITY_DATA_KEY_HURT_DIRECTION: UInt32 = 12
"""Go `EntityDataKeyHurtDirection`."""
comptime ENTITY_DATA_KEY_ROW_TIME_LEFT: UInt32 = 13
"""Go `EntityDataKeyRowTimeLeft`."""
comptime ENTITY_DATA_KEY_ROW_TIME_RIGHT: UInt32 = 14
"""Go `EntityDataKeyRowTimeRight`."""
comptime ENTITY_DATA_KEY_VALUE: UInt32 = 15
"""Go `EntityDataKeyValue`."""
comptime ENTITY_DATA_KEY_DISPLAY_BLOCK_STATE: UInt32 = 16
"""Go `EntityDataKeyDisplayBlockState`."""
comptime ENTITY_DATA_KEY_DISPLAY_OFFSET: UInt32 = 17
"""Go `EntityDataKeyDisplayOffset`."""
comptime ENTITY_DATA_KEY_CUSTOM_DISPLAY: UInt32 = 18
"""Go `EntityDataKeyCustomDisplay`."""
comptime ENTITY_DATA_KEY_SWELL: UInt32 = 19
"""Go `EntityDataKeySwell`."""
comptime ENTITY_DATA_KEY_OLD_SWELL: UInt32 = 20
"""Go `EntityDataKeyOldSwell`."""
comptime ENTITY_DATA_KEY_SWELL_DIRECTION: UInt32 = 21
"""Go `EntityDataKeySwellDirection`."""
comptime ENTITY_DATA_KEY_CHARGE_AMOUNT: UInt32 = 22
"""Go `EntityDataKeyChargeAmount`."""
comptime ENTITY_DATA_KEY_CARRY_BLOCK_RUNTIME_ID: UInt32 = 23
"""Go `EntityDataKeyCarryBlockRuntimeID`."""
comptime ENTITY_DATA_KEY_CLIENT_EVENT: UInt32 = 24
"""Go `EntityDataKeyClientEvent`."""
comptime ENTITY_DATA_KEY_USING_ITEM: UInt32 = 25
"""Go `EntityDataKeyUsingItem`."""
comptime ENTITY_DATA_KEY_PLAYER_FLAGS: UInt32 = 26
"""Go `EntityDataKeyPlayerFlags`."""
comptime ENTITY_DATA_KEY_PLAYER_INDEX: UInt32 = 27
"""Go `EntityDataKeyPlayerIndex`."""
comptime ENTITY_DATA_KEY_BED_POSITION: UInt32 = 28
"""Go `EntityDataKeyBedPosition`."""
comptime ENTITY_DATA_KEY_POWER_X: UInt32 = 29
"""Go `EntityDataKeyPowerX`."""
comptime ENTITY_DATA_KEY_POWER_Y: UInt32 = 30
"""Go `EntityDataKeyPowerY`."""
comptime ENTITY_DATA_KEY_POWER_Z: UInt32 = 31
"""Go `EntityDataKeyPowerZ`."""
comptime ENTITY_DATA_KEY_AUX_POWER: UInt32 = 32
"""Go `EntityDataKeyAuxPower`."""
comptime ENTITY_DATA_KEY_FISH_X: UInt32 = 33
"""Go `EntityDataKeyFishX`."""
comptime ENTITY_DATA_KEY_FISH_Z: UInt32 = 34
"""Go `EntityDataKeyFishZ`."""
comptime ENTITY_DATA_KEY_FISH_ANGLE: UInt32 = 35
"""Go `EntityDataKeyFishAngle`."""
comptime ENTITY_DATA_KEY_AUX_VALUE_DATA: UInt32 = 36
"""Go `EntityDataKeyAuxValueData`."""
comptime ENTITY_DATA_KEY_LEASH_HOLDER: UInt32 = 37
"""Go `EntityDataKeyLeashHolder`."""
comptime ENTITY_DATA_KEY_SCALE: UInt32 = 38
"""Go `EntityDataKeyScale`."""
comptime ENTITY_DATA_KEY_HAS_NPC: UInt32 = 39
"""Go `EntityDataKeyHasNPC`."""
comptime ENTITY_DATA_KEY_NPC_DATA: UInt32 = 40
"""Go `EntityDataKeyNPCData`."""
comptime ENTITY_DATA_KEY_ACTIONS: UInt32 = 41
"""Go `EntityDataKeyActions`."""
comptime ENTITY_DATA_KEY_AIR_SUPPLY_MAX: UInt32 = 42
"""Go `EntityDataKeyAirSupplyMax`."""
comptime ENTITY_DATA_KEY_MARK_VARIANT: UInt32 = 43
"""Go `EntityDataKeyMarkVariant`."""
comptime ENTITY_DATA_KEY_CONTAINER_TYPE: UInt32 = 44
"""Go `EntityDataKeyContainerType`."""
comptime ENTITY_DATA_KEY_CONTAINER_SIZE: UInt32 = 45
"""Go `EntityDataKeyContainerSize`."""
comptime ENTITY_DATA_KEY_CONTAINER_STRENGTH_MODIFIER: UInt32 = 46
"""Go `EntityDataKeyContainerStrengthModifier`."""
comptime ENTITY_DATA_KEY_BLOCK_TARGET: UInt32 = 47
"""Go `EntityDataKeyBlockTarget`."""
comptime ENTITY_DATA_KEY_INVULNERABLE_TICKS: UInt32 = 48
"""Go `EntityDataKeyInvulnerableTicks`."""
comptime ENTITY_DATA_KEY_TARGET_A: UInt32 = 49
"""Go `EntityDataKeyTargetA`."""
comptime ENTITY_DATA_KEY_TARGET_B: UInt32 = 50
"""Go `EntityDataKeyTargetB`."""
comptime ENTITY_DATA_KEY_TARGET_C: UInt32 = 51
"""Go `EntityDataKeyTargetC`."""
comptime ENTITY_DATA_KEY_AERIAL_ATTACK: UInt32 = 52
"""Go `EntityDataKeyAerialAttack`."""
comptime ENTITY_DATA_KEY_WIDTH: UInt32 = 53
"""Go `EntityDataKeyWidth`."""
comptime ENTITY_DATA_KEY_HEIGHT: UInt32 = 54
"""Go `EntityDataKeyHeight`."""
comptime ENTITY_DATA_KEY_FUSE_TIME: UInt32 = 55
"""Go `EntityDataKeyFuseTime`."""
comptime ENTITY_DATA_KEY_SEAT_OFFSET: UInt32 = 56
"""Go `EntityDataKeySeatOffset`."""
comptime ENTITY_DATA_KEY_SEAT_LOCK_PASSENGER_ROTATION: UInt32 = 57
"""Go `EntityDataKeySeatLockPassengerRotation`."""
comptime ENTITY_DATA_KEY_SEAT_LOCK_PASSENGER_ROTATION_DEGREES: UInt32 = 58
"""Go `EntityDataKeySeatLockPassengerRotationDegrees`."""
comptime ENTITY_DATA_KEY_SEAT_ROTATION_OFFSET: UInt32 = 59
"""Go `EntityDataKeySeatRotationOffset`."""
comptime ENTITY_DATA_KEY_SEAT_ROTATION_OFFSET_DEGREES: UInt32 = 60
"""Go `EntityDataKeySeatRotationOffsetDegrees`."""
comptime ENTITY_DATA_KEY_DATA_RADIUS: UInt32 = 61
"""Go `EntityDataKeyDataRadius`."""
comptime ENTITY_DATA_KEY_DATA_WAITING: UInt32 = 62
"""Go `EntityDataKeyDataWaiting`."""
comptime ENTITY_DATA_KEY_DATA_PARTICLE: UInt32 = 63
"""Go `EntityDataKeyDataParticle`."""
comptime ENTITY_DATA_KEY_PEEK_ID: UInt32 = 64
"""Go `EntityDataKeyPeekID`."""
comptime ENTITY_DATA_KEY_ATTACH_FACE: UInt32 = 65
"""Go `EntityDataKeyAttachFace`."""
comptime ENTITY_DATA_KEY_ATTACHED: UInt32 = 66
"""Go `EntityDataKeyAttached`."""
comptime ENTITY_DATA_KEY_ATTACHED_POSITION: UInt32 = 67
"""Go `EntityDataKeyAttachedPosition`."""
comptime ENTITY_DATA_KEY_TRADE_TARGET: UInt32 = 68
"""Go `EntityDataKeyTradeTarget`."""
comptime ENTITY_DATA_KEY_CAREER: UInt32 = 69
"""Go `EntityDataKeyCareer`."""
comptime ENTITY_DATA_KEY_HAS_COMMAND_BLOCK: UInt32 = 70
"""Go `EntityDataKeyHasCommandBlock`."""
comptime ENTITY_DATA_KEY_COMMAND_NAME: UInt32 = 71
"""Go `EntityDataKeyCommandName`."""
comptime ENTITY_DATA_KEY_LAST_COMMAND_OUTPUT: UInt32 = 72
"""Go `EntityDataKeyLastCommandOutput`."""
comptime ENTITY_DATA_KEY_TRACK_COMMAND_OUTPUT: UInt32 = 73
"""Go `EntityDataKeyTrackCommandOutput`."""
comptime ENTITY_DATA_KEY_CONTROLLING_SEAT_INDEX: UInt32 = 74
"""Go `EntityDataKeyControllingSeatIndex`."""
comptime ENTITY_DATA_KEY_STRENGTH: UInt32 = 75
"""Go `EntityDataKeyStrength`."""
comptime ENTITY_DATA_KEY_STRENGTH_MAX: UInt32 = 76
"""Go `EntityDataKeyStrengthMax`."""
comptime ENTITY_DATA_KEY_DATA_SPELL_CASTING_COLOR: UInt32 = 77
"""Go `EntityDataKeyDataSpellCastingColor`."""
comptime ENTITY_DATA_KEY_DATA_LIFETIME_TICKS: UInt32 = 78
"""Go `EntityDataKeyDataLifetimeTicks`."""
comptime ENTITY_DATA_KEY_POSE_INDEX: UInt32 = 79
"""Go `EntityDataKeyPoseIndex`."""
comptime ENTITY_DATA_KEY_DATA_TICK_OFFSET: UInt32 = 80
"""Go `EntityDataKeyDataTickOffset`."""
comptime ENTITY_DATA_KEY_ALWAYS_SHOW_NAME_TAG: UInt32 = 81
"""Go `EntityDataKeyAlwaysShowNameTag`."""
comptime ENTITY_DATA_KEY_COLOR_TWO_INDEX: UInt32 = 82
"""Go `EntityDataKeyColorTwoIndex`."""
comptime ENTITY_DATA_KEY_NAME_AUTHOR: UInt32 = 83
"""Go `EntityDataKeyNameAuthor`."""
comptime ENTITY_DATA_KEY_SCORE: UInt32 = 84
"""Go `EntityDataKeyScore`."""
comptime ENTITY_DATA_KEY_BALLOON_ANCHOR: UInt32 = 85
"""Go `EntityDataKeyBalloonAnchor`."""
comptime ENTITY_DATA_KEY_PUFFED_STATE: UInt32 = 86
"""Go `EntityDataKeyPuffedState`."""
comptime ENTITY_DATA_KEY_BUBBLE_TIME: UInt32 = 87
"""Go `EntityDataKeyBubbleTime`."""
comptime ENTITY_DATA_KEY_AGENT: UInt32 = 88
"""Go `EntityDataKeyAgent`."""
comptime ENTITY_DATA_KEY_SITTING_AMOUNT: UInt32 = 89
"""Go `EntityDataKeySittingAmount`."""
comptime ENTITY_DATA_KEY_SITTING_AMOUNT_PREVIOUS: UInt32 = 90
"""Go `EntityDataKeySittingAmountPrevious`."""
comptime ENTITY_DATA_KEY_EATING_COUNTER: UInt32 = 91
"""Go `EntityDataKeyEatingCounter`."""
comptime ENTITY_DATA_KEY_FLAGS_TWO: UInt32 = 92
"""Go `EntityDataKeyFlagsTwo`."""
comptime ENTITY_DATA_KEY_LAYING_AMOUNT: UInt32 = 93
"""Go `EntityDataKeyLayingAmount`."""
comptime ENTITY_DATA_KEY_LAYING_AMOUNT_PREVIOUS: UInt32 = 94
"""Go `EntityDataKeyLayingAmountPrevious`."""
comptime ENTITY_DATA_KEY_DATA_DURATION: UInt32 = 95
"""Go `EntityDataKeyDataDuration`."""
comptime ENTITY_DATA_KEY_DATA_SPAWN_TIME: UInt32 = 96
"""Go `EntityDataKeyDataSpawnTime`."""
comptime ENTITY_DATA_KEY_DATA_CHANGE_RATE: UInt32 = 97
"""Go `EntityDataKeyDataChangeRate`."""
comptime ENTITY_DATA_KEY_DATA_CHANGE_ON_PICKUP: UInt32 = 98
"""Go `EntityDataKeyDataChangeOnPickup`."""
comptime ENTITY_DATA_KEY_DATA_PICKUP_COUNT: UInt32 = 99
"""Go `EntityDataKeyDataPickupCount`."""
comptime ENTITY_DATA_KEY_INTERACT_TEXT: UInt32 = 100
"""Go `EntityDataKeyInteractText`."""
comptime ENTITY_DATA_KEY_TRADE_TIER: UInt32 = 101
"""Go `EntityDataKeyTradeTier`."""
comptime ENTITY_DATA_KEY_MAX_TRADE_TIER: UInt32 = 102
"""Go `EntityDataKeyMaxTradeTier`."""
comptime ENTITY_DATA_KEY_TRADE_EXPERIENCE: UInt32 = 103
"""Go `EntityDataKeyTradeExperience`."""
comptime ENTITY_DATA_KEY_SKIN_ID: UInt32 = 104
"""Go `EntityDataKeySkinID`."""
comptime ENTITY_DATA_KEY_SPAWNING_FRAMES: UInt32 = 105
"""Go `EntityDataKeySpawningFrames`."""
comptime ENTITY_DATA_KEY_COMMAND_BLOCK_TICK_DELAY: UInt32 = 106
"""Go `EntityDataKeyCommandBlockTickDelay`."""
comptime ENTITY_DATA_KEY_COMMAND_BLOCK_EXECUTE_ON_FIRST_TICK: UInt32 = 107
"""Go `EntityDataKeyCommandBlockExecuteOnFirstTick`."""
comptime ENTITY_DATA_KEY_AMBIENT_SOUND_INTERVAL: UInt32 = 108
"""Go `EntityDataKeyAmbientSoundInterval`."""
comptime ENTITY_DATA_KEY_AMBIENT_SOUND_INTERVAL_RANGE: UInt32 = 109
"""Go `EntityDataKeyAmbientSoundIntervalRange`."""
comptime ENTITY_DATA_KEY_AMBIENT_SOUND_EVENT_NAME: UInt32 = 110
"""Go `EntityDataKeyAmbientSoundEventName`."""
comptime ENTITY_DATA_KEY_FALL_DAMAGE_MULTIPLIER: UInt32 = 111
"""Go `EntityDataKeyFallDamageMultiplier`."""
comptime ENTITY_DATA_KEY_NAME_RAW_TEXT: UInt32 = 112
"""Go `EntityDataKeyNameRawText`."""
comptime ENTITY_DATA_KEY_CAN_RIDE_TARGET: UInt32 = 113
"""Go `EntityDataKeyCanRideTarget`."""
comptime ENTITY_DATA_KEY_LOW_TIER_CURED_TRADE_DISCOUNT: UInt32 = 114
"""Go `EntityDataKeyLowTierCuredTradeDiscount`."""
comptime ENTITY_DATA_KEY_HIGH_TIER_CURED_TRADE_DISCOUNT: UInt32 = 115
"""Go `EntityDataKeyHighTierCuredTradeDiscount`."""
comptime ENTITY_DATA_KEY_NEARBY_CURED_TRADE_DISCOUNT: UInt32 = 116
"""Go `EntityDataKeyNearbyCuredTradeDiscount`."""
comptime ENTITY_DATA_KEY_NEARBY_CURED_DISCOUNT_TIME_STAMP: UInt32 = 117
"""Go `EntityDataKeyNearbyCuredDiscountTimeStamp`."""
comptime ENTITY_DATA_KEY_HIT_BOX: UInt32 = 118
"""Go `EntityDataKeyHitBox`."""
comptime ENTITY_DATA_KEY_IS_BUOYANT: UInt32 = 119
"""Go `EntityDataKeyIsBuoyant`."""
comptime ENTITY_DATA_KEY_FREEZING_EFFECT_STRENGTH: UInt32 = 120
"""Go `EntityDataKeyFreezingEffectStrength`."""
comptime ENTITY_DATA_KEY_BUOYANCY_DATA: UInt32 = 121
"""Go `EntityDataKeyBuoyancyData`."""
comptime ENTITY_DATA_KEY_GOAT_HORN_COUNT: UInt32 = 122
"""Go `EntityDataKeyGoatHornCount`."""
comptime ENTITY_DATA_KEY_BASE_RUNTIME_ID: UInt32 = 123
"""Go `EntityDataKeyBaseRuntimeID`."""
comptime ENTITY_DATA_KEY_MOVEMENT_SOUND_DISTANCE_OFFSET: UInt32 = 124
"""Go `EntityDataKeyMovementSoundDistanceOffset`."""
comptime ENTITY_DATA_KEY_HEARTBEAT_INTERVAL_TICKS: UInt32 = 125
"""Go `EntityDataKeyHeartbeatIntervalTicks`."""
comptime ENTITY_DATA_KEY_HEARTBEAT_SOUND_EVENT: UInt32 = 126
"""Go `EntityDataKeyHeartbeatSoundEvent`."""
comptime ENTITY_DATA_KEY_PLAYER_LAST_DEATH_POSITION: UInt32 = 127
"""Go `EntityDataKeyPlayerLastDeathPosition`."""
comptime ENTITY_DATA_KEY_PLAYER_LAST_DEATH_DIMENSION: UInt32 = 128
"""Go `EntityDataKeyPlayerLastDeathDimension`."""
comptime ENTITY_DATA_KEY_PLAYER_HAS_DIED: UInt32 = 129
"""Go `EntityDataKeyPlayerHasDied`."""
comptime ENTITY_DATA_KEY_COLLISION_BOX: UInt32 = 130
"""Go `EntityDataKeyCollisionBox`."""
comptime ENTITY_DATA_KEY_VISIBLE_MOB_EFFECTS: UInt32 = 131
"""Go `EntityDataKeyVisibleMobEffects`."""
comptime ENTITY_DATA_KEY_FILTERED_NAME: UInt32 = 132
"""Go `EntityDataKeyFilteredName`."""
comptime ENTITY_DATA_KEY_ENTER_BED_POSITION: UInt32 = 133
"""Go `EntityDataKeyEnterBedPosition`."""
comptime ENTITY_DATA_KEY_SEAT_THIRD_PERSON_CAMERA_RADIUS: UInt32 = 134
"""Go `EntityDataKeySeatThirdPersonCameraRadius`."""
comptime ENTITY_DATA_KEY_SEAT_CAMERA_RELAX_DISTANCE_SMOOTHING: UInt32 = 135
"""Go `EntityDataKeySeatCameraRelaxDistanceSmoothing`."""
comptime ENTITY_DATA_KEY_AIM_ASSIST_PRIORITY_PRESET_ID: UInt32 = 136
"""Go `EntityDataKeyAimAssistPriorityPresetID`."""
comptime ENTITY_DATA_KEY_AIM_ASSIST_PRIORITY_CATEGORY_ID: UInt32 = 137
"""Go `EntityDataKeyAimAssistPriorityCategoryID`."""
comptime ENTITY_DATA_KEY_AIM_ASSIST_PRIORITY_ACTOR_ID: UInt32 = 138
"""Go `EntityDataKeyAimAssistPriorityActorID`."""
comptime ENTITY_DATA_KEY_ARROW_SHOOTER_ID: UInt32 = 139
"""Go `EntityDataKeyArrowShooterID`."""
comptime ENTITY_DATA_KEY_FIREWORK_DIRECTION: UInt32 = 140
"""Go `EntityDataKeyFireworkDirection`."""
comptime ENTITY_DATA_KEY_FIREWORK_SHOOTER_ID: UInt32 = 141
"""Go `EntityDataKeyFireworkShooterID`."""
comptime ENTITY_DATA_KEY_RESERVED139: UInt32 = 142
"""Go `EntityDataKeyReserved139`."""
comptime ENTITY_DATA_KEY_NAMEPLATE_RENDER_DISTANCE_MAX: UInt32 = 143
"""Go `EntityDataKeyNameplateRenderDistanceMax`."""

comptime ENTITY_DATA_KEY_DISPLAY_FIREWORK: UInt32 = (
    ENTITY_DATA_KEY_DISPLAY_BLOCK_STATE
)
"""Go `EntityDataKeyDisplayFirework`, an actor-specific meaning of
`EntityDataKeyDisplayBlockState`.
"""
comptime ENTITY_DATA_KEY_HORSE_FLAGS: UInt32 = (
    ENTITY_DATA_KEY_DISPLAY_BLOCK_STATE
)
"""Go `EntityDataKeyHorseFlags`, an actor-specific meaning of
`EntityDataKeyDisplayBlockState`.
"""
comptime ENTITY_DATA_KEY_WITHER_SKULL_DANGEROUS: UInt32 = (
    ENTITY_DATA_KEY_DISPLAY_BLOCK_STATE
)
"""Go `EntityDataKeyWitherSkullDangerous`, an actor-specific meaning of
`EntityDataKeyDisplayBlockState`.
"""
comptime ENTITY_DATA_KEY_UNKNOWN_HORSE_INTEGER25: UInt32 = (
    ENTITY_DATA_KEY_USING_ITEM
)
"""Go `EntityDataKeyUnknownHorseInteger25`, an actor-specific meaning of
`EntityDataKeyUsingItem`.
"""

comptime ENTITY_DATA_FLAG_ON_FIRE: UInt8 = 0
"""Go `EntityDataFlagOnFire`."""
comptime ENTITY_DATA_FLAG_SNEAKING: UInt8 = 1
"""Go `EntityDataFlagSneaking`."""
comptime ENTITY_DATA_FLAG_RIDING: UInt8 = 2
"""Go `EntityDataFlagRiding`."""
comptime ENTITY_DATA_FLAG_SPRINTING: UInt8 = 3
"""Go `EntityDataFlagSprinting`."""
comptime ENTITY_DATA_FLAG_USING_ITEM: UInt8 = 4
"""Go `EntityDataFlagUsingItem`."""
comptime ENTITY_DATA_FLAG_INVISIBLE: UInt8 = 5
"""Go `EntityDataFlagInvisible`."""
comptime ENTITY_DATA_FLAG_TEMPTED: UInt8 = 6
"""Go `EntityDataFlagTempted`."""
comptime ENTITY_DATA_FLAG_IN_LOVE: UInt8 = 7
"""Go `EntityDataFlagInLove`."""
comptime ENTITY_DATA_FLAG_SADDLED: UInt8 = 8
"""Go `EntityDataFlagSaddled`."""
comptime ENTITY_DATA_FLAG_POWERED: UInt8 = 9
"""Go `EntityDataFlagPowered`."""
comptime ENTITY_DATA_FLAG_IGNITED: UInt8 = 10
"""Go `EntityDataFlagIgnited`."""
comptime ENTITY_DATA_FLAG_BABY: UInt8 = 11
"""Go `EntityDataFlagBaby`."""
comptime ENTITY_DATA_FLAG_CONVERTING: UInt8 = 12
"""Go `EntityDataFlagConverting`."""
comptime ENTITY_DATA_FLAG_CRITICAL: UInt8 = 13
"""Go `EntityDataFlagCritical`."""
comptime ENTITY_DATA_FLAG_SHOW_NAME: UInt8 = 14
"""Go `EntityDataFlagShowName`."""
comptime ENTITY_DATA_FLAG_ALWAYS_SHOW_NAME: UInt8 = 15
"""Go `EntityDataFlagAlwaysShowName`."""
comptime ENTITY_DATA_FLAG_NO_AI: UInt8 = 16
"""Go `EntityDataFlagNoAI`."""
comptime ENTITY_DATA_FLAG_SILENT: UInt8 = 17
"""Go `EntityDataFlagSilent`."""
comptime ENTITY_DATA_FLAG_WALL_CLIMBING: UInt8 = 18
"""Go `EntityDataFlagWallClimbing`."""
comptime ENTITY_DATA_FLAG_CLIMB: UInt8 = 19
"""Go `EntityDataFlagClimb`."""
comptime ENTITY_DATA_FLAG_SWIM: UInt8 = 20
"""Go `EntityDataFlagSwim`."""
comptime ENTITY_DATA_FLAG_FLY: UInt8 = 21
"""Go `EntityDataFlagFly`."""
comptime ENTITY_DATA_FLAG_WALK: UInt8 = 22
"""Go `EntityDataFlagWalk`."""
comptime ENTITY_DATA_FLAG_RESTING: UInt8 = 23
"""Go `EntityDataFlagResting`."""
comptime ENTITY_DATA_FLAG_SITTING: UInt8 = 24
"""Go `EntityDataFlagSitting`."""
comptime ENTITY_DATA_FLAG_ANGRY: UInt8 = 25
"""Go `EntityDataFlagAngry`."""
comptime ENTITY_DATA_FLAG_INTERESTED: UInt8 = 26
"""Go `EntityDataFlagInterested`."""
comptime ENTITY_DATA_FLAG_CHARGED: UInt8 = 27
"""Go `EntityDataFlagCharged`."""
comptime ENTITY_DATA_FLAG_TAMED: UInt8 = 28
"""Go `EntityDataFlagTamed`."""
comptime ENTITY_DATA_FLAG_ORPHANED: UInt8 = 29
"""Go `EntityDataFlagOrphaned`."""
comptime ENTITY_DATA_FLAG_LEASHED: UInt8 = 30
"""Go `EntityDataFlagLeashed`."""
comptime ENTITY_DATA_FLAG_SHEARED: UInt8 = 31
"""Go `EntityDataFlagSheared`."""
comptime ENTITY_DATA_FLAG_GLIDING: UInt8 = 32
"""Go `EntityDataFlagGliding`."""
comptime ENTITY_DATA_FLAG_ELDER: UInt8 = 33
"""Go `EntityDataFlagElder`."""
comptime ENTITY_DATA_FLAG_MOVING: UInt8 = 34
"""Go `EntityDataFlagMoving`."""
comptime ENTITY_DATA_FLAG_BREATHING: UInt8 = 35
"""Go `EntityDataFlagBreathing`."""
comptime ENTITY_DATA_FLAG_CHESTED: UInt8 = 36
"""Go `EntityDataFlagChested`."""
comptime ENTITY_DATA_FLAG_STACKABLE: UInt8 = 37
"""Go `EntityDataFlagStackable`."""
comptime ENTITY_DATA_FLAG_SHOW_BOTTOM: UInt8 = 38
"""Go `EntityDataFlagShowBottom`."""
comptime ENTITY_DATA_FLAG_STANDING: UInt8 = 39
"""Go `EntityDataFlagStanding`."""
comptime ENTITY_DATA_FLAG_SHAKING: UInt8 = 40
"""Go `EntityDataFlagShaking`."""
comptime ENTITY_DATA_FLAG_IDLING: UInt8 = 41
"""Go `EntityDataFlagIdling`."""
comptime ENTITY_DATA_FLAG_CASTING: UInt8 = 42
"""Go `EntityDataFlagCasting`."""
comptime ENTITY_DATA_FLAG_CHARGING: UInt8 = 43
"""Go `EntityDataFlagCharging`."""
comptime ENTITY_DATA_FLAG_KEYBOARD_CONTROLLED: UInt8 = 44
"""Go `EntityDataFlagKeyboardControlled`."""
comptime ENTITY_DATA_FLAG_POWER_JUMP: UInt8 = 45
"""Go `EntityDataFlagPowerJump`."""
comptime ENTITY_DATA_FLAG_DASH: UInt8 = 46
"""Go `EntityDataFlagDash`."""
comptime ENTITY_DATA_FLAG_LINGERING: UInt8 = 47
"""Go `EntityDataFlagLingering`."""
comptime ENTITY_DATA_FLAG_HAS_COLLISION: UInt8 = 48
"""Go `EntityDataFlagHasCollision`."""
comptime ENTITY_DATA_FLAG_HAS_GRAVITY: UInt8 = 49
"""Go `EntityDataFlagHasGravity`."""
comptime ENTITY_DATA_FLAG_FIRE_IMMUNE: UInt8 = 50
"""Go `EntityDataFlagFireImmune`."""
comptime ENTITY_DATA_FLAG_DANCING: UInt8 = 51
"""Go `EntityDataFlagDancing`."""
comptime ENTITY_DATA_FLAG_ENCHANTED: UInt8 = 52
"""Go `EntityDataFlagEnchanted`."""
comptime ENTITY_DATA_FLAG_RETURN_TRIDENT: UInt8 = 53
"""Go `EntityDataFlagReturnTrident`."""
comptime ENTITY_DATA_FLAG_CONTAINER_PRIVATE: UInt8 = 54
"""Go `EntityDataFlagContainerPrivate`."""
comptime ENTITY_DATA_FLAG_TRANSFORMING: UInt8 = 55
"""Go `EntityDataFlagTransforming`."""
comptime ENTITY_DATA_FLAG_DAMAGE_NEARBY_MOBS: UInt8 = 56
"""Go `EntityDataFlagDamageNearbyMobs`."""
comptime ENTITY_DATA_FLAG_SWIMMING: UInt8 = 57
"""Go `EntityDataFlagSwimming`."""
comptime ENTITY_DATA_FLAG_BRIBED: UInt8 = 58
"""Go `EntityDataFlagBribed`."""
comptime ENTITY_DATA_FLAG_PREGNANT: UInt8 = 59
"""Go `EntityDataFlagPregnant`."""
comptime ENTITY_DATA_FLAG_LAYING_EGG: UInt8 = 60
"""Go `EntityDataFlagLayingEgg`."""
comptime ENTITY_DATA_FLAG_PASSENGER_CAN_PICK: UInt8 = 61
"""Go `EntityDataFlagPassengerCanPick`."""
comptime ENTITY_DATA_FLAG_TRANSITION_SITTING: UInt8 = 62
"""Go `EntityDataFlagTransitionSitting`."""
comptime ENTITY_DATA_FLAG_EATING: UInt8 = 63
"""Go `EntityDataFlagEating`."""
comptime ENTITY_DATA_FLAG_LAYING_DOWN: UInt8 = 64
"""Go `EntityDataFlagLayingDown`."""
comptime ENTITY_DATA_FLAG_SNEEZING: UInt8 = 65
"""Go `EntityDataFlagSneezing`."""
comptime ENTITY_DATA_FLAG_TRUSTING: UInt8 = 66
"""Go `EntityDataFlagTrusting`."""
comptime ENTITY_DATA_FLAG_ROLLING: UInt8 = 67
"""Go `EntityDataFlagRolling`."""
comptime ENTITY_DATA_FLAG_SCARED: UInt8 = 68
"""Go `EntityDataFlagScared`."""
comptime ENTITY_DATA_FLAG_IN_SCAFFOLDING: UInt8 = 69
"""Go `EntityDataFlagInScaffolding`."""
comptime ENTITY_DATA_FLAG_OVER_SCAFFOLDING: UInt8 = 70
"""Go `EntityDataFlagOverScaffolding`."""
comptime ENTITY_DATA_FLAG_DESCEND_THROUGH_BLOCK: UInt8 = 71
"""Go `EntityDataFlagDescendThroughBlock`."""
comptime ENTITY_DATA_FLAG_BLOCKING: UInt8 = 72
"""Go `EntityDataFlagBlocking`."""
comptime ENTITY_DATA_FLAG_TRANSITION_BLOCKING: UInt8 = 73
"""Go `EntityDataFlagTransitionBlocking`."""
comptime ENTITY_DATA_FLAG_BLOCKED_USING_SHIELD: UInt8 = 74
"""Go `EntityDataFlagBlockedUsingShield`."""
comptime ENTITY_DATA_FLAG_BLOCKED_USING_DAMAGED_SHIELD: UInt8 = 75
"""Go `EntityDataFlagBlockedUsingDamagedShield`."""
comptime ENTITY_DATA_FLAG_SLEEPING: UInt8 = 76
"""Go `EntityDataFlagSleeping`."""
comptime ENTITY_DATA_FLAG_WANTS_TO_WAKE: UInt8 = 77
"""Go `EntityDataFlagWantsToWake`."""
comptime ENTITY_DATA_FLAG_TRADE_INTEREST: UInt8 = 78
"""Go `EntityDataFlagTradeInterest`."""
comptime ENTITY_DATA_FLAG_DOOR_BREAKER: UInt8 = 79
"""Go `EntityDataFlagDoorBreaker`."""
comptime ENTITY_DATA_FLAG_BREAKING_OBSTRUCTION: UInt8 = 80
"""Go `EntityDataFlagBreakingObstruction`."""
comptime ENTITY_DATA_FLAG_DOOR_OPENER: UInt8 = 81
"""Go `EntityDataFlagDoorOpener`."""
comptime ENTITY_DATA_FLAG_CAPTAIN: UInt8 = 82
"""Go `EntityDataFlagCaptain`."""
comptime ENTITY_DATA_FLAG_STUNNED: UInt8 = 83
"""Go `EntityDataFlagStunned`."""
comptime ENTITY_DATA_FLAG_ROARING: UInt8 = 84
"""Go `EntityDataFlagRoaring`."""
comptime ENTITY_DATA_FLAG_DELAYED_ATTACK: UInt8 = 85
"""Go `EntityDataFlagDelayedAttack`."""
comptime ENTITY_DATA_FLAG_AVOIDING_MOBS: UInt8 = 86
"""Go `EntityDataFlagAvoidingMobs`."""
comptime ENTITY_DATA_FLAG_AVOIDING_BLOCK: UInt8 = 87
"""Go `EntityDataFlagAvoidingBlock`."""
comptime ENTITY_DATA_FLAG_FACING_TARGET_TO_RANGE_ATTACK: UInt8 = 88
"""Go `EntityDataFlagFacingTargetToRangeAttack`."""
comptime ENTITY_DATA_FLAG_HIDDEN_WHEN_INVISIBLE: UInt8 = 89
"""Go `EntityDataFlagHiddenWhenInvisible`."""
comptime ENTITY_DATA_FLAG_IN_UI: UInt8 = 90
"""Go `EntityDataFlagInUI`."""
comptime ENTITY_DATA_FLAG_STALKING: UInt8 = 91
"""Go `EntityDataFlagStalking`."""
comptime ENTITY_DATA_FLAG_EMOTING: UInt8 = 92
"""Go `EntityDataFlagEmoting`."""
comptime ENTITY_DATA_FLAG_CELEBRATING: UInt8 = 93
"""Go `EntityDataFlagCelebrating`."""
comptime ENTITY_DATA_FLAG_ADMIRING: UInt8 = 94
"""Go `EntityDataFlagAdmiring`."""
comptime ENTITY_DATA_FLAG_CELEBRATING_SPECIAL: UInt8 = 95
"""Go `EntityDataFlagCelebratingSpecial`."""
comptime ENTITY_DATA_FLAG_OUT_OF_CONTROL: UInt8 = 96
"""Go `EntityDataFlagOutOfControl`."""
comptime ENTITY_DATA_FLAG_RAM_ATTACK: UInt8 = 97
"""Go `EntityDataFlagRamAttack`."""
comptime ENTITY_DATA_FLAG_PLAYING_DEAD: UInt8 = 98
"""Go `EntityDataFlagPlayingDead`."""
comptime ENTITY_DATA_FLAG_IN_ASCENDING_BLOCK: UInt8 = 99
"""Go `EntityDataFlagInAscendingBlock`."""
comptime ENTITY_DATA_FLAG_OVER_DESCENDING_BLOCK: UInt8 = 100
"""Go `EntityDataFlagOverDescendingBlock`."""
comptime ENTITY_DATA_FLAG_CROAKING: UInt8 = 101
"""Go `EntityDataFlagCroaking`."""
comptime ENTITY_DATA_FLAG_DIGEST_MOB: UInt8 = 102
"""Go `EntityDataFlagDigestMob`."""
comptime ENTITY_DATA_FLAG_JUMP_GOAL: UInt8 = 103
"""Go `EntityDataFlagJumpGoal`."""
comptime ENTITY_DATA_FLAG_EMERGING: UInt8 = 104
"""Go `EntityDataFlagEmerging`."""
comptime ENTITY_DATA_FLAG_SNIFFING: UInt8 = 105
"""Go `EntityDataFlagSniffing`."""
comptime ENTITY_DATA_FLAG_DIGGING: UInt8 = 106
"""Go `EntityDataFlagDigging`."""
comptime ENTITY_DATA_FLAG_SONIC_BOOM: UInt8 = 107
"""Go `EntityDataFlagSonicBoom`."""
comptime ENTITY_DATA_FLAG_HAS_DASH_TIMEOUT: UInt8 = 108
"""Go `EntityDataFlagHasDashTimeout`."""
comptime ENTITY_DATA_FLAG_PUSH_TOWARDS_CLOSEST_SPACE: UInt8 = 109
"""Go `EntityDataFlagPushTowardsClosestSpace`."""
comptime ENTITY_DATA_FLAG_SCENTING: UInt8 = 110
"""Go `EntityDataFlagScenting`."""
comptime ENTITY_DATA_FLAG_RISING: UInt8 = 111
"""Go `EntityDataFlagRising`."""
comptime ENTITY_DATA_FLAG_FEELING_HAPPY: UInt8 = 112
"""Go `EntityDataFlagFeelingHappy`."""
comptime ENTITY_DATA_FLAG_SEARCHING: UInt8 = 113
"""Go `EntityDataFlagSearching`."""
comptime ENTITY_DATA_FLAG_CRAWLING: UInt8 = 114
"""Go `EntityDataFlagCrawling`."""
comptime ENTITY_DATA_FLAG_TIMER_FLAG1: UInt8 = 115
"""Go `EntityDataFlagTimerFlag1`."""
comptime ENTITY_DATA_FLAG_TIMER_FLAG2: UInt8 = 116
"""Go `EntityDataFlagTimerFlag2`."""
comptime ENTITY_DATA_FLAG_TIMER_FLAG3: UInt8 = 117
"""Go `EntityDataFlagTimerFlag3`."""
comptime ENTITY_DATA_FLAG_BODY_ROTATION_BLOCKED: UInt8 = 118
"""Go `EntityDataFlagBodyRotationBlocked`."""
comptime ENTITY_DATA_FLAG_RENDER_WHEN_INVISIBLE: UInt8 = 119
"""Go `EntityDataFlagRenderWhenInvisible`."""
comptime ENTITY_DATA_FLAG_BODY_ROTATION_AXIS_ALIGNED: UInt8 = 120
"""Go `EntityDataFlagBodyRotationAxisAligned`."""
comptime ENTITY_DATA_FLAG_COLLIDABLE: UInt8 = 121
"""Go `EntityDataFlagCollidable`."""
comptime ENTITY_DATA_FLAG_WASD_AIR_CONTROLLED: UInt8 = 122
"""Go `EntityDataFlagWASDAirControlled`."""
comptime ENTITY_DATA_FLAG_DOES_SERVER_AUTH_ONLY_DISMOUNT: UInt8 = 123
"""Go `EntityDataFlagDoesServerAuthOnlyDismount`."""
comptime ENTITY_DATA_FLAG_BODY_ROTATION_ALWAYS_FOLLOWS_HEAD: UInt8 = 124
"""Go `EntityDataFlagBodyRotationAlwaysFollowsHead`."""
comptime ENTITY_DATA_FLAG_CAN_USE_VERTICAL_MOVEMENT_ACTION: UInt8 = 125
"""Go `EntityDataFlagCanUseVerticalMovementAction`."""
comptime ENTITY_DATA_FLAG_ROTATION_LOCKED_TO_VEHICLE: UInt8 = 126
"""Go `EntityDataFlagRotationLockedToVehicle`."""
comptime ENTITY_DATA_FLAG_USES_LEGACY_FRICTION: UInt8 = 127
"""Go `EntityDataFlagUsesLegacyFriction`."""
comptime ENTITY_DATA_FLAG_USES_UNIFORM_AIR_DRAG: UInt8 = 128
"""Go `EntityDataFlagUsesUniformAirDrag`."""
comptime ENTITY_DATA_FLAG_NAMEPLATE_DEPTH_TESTED: UInt8 = 129
"""Go `EntityDataFlagNameplateDepthTested`."""
comptime ENTITY_DATA_FLAG_NOT_PICKABLE_FROM_INSIDE: UInt8 = 130
"""Go `EntityDataFlagNotPickableFromInside`."""
comptime ENTITY_DATA_FLAG_COUNT: UInt8 = 131
"""The number of entity data flags."""

comptime ENTITY_DATA_TYPE_BYTE: UInt32 = 0
"""Go `EntityDataTypeByte`."""
comptime ENTITY_DATA_TYPE_INT16: UInt32 = 1
"""Go `EntityDataTypeInt16`."""
comptime ENTITY_DATA_TYPE_INT32: UInt32 = 2
"""Go `EntityDataTypeInt32`."""
comptime ENTITY_DATA_TYPE_FLOAT32: UInt32 = 3
"""Go `EntityDataTypeFloat32`."""
comptime ENTITY_DATA_TYPE_STRING: UInt32 = 4
"""Go `EntityDataTypeString`."""
comptime ENTITY_DATA_TYPE_COMPOUND_TAG: UInt32 = 5
"""Go `EntityDataTypeCompoundTag`."""
comptime ENTITY_DATA_TYPE_BLOCK_POS: UInt32 = 6
"""Go `EntityDataTypeBlockPos`."""
comptime ENTITY_DATA_TYPE_INT64: UInt32 = 7
"""Go `EntityDataTypeInt64`."""
comptime ENTITY_DATA_TYPE_VEC3: UInt32 = 8
"""Go `EntityDataTypeVec3`."""

comptime EntityDataValue = Variant[
    UInt8, Int16, Int32, Float32, String, NBT, BlockPos, Int64, Vec3
]
"""An entity metadata value, one arm per `ENTITY_DATA_TYPE_*` in order.

The compound tag arm is `NBT` in the network little-endian encoding.
"""


@fieldwise_init
struct EntityMetadataEntry(Copyable):
    """One key/value pair of entity metadata."""

    var key: UInt32
    """One of the `ENTITY_DATA_KEY_*` values."""
    var value: EntityDataValue
    """The value; its arm selects the wire type."""


struct EntityMetadata(Marshaler, Sized):
    """The metadata of an entity (Go `map[uint32]any`).

    The zero value is empty; `new_entity_metadata()` adds the flag keys.
    """

    var entries: List[EntityMetadataEntry]
    """The entries in the order they were read or added."""

    def __init__(out self):
        """Creates empty metadata."""
        self.entries = List[EntityMetadataEntry]()

    def __len__(self) -> Int:
        """Counts the entries.

        Returns:
            The number of entries.
        """
        return len(self.entries)

    def _find(self, key: UInt32) -> Int:
        var i = len(self.entries) - 1
        while i >= 0:
            if self.entries[i].key == key:
                return i
            i -= 1
        return -1

    def __contains__(self, key: UInt32) -> Bool:
        """Checks whether a key is present.

        Args:
            key: The key.

        Returns:
            `True` if an entry has the key.
        """
        return self._find(key) >= 0

    def get(self, key: UInt32) -> Optional[EntityDataValue]:
        """Looks up the value of a key.

        Args:
            key: The key.

        Returns:
            A copy of the value of the last entry with the key, if any.
        """
        var i = self._find(key)
        if i < 0:
            return None
        return self.entries[i].value.copy()

    def set(mut self, key: UInt32, var value: EntityDataValue):
        """Sets the value of a key, replacing an existing entry.

        Args:
            key: The key.
            value: The new value.
        """
        var i = self._find(key)
        if i < 0:
            self.entries.append(EntityMetadataEntry(key, value^))
        else:
            self.entries[i].value = value^

    def remove(mut self, key: UInt32):
        """Removes every entry with a key (Go `delete`).

        Args:
            key: The key.
        """
        var kept = List[EntityMetadataEntry](capacity=len(self.entries))
        for e in self.entries:
            if e.key != key:
                kept.append(e.copy())
        self.entries = kept^

    def _flag_entry(mut self, key: UInt32) raises -> Int:
        var i = self._find(key)
        if i < 0:
            raise Error(t"entity metadata has no flag key {key}")
        ref v = self.entries[i].value
        if key == ENTITY_DATA_KEY_PLAYER_FLAGS:
            if not v.isa[UInt8]():
                raise Error("entity metadata player flags are not a byte")
        elif not v.isa[Int64]():
            raise Error(t"entity metadata flags {key} are not an int64")
        return i

    def set_flag(mut self, key: UInt32, index: UInt8) raises:
        """Sets flag `index` in the flag field `key`.

        Flags at or above 64 belong in `ENTITY_DATA_KEY_FLAGS_TWO` at
        `index - 64`; as in Go, an index past the field width does nothing.

        Args:
            key: `ENTITY_DATA_KEY_FLAGS`, `ENTITY_DATA_KEY_FLAGS_TWO` or
                `ENTITY_DATA_KEY_PLAYER_FLAGS`.
            index: An `ENTITY_DATA_FLAG_*` value (or a player flag).

        Raises:
            If the key is missing or holds the wrong type.
        """
        var i = self._flag_entry(key)
        ref v = self.entries[i].value
        if key == ENTITY_DATA_KEY_PLAYER_FLAGS:
            if index < 8:
                v[UInt8] |= UInt8(1) << index
        elif index < 64:
            v[Int64] |= Int64(1) << Int64(index)

    def unset_flag(mut self, key: UInt32, index: UInt8) raises:
        """Clears flag `index` in the flag field `key`.

        Args:
            key: The flag field, as for `set_flag`.
            index: The flag index.

        Raises:
            If the key is missing or holds the wrong type.
        """
        var i = self._flag_entry(key)
        ref v = self.entries[i].value
        if key == ENTITY_DATA_KEY_PLAYER_FLAGS:
            if index < 8:
                v[UInt8] &= ~(UInt8(1) << index)
        elif index < 64:
            v[Int64] &= ~(Int64(1) << Int64(index))

    def flag(mut self, key: UInt32, index: UInt8) raises -> Bool:
        """Reports whether flag `index` is set in the flag field `key`.

        Args:
            key: The flag field, as for `set_flag`.
            index: The flag index.

        Returns:
            `True` if the flag is set.

        Raises:
            If the key is missing or holds the wrong type.
        """
        var i = self._flag_entry(key)
        ref v = self.entries[i].value
        if key == ENTITY_DATA_KEY_PLAYER_FLAGS:
            return index < 8 and (v[UInt8] >> index) & 1 == 1
        return index < 64 and (v[Int64] >> Int64(index)) & 1 == 1

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the metadata (see `entity_metadata`).

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        entity_metadata(io, self)


def new_entity_metadata() -> EntityMetadata:
    """Creates metadata holding the zeroed flag fields (Go `NewEntityMetadata`).

    Returns:
        Metadata with `FLAGS` and `FLAGS_TWO` as `Int64(0)` and
        `PLAYER_FLAGS` as `UInt8(0)`.
    """
    var m = EntityMetadata()
    m.set(ENTITY_DATA_KEY_FLAGS, Int64(0))
    m.set(ENTITY_DATA_KEY_PLAYER_FLAGS, UInt8(0))
    m.set(ENTITY_DATA_KEY_FLAGS_TWO, Int64(0))
    return m^


def _data_type(v: EntityDataValue) -> UInt32:
    if v.isa[UInt8]():
        return ENTITY_DATA_TYPE_BYTE
    if v.isa[Int16]():
        return ENTITY_DATA_TYPE_INT16
    if v.isa[Int32]():
        return ENTITY_DATA_TYPE_INT32
    if v.isa[Float32]():
        return ENTITY_DATA_TYPE_FLOAT32
    if v.isa[String]():
        return ENTITY_DATA_TYPE_STRING
    if v.isa[NBT]():
        return ENTITY_DATA_TYPE_COMPOUND_TAG
    if v.isa[BlockPos]():
        return ENTITY_DATA_TYPE_BLOCK_POS
    if v.isa[Int64]():
        return ENTITY_DATA_TYPE_INT64
    return ENTITY_DATA_TYPE_VEC3


def _zero_value(data_type: UInt32) raises -> EntityDataValue:
    if data_type == ENTITY_DATA_TYPE_BYTE:
        return UInt8(0)
    if data_type == ENTITY_DATA_TYPE_INT16:
        return Int16(0)
    if data_type == ENTITY_DATA_TYPE_INT32:
        return Int32(0)
    if data_type == ENTITY_DATA_TYPE_FLOAT32:
        return Float32(0)
    if data_type == ENTITY_DATA_TYPE_STRING:
        return String()
    if data_type == ENTITY_DATA_TYPE_COMPOUND_TAG:
        return NBT()
    if data_type == ENTITY_DATA_TYPE_BLOCK_POS:
        return BlockPos()
    if data_type == ENTITY_DATA_TYPE_INT64:
        return Int64(0)
    if data_type == ENTITY_DATA_TYPE_VEC3:
        return Vec3()
    unknown_enum_option(Int(data_type), "entity metadata")
    raise Error("unreachable")


def _metadata_entry[I: IO](mut io: I, mut e: EntityMetadataEntry) raises:
    io.varuint32(e.key)
    var data_type = _data_type(e.value)
    io.varuint32(data_type)
    # The value type is sent twice: as the cereal selector and as a byte.
    var legacy = UInt8(data_type & 0xFF)
    io.uint8(legacy)
    if UInt32(legacy) != data_type:
        invalid_value(
            String(legacy),
            "entity metadata type",
            String(t"does not match cereal selector {data_type}"),
        )
    if io.reads():
        e.value = _zero_value(data_type)
    ref v = e.value
    if v.isa[UInt8]():
        io.uint8(v[UInt8])
    elif v.isa[Int16]():
        io.int16(v[Int16])
    elif v.isa[Int32]():
        io.varint32(v[Int32])
    elif v.isa[Float32]():
        io.float32(v[Float32])
    elif v.isa[String]():
        io.string(v[String])
    elif v.isa[NBT]():
        nbt(io, v[NBT], NETWORK_LITTLE_ENDIAN)
    elif v.isa[BlockPos]():
        block_pos(io, v[BlockPos])
    elif v.isa[Int64]():
        io.varint64(v[Int64])
    else:
        vec3(io, v[Vec3])


def entity_metadata[I: IO](mut io: I, mut x: EntityMetadata) raises:
    """Marshals a varuint32 count, then key, type and value per entry.

    This is gophertunnel `IO.EntityMetadata`. Writing sorts by key and keeps
    only the last entry of a repeated key; reading keeps the wire order.

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The metadata; replaced when reading.

    Raises:
        If the input is malformed or a value type is unknown or mismatched.
    """
    if io.reads():
        var count = UInt32(0)
        io.varuint32(count)
        # No limit in Go: every entry takes at least three bytes, so the
        # payload bounds the loop. Do not preallocate `count` entries.
        x = EntityMetadata()
        for _ in range(Int(count)):
            var e = EntityMetadataEntry(0, UInt8(0))
            _metadata_entry(io, e)
            x.entries.append(e^)
        return
    # Sort indices by key; `key << 32 | index` keeps the sort stable.
    var order = List[UInt64](capacity=len(x.entries))
    for i in range(len(x.entries)):
        order.append((UInt64(x.entries[i].key) << 32) | UInt64(i))
    sort(order)
    var unique = List[Int](capacity=len(order))
    for j in range(len(order)):
        var last_of_key = j + 1 == len(order) or (order[j] >> 32) != (
            order[j + 1] >> 32
        )
        if last_of_key:
            unique.append(Int(order[j] & 0xFFFFFFFF))
    var count = UInt32(len(unique))
    io.varuint32(count)
    for i in unique:
        _metadata_entry(io, x.entries[i])
