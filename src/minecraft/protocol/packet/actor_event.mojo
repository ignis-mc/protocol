"""The `ActorEvent` packet (gophertunnel `packet/actor_event.go`)."""

from ..io import IO, actor_runtime_id, optional_vec3
from ..math import Vec3
from .id import ID_ACTOR_EVENT
from .packet import Packet

comptime ACTOR_EVENT_JUMP: UInt8 = 1
"""Go `ActorEventJump`."""
comptime ACTOR_EVENT_HURT: UInt8 = 2
"""Go `ActorEventHurt`."""
comptime ACTOR_EVENT_DEATH: UInt8 = 3
"""Go `ActorEventDeath`."""
comptime ACTOR_EVENT_START_ATTACKING: UInt8 = 4
"""Go `ActorEventStartAttacking`."""
comptime ACTOR_EVENT_STOP_ATTACKING: UInt8 = 5
"""Go `ActorEventStopAttacking`."""
comptime ACTOR_EVENT_TAMING_FAILED: UInt8 = 6
"""Go `ActorEventTamingFailed`."""
comptime ACTOR_EVENT_TAMING_SUCCEEDED: UInt8 = 7
"""Go `ActorEventTamingSucceeded`."""
comptime ACTOR_EVENT_SHAKE_WETNESS: UInt8 = 8
"""Go `ActorEventShakeWetness`."""
comptime ACTOR_EVENT_USE_ITEM: UInt8 = 9
"""Go `ActorEventUseItem`."""
comptime ACTOR_EVENT_EAT_GRASS: UInt8 = 10
"""Go `ActorEventEatGrass`."""
comptime ACTOR_EVENT_FISHHOOK_BUBBLE: UInt8 = 11
"""Go `ActorEventFishhookBubble`."""
comptime ACTOR_EVENT_FISHHOOK_FISH_POSITION: UInt8 = 12
"""Go `ActorEventFishhookFishPosition`."""
comptime ACTOR_EVENT_FISHHOOK_HOOK_TIME: UInt8 = 13
"""Go `ActorEventFishhookHookTime`."""
comptime ACTOR_EVENT_FISHHOOK_TEASE: UInt8 = 14
"""Go `ActorEventFishhookTease`."""
comptime ACTOR_EVENT_SQUID_FLEEING: UInt8 = 15
"""Go `ActorEventSquidFleeing`."""
comptime ACTOR_EVENT_ZOMBIE_CONVERTING: UInt8 = 16
"""Go `ActorEventZombieConverting`."""
comptime ACTOR_EVENT_PLAY_AMBIENT: UInt8 = 17
"""Go `ActorEventPlayAmbient`."""
comptime ACTOR_EVENT_SPAWN_ALIVE: UInt8 = 18
"""Go `ActorEventSpawnAlive`."""
comptime ACTOR_EVENT_START_OFFER_FLOWER: UInt8 = 19
"""Go `ActorEventStartOfferFlower`."""
comptime ACTOR_EVENT_STOP_OFFER_FLOWER: UInt8 = 20
"""Go `ActorEventStopOfferFlower`."""
comptime ACTOR_EVENT_LOVE_HEARTS: UInt8 = 21
"""Go `ActorEventLoveHearts`."""
comptime ACTOR_EVENT_VILLAGER_ANGRY: UInt8 = 22
"""Go `ActorEventVillagerAngry`."""
comptime ACTOR_EVENT_VILLAGER_HAPPY: UInt8 = 23
"""Go `ActorEventVillagerHappy`."""
comptime ACTOR_EVENT_WITCH_HAT_MAGIC: UInt8 = 24
"""Go `ActorEventWitchHatMagic`."""
comptime ACTOR_EVENT_FIREWORKS_EXPLODE: UInt8 = 25
"""Go `ActorEventFireworksExplode`."""
comptime ACTOR_EVENT_IN_LOVE_HEARTS: UInt8 = 26
"""Go `ActorEventInLoveHearts`."""
comptime ACTOR_EVENT_SILVERFISH_MERGE_ANIMATION: UInt8 = 27
"""Go `ActorEventSilverfishMergeAnimation`."""
comptime ACTOR_EVENT_GUARDIAN_ATTACK_SOUND: UInt8 = 28
"""Go `ActorEventGuardianAttackSound`."""
comptime ACTOR_EVENT_DRINK_POTION: UInt8 = 29
"""Go `ActorEventDrinkPotion`."""
comptime ACTOR_EVENT_THROW_POTION: UInt8 = 30
"""Go `ActorEventThrowPotion`."""
comptime ACTOR_EVENT_CART_WITH_PRIME_TNT: UInt8 = 31
"""Go `ActorEventCartWithPrimeTNT`."""
comptime ACTOR_EVENT_PRIME_CREEPER: UInt8 = 32
"""Go `ActorEventPrimeCreeper`."""
comptime ACTOR_EVENT_AIR_SUPPLY: UInt8 = 33
"""Go `ActorEventAirSupply`."""
comptime ACTOR_EVENT_ADD_PLAYER_LEVELS: UInt8 = 34
"""Go `ActorEventAddPlayerLevels`."""
comptime ACTOR_EVENT_GUARDIAN_MINING_FATIGUE: UInt8 = 35
"""Go `ActorEventGuardianMiningFatigue`."""
comptime ACTOR_EVENT_AGENT_SWING_ARM: UInt8 = 36
"""Go `ActorEventAgentSwingArm`."""
comptime ACTOR_EVENT_DRAGON_START_DEATH_ANIM: UInt8 = 37
"""Go `ActorEventDragonStartDeathAnim`."""
comptime ACTOR_EVENT_GROUND_DUST: UInt8 = 38
"""Go `ActorEventGroundDust`."""
comptime ACTOR_EVENT_SHAKE: UInt8 = 39
"""Go `ActorEventShake`."""
comptime ACTOR_EVENT_FEED: UInt8 = 57
"""Go `ActorEventFeed`."""
comptime ACTOR_EVENT_BABY_EAT: UInt8 = 60
"""Go `ActorEventBabyEat`."""
comptime ACTOR_EVENT_INSTANT_DEATH: UInt8 = 61
"""Go `ActorEventInstantDeath`."""
comptime ACTOR_EVENT_NOTIFY_TRADE: UInt8 = 62
"""Go `ActorEventNotifyTrade`."""
comptime ACTOR_EVENT_LEASH_DESTROYED: UInt8 = 63
"""Go `ActorEventLeashDestroyed`."""
comptime ACTOR_EVENT_CARAVAN_UPDATED: UInt8 = 64
"""Go `ActorEventCaravanUpdated`."""
comptime ACTOR_EVENT_TALISMAN_ACTIVATE: UInt8 = 65
"""Go `ActorEventTalismanActivate`."""
comptime ACTOR_EVENT_UPDATE_STRUCTURE_FEATURE: UInt8 = 66
"""Go `ActorEventUpdateStructureFeature`."""
comptime ACTOR_EVENT_PLAYER_SPAWNED_MOB: UInt8 = 67
"""Go `ActorEventPlayerSpawnedMob`."""
comptime ACTOR_EVENT_PUKE: UInt8 = 68
"""Go `ActorEventPuke`."""
comptime ACTOR_EVENT_UPDATE_STACK_SIZE: UInt8 = 69
"""Go `ActorEventUpdateStackSize`."""
comptime ACTOR_EVENT_START_SWIMMING: UInt8 = 70
"""Go `ActorEventStartSwimming`."""
comptime ACTOR_EVENT_BALLOON_POP: UInt8 = 71
"""Go `ActorEventBalloonPop`."""
comptime ACTOR_EVENT_TREASURE_HUNT: UInt8 = 72
"""Go `ActorEventTreasureHunt`."""
comptime ACTOR_EVENT_SUMMON_AGENT: UInt8 = 73
"""Go `ActorEventSummonAgent`."""
comptime ACTOR_EVENT_FINISHED_CHARGING_ITEM: UInt8 = 74
"""Go `ActorEventFinishedChargingItem`."""
comptime ACTOR_EVENT_LANDED_ON_GROUND: UInt8 = 75
"""Go `ActorEventLandedOnGround`."""
comptime ACTOR_EVENT_ACTOR_GROW_UP: UInt8 = 76
"""Go `ActorEventActorGrowUp`."""
comptime ACTOR_EVENT_VIBRATION_DETECTED: UInt8 = 77
"""Go `ActorEventVibrationDetected`."""
comptime ACTOR_EVENT_DRINK_MILK: UInt8 = 78
"""Go `ActorEventDrinkMilk`."""
comptime ACTOR_EVENT_WETNESS_STOP: UInt8 = 79
"""Go `ActorEventWetnessStop`."""
comptime ACTOR_EVENT_KINETIC_DAMAGE_DEALT: UInt8 = 80
"""Go `ActorEventKineticDamageDealt`."""
comptime ACTOR_EVENT_HURT_WITHOUT_RECEIVING_DAMAGE: UInt8 = 81
"""Go `ActorEventHurtWithoutReceivingDamage`."""


struct ActorEvent(Packet):
    """Sent by the server when an event happens to an entity, such as dying."""

    comptime ID: UInt32 = ID_ACTOR_EVENT
    """The packet ID."""
    var entity_runtime_id: UInt64
    """The runtime ID of the entity, unique per world session."""
    var event_type: UInt8
    """One of the `ACTOR_EVENT_*` values."""
    var event_data: Int32
    """Event-specific data; most events leave it zero."""
    var fire_at_position: Optional[Vec3]
    """Where the event fires; the entity position if absent."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.entity_runtime_id = 0
        self.event_type = 0
        self.event_data = 0
        self.fire_at_position = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        actor_runtime_id(io, self.entity_runtime_id)
        io.uint8(self.event_type)
        io.varint32(self.event_data)
        optional_vec3(io, self.fire_at_position)
