"""The `LevelEvent` packet (gophertunnel `packet/level_event.go`)."""

from ..io import IO, vec3
from ..math import Vec3
from .id import ID_LEVEL_EVENT
from .packet import Packet

comptime PARTICLE_TYPE_UNDEFINED: Int32 = 0
"""The undefined particle."""
comptime PARTICLE_TYPE_BUBBLE: Int32 = 1
"""The bubble particle."""
comptime PARTICLE_TYPE_BUBBLE_MANUAL: Int32 = 2
"""The bubble manual particle."""
comptime PARTICLE_TYPE_CRIT: Int32 = 3
"""The crit particle."""
comptime PARTICLE_TYPE_BLOCK_FORCE_FIELD: Int32 = 4
"""The block force field particle."""
comptime PARTICLE_TYPE_SMOKE: Int32 = 5
"""The smoke particle."""
comptime PARTICLE_TYPE_EXPLODE: Int32 = 6
"""The explode particle."""
comptime PARTICLE_TYPE_EVAPORATION: Int32 = 7
"""The evaporation particle."""
comptime PARTICLE_TYPE_FLAME: Int32 = 8
"""The flame particle."""
comptime PARTICLE_TYPE_LAVA: Int32 = 9
"""The lava particle."""
comptime PARTICLE_TYPE_LARGE_SMOKE: Int32 = 10
"""The large smoke particle."""
comptime PARTICLE_TYPE_RED_DUST: Int32 = 11
"""The red dust particle."""
comptime PARTICLE_TYPE_RISING_BORDER_DUST: Int32 = 12
"""The rising border dust particle."""
comptime PARTICLE_TYPE_ICON_CRACK: Int32 = 13
"""The icon crack particle."""
comptime PARTICLE_TYPE_SNOWBALL_POOF: Int32 = 14
"""The snowball poof particle."""
comptime PARTICLE_TYPE_LARGE_EXPLODE: Int32 = 15
"""The large explode particle."""
comptime PARTICLE_TYPE_HUGE_EXPLOSION: Int32 = 16
"""The huge explosion particle."""
comptime PARTICLE_TYPE_MOB_FLAME: Int32 = 17
"""The mob flame particle."""
comptime PARTICLE_TYPE_HEART: Int32 = 18
"""The heart particle."""
comptime PARTICLE_TYPE_TERRAIN: Int32 = 19
"""The terrain particle."""
comptime PARTICLE_TYPE_TOWN_AURA: Int32 = 20
"""The town aura particle."""
comptime PARTICLE_TYPE_PORTAL: Int32 = 21
"""The portal particle."""
comptime PARTICLE_TYPE_MOB_PORTAL: Int32 = 22
"""The mob portal particle."""
comptime PARTICLE_TYPE_WATER_SPLASH: Int32 = 23
"""The water splash particle."""
comptime PARTICLE_TYPE_WATER_SPLASH_MANUAL: Int32 = 24
"""The water splash manual particle."""
comptime PARTICLE_TYPE_WATER_WAKE: Int32 = 25
"""The water wake particle."""
comptime PARTICLE_TYPE_DRIP_WATER: Int32 = 26
"""The drip water particle."""
comptime PARTICLE_TYPE_DRIP_LAVA: Int32 = 27
"""The drip lava particle."""
comptime PARTICLE_TYPE_DRIP_HONEY: Int32 = 28
"""The drip honey particle."""
comptime PARTICLE_TYPE_STALACTITE_DRIP_WATER: Int32 = 29
"""The stalactite drip water particle."""
comptime PARTICLE_TYPE_STALACTITE_DRIP_LAVA: Int32 = 30
"""The stalactite drip lava particle."""
comptime PARTICLE_TYPE_FALLING_DUST: Int32 = 31
"""The falling dust particle."""
comptime PARTICLE_TYPE_MOB_SPELL: Int32 = 32
"""The mob spell particle."""
comptime PARTICLE_TYPE_MOB_SPELL_AMBIENT: Int32 = 33
"""The mob spell ambient particle."""
comptime PARTICLE_TYPE_MOB_SPELL_INSTANTANEOUS: Int32 = 34
"""The mob spell instantaneous particle."""
comptime PARTICLE_TYPE_INK: Int32 = 35
"""The ink particle."""
comptime PARTICLE_TYPE_SLIME: Int32 = 36
"""The slime particle."""
comptime PARTICLE_TYPE_RAIN_SPLASH: Int32 = 37
"""The rain splash particle."""
comptime PARTICLE_TYPE_VILLAGER_ANGRY: Int32 = 38
"""The villager angry particle."""
comptime PARTICLE_TYPE_VILLAGER_HAPPY: Int32 = 39
"""The villager happy particle."""
comptime PARTICLE_TYPE_ENCHANTING_TABLE: Int32 = 40
"""The enchanting table particle."""
comptime PARTICLE_TYPE_TRACKER_EMITTER: Int32 = 41
"""The tracker emitter particle."""
comptime PARTICLE_TYPE_NOTE: Int32 = 42
"""The note particle."""
comptime PARTICLE_TYPE_WITCH_SPELL: Int32 = 43
"""The witch spell particle."""
comptime PARTICLE_TYPE_CARROT_BOOST: Int32 = 44
"""The carrot boost particle."""
comptime PARTICLE_TYPE_MOB_APPEARANCE: Int32 = 45
"""The mob appearance particle."""
comptime PARTICLE_TYPE_END_ROD: Int32 = 46
"""The end rod particle."""
comptime PARTICLE_TYPE_DRAGON_BREATH: Int32 = 47
"""The dragon breath particle."""
comptime PARTICLE_TYPE_SPIT: Int32 = 48
"""The spit particle."""
comptime PARTICLE_TYPE_TOTEM: Int32 = 49
"""The totem particle."""
comptime PARTICLE_TYPE_FOOD: Int32 = 50
"""The food particle."""
comptime PARTICLE_TYPE_FIREWORKS_STARTER: Int32 = 51
"""The fireworks starter particle."""
comptime PARTICLE_TYPE_FIREWORKS: Int32 = 52
"""The fireworks particle."""
comptime PARTICLE_TYPE_FIREWORKS_OVERLAY: Int32 = 53
"""The fireworks overlay particle."""
comptime PARTICLE_TYPE_BALLOON_GAS: Int32 = 54
"""The balloon gas particle."""
comptime PARTICLE_TYPE_COLOURED_FLAME: Int32 = 55
"""The coloured flame particle."""
comptime PARTICLE_TYPE_SPARKLER: Int32 = 56
"""The sparkler particle."""
comptime PARTICLE_TYPE_CONDUIT: Int32 = 57
"""The conduit particle."""
comptime PARTICLE_TYPE_BUBBLE_COLUMN_UP: Int32 = 58
"""The bubble column up particle."""
comptime PARTICLE_TYPE_BUBBLE_COLUMN_DOWN: Int32 = 59
"""The bubble column down particle."""
comptime PARTICLE_TYPE_SNEEZE: Int32 = 60
"""The sneeze particle."""
comptime PARTICLE_TYPE_SHULKER_BULLET: Int32 = 61
"""The shulker bullet particle."""
comptime PARTICLE_TYPE_BLEACH: Int32 = 62
"""The bleach particle."""
comptime PARTICLE_TYPE_DRAGON_DESTROY_BLOCK: Int32 = 63
"""The dragon destroy block particle."""
comptime PARTICLE_TYPE_MYCELIUM_DUST: Int32 = 64
"""The mycelium dust particle."""
comptime PARTICLE_TYPE_FALLING_BORDER_DUST: Int32 = 65
"""The falling border dust particle."""
comptime PARTICLE_TYPE_CAMPFIRE_SMOKE: Int32 = 66
"""The campfire smoke particle."""
comptime PARTICLE_TYPE_CAMPFIRE_SMOKE_TALL: Int32 = 67
"""The campfire smoke tall particle."""
comptime PARTICLE_TYPE_DRAGON_BREATH_FIRE: Int32 = 68
"""The dragon breath fire particle."""
comptime PARTICLE_TYPE_DRAGON_BREATH_TRAIL: Int32 = 69
"""The dragon breath trail particle."""
comptime PARTICLE_TYPE_BLUE_FLAME: Int32 = 70
"""The blue flame particle."""
comptime PARTICLE_TYPE_SOUL: Int32 = 71
"""The soul particle."""
comptime PARTICLE_TYPE_OBSIDIAN_TEAR: Int32 = 72
"""The obsidian tear particle."""
comptime PARTICLE_TYPE_PORTAL_REVERSE: Int32 = 73
"""The portal reverse particle."""
comptime PARTICLE_TYPE_SNOWFLAKE: Int32 = 74
"""The snowflake particle."""
comptime PARTICLE_TYPE_VIBRATION_SIGNAL: Int32 = 75
"""The vibration signal particle."""
comptime PARTICLE_TYPE_SCULK_SENSOR_REDSTONE: Int32 = 76
"""The sculk sensor redstone particle."""
comptime PARTICLE_TYPE_SPORE_BLOSSOM_SHOWER: Int32 = 77
"""The spore blossom shower particle."""
comptime PARTICLE_TYPE_SPORE_BLOSSOM_AMBIENT: Int32 = 78
"""The spore blossom ambient particle."""
comptime PARTICLE_TYPE_WAX: Int32 = 79
"""The wax particle."""
comptime PARTICLE_TYPE_ELECTRIC_SPARK: Int32 = 80
"""The electric spark particle."""
comptime PARTICLE_TYPE_CANDLE_FLAME: Int32 = 81
"""The candle flame particle."""
comptime PARTICLE_TYPE_SHRIEK: Int32 = 82
"""The shriek particle."""
comptime PARTICLE_TYPE_SCULK_SOUL: Int32 = 83
"""The sculk soul particle."""
comptime PARTICLE_TYPE_SONIC_EXPLOSION: Int32 = 84
"""The sonic explosion particle."""
comptime PARTICLE_TYPE_BRUSH_DUST: Int32 = 85
"""The brush dust particle."""
comptime PARTICLE_TYPE_CHERRY_LEAVES: Int32 = 86
"""The cherry leaves particle."""
comptime PARTICLE_TYPE_DUST_PLUME: Int32 = 87
"""The dust plume particle."""
comptime PARTICLE_TYPE_WHITE_SMOKE: Int32 = 88
"""The white smoke particle."""
comptime PARTICLE_TYPE_WIND_EXPLOSION: Int32 = 89
"""The wind explosion particle."""
comptime PARTICLE_TYPE_BREEZE_WIND_EXPLOSION: Int32 = 90
"""The breeze wind explosion particle."""
comptime PARTICLE_TYPE_VAULT_CONNECTION: Int32 = 91
"""The vault connection particle."""
comptime PARTICLE_TYPE_WOLF_ARMOUR_BREAK: Int32 = 92
"""The wolf armour break particle."""
comptime PARTICLE_TYPE_OMINOUS_ITEM_SPAWNER: Int32 = 93
"""The ominous item spawner particle."""
comptime PARTICLE_TYPE_CREAKING_CRUMBLE: Int32 = 94
"""The creaking crumble particle."""
comptime PARTICLE_TYPE_PALE_OAK_LEAVES: Int32 = 95
"""The pale oak leaves particle."""
comptime PARTICLE_TYPE_EYEBLOSSOM_OPEN: Int32 = 96
"""The eyeblossom open particle."""
comptime PARTICLE_TYPE_EYEBLOSSOM_CLOSE: Int32 = 97
"""The eyeblossom close particle."""
comptime PARTICLE_TYPE_GREEN_FLAME: Int32 = 98
"""The green flame particle."""
comptime PARTICLE_TYPE_PAUSE_MOB_GROWTH: Int32 = 99
"""The pause mob growth particle."""
comptime PARTICLE_TYPE_RESET_MOB_GROWTH: Int32 = 100
"""The reset mob growth particle."""
comptime PARTICLE_TYPE_SULFUR_CUBE: Int32 = 101
"""The sulfur cube particle."""
comptime PARTICLE_TYPE_ORANGE_POPLAR_LEAVES: Int32 = 102
"""The orange poplar leaves particle."""
comptime PARTICLE_TYPE_RED_POPLAR_LEAVES: Int32 = 103
"""The red poplar leaves particle."""
comptime PARTICLE_TYPE_YELLOW_POPLAR_LEAVES: Int32 = 104
"""The yellow poplar leaves particle."""

comptime LEVEL_EVENT_SOUND_CLICK: Int32 = 1000
"""The sound click level event."""
comptime LEVEL_EVENT_SOUND_CLICK_FAIL: Int32 = 1001
"""The sound click fail level event."""
comptime LEVEL_EVENT_SOUND_LAUNCH: Int32 = 1002
"""The sound launch level event."""
comptime LEVEL_EVENT_SOUND_OPEN_DOOR: Int32 = 1003
"""The sound open door level event."""
comptime LEVEL_EVENT_SOUND_FIZZ: Int32 = 1004
"""The sound fizz level event."""
comptime LEVEL_EVENT_SOUND_FUSE: Int32 = 1005
"""The sound fuse level event."""
comptime LEVEL_EVENT_SOUND_PLAY_RECORDING: Int32 = 1006
"""The sound play recording level event."""
comptime LEVEL_EVENT_SOUND_GHAST_WARNING: Int32 = 1007
"""The sound ghast warning level event."""
comptime LEVEL_EVENT_SOUND_GHAST_FIREBALL: Int32 = 1008
"""The sound ghast fireball level event."""
comptime LEVEL_EVENT_SOUND_BLAZE_FIREBALL: Int32 = 1009
"""The sound blaze fireball level event."""
comptime LEVEL_EVENT_SOUND_ZOMBIE_WOODEN_DOOR: Int32 = 1010
"""The sound zombie wooden door level event."""
comptime LEVEL_EVENT_SOUND_ZOMBIE_DOOR_CRASH: Int32 = 1012
"""The sound zombie door crash level event."""
comptime LEVEL_EVENT_SOUND_ZOMBIE_INFECTED: Int32 = 1016
"""The sound zombie infected level event."""
comptime LEVEL_EVENT_SOUND_ZOMBIE_CONVERTED: Int32 = 1017
"""The sound zombie converted level event."""
comptime LEVEL_EVENT_SOUND_ENDERMAN_TELEPORT: Int32 = 1018
"""The sound enderman teleport level event."""
comptime LEVEL_EVENT_SOUND_ANVIL_BROKEN: Int32 = 1020
"""The sound anvil broken level event."""
comptime LEVEL_EVENT_SOUND_ANVIL_USED: Int32 = 1021
"""The sound anvil used level event."""
comptime LEVEL_EVENT_SOUND_ANVIL_LAND: Int32 = 1022
"""The sound anvil land level event."""
comptime LEVEL_EVENT_SOUND_INFINITY_ARROW_PICKUP: Int32 = 1030
"""The sound infinity arrow pickup level event."""
comptime LEVEL_EVENT_SOUND_TELEPORT_ENDER_PEARL: Int32 = 1032
"""The sound teleport ender pearl level event."""
comptime LEVEL_EVENT_SOUND_ADD_ITEM: Int32 = 1040
"""The sound add item level event."""
comptime LEVEL_EVENT_SOUND_ITEM_FRAME_BREAK: Int32 = 1041
"""The sound item frame break level event."""
comptime LEVEL_EVENT_SOUND_ITEM_FRAME_PLACE: Int32 = 1042
"""The sound item frame place level event."""
comptime LEVEL_EVENT_SOUND_ITEM_FRAME_REMOVE_ITEM: Int32 = 1043
"""The sound item frame remove item level event."""
comptime LEVEL_EVENT_SOUND_ITEM_FRAME_ROTATE_ITEM: Int32 = 1044
"""The sound item frame rotate item level event."""
comptime LEVEL_EVENT_SOUND_EXPERIENCE_ORB_PICKUP: Int32 = 1051
"""The sound experience orb pickup level event."""
comptime LEVEL_EVENT_SOUND_TOTEM_USED: Int32 = 1052
"""The sound totem used level event."""
comptime LEVEL_EVENT_SOUND_ARMOR_STAND_BREAK: Int32 = 1060
"""The sound armor stand break level event."""
comptime LEVEL_EVENT_SOUND_ARMOR_STAND_HIT: Int32 = 1061
"""The sound armor stand hit level event."""
comptime LEVEL_EVENT_SOUND_ARMOR_STAND_LAND: Int32 = 1062
"""The sound armor stand land level event."""
comptime LEVEL_EVENT_SOUND_ARMOR_STAND_PLACE: Int32 = 1063
"""The sound armor stand place level event."""
comptime LEVEL_EVENT_SOUND_POINTED_DRIPSTONE_LAND: Int32 = 1064
"""The sound pointed dripstone land level event."""
comptime LEVEL_EVENT_SOUND_DYE_USED: Int32 = 1065
"""The sound dye used level event."""
comptime LEVEL_EVENT_SOUND_INK_SAC_USED: Int32 = 1066
"""The sound ink sac used level event."""
comptime LEVEL_EVENT_SOUND_AMETHYST_RESONATE: Int32 = 1067
"""The sound amethyst resonate level event."""
comptime LEVEL_EVENT_QUEUE_CUSTOM_MUSIC: Int32 = 1900
"""The queue custom music level event."""
comptime LEVEL_EVENT_PLAY_CUSTOM_MUSIC: Int32 = 1901
"""The play custom music level event."""
comptime LEVEL_EVENT_STOP_CUSTOM_MUSIC: Int32 = 1902
"""The stop custom music level event."""
comptime LEVEL_EVENT_SET_MUSIC_VOLUME: Int32 = 1903
"""The set music volume level event."""
comptime LEVEL_EVENT_PARTICLES_SHOOT: Int32 = 2000
"""The particles shoot level event."""
comptime LEVEL_EVENT_PARTICLES_DESTROY_BLOCK: Int32 = 2001
"""The particles destroy block level event."""
comptime LEVEL_EVENT_PARTICLES_POTION_SPLASH: Int32 = 2002
"""The particles potion splash level event."""
comptime LEVEL_EVENT_PARTICLES_EYE_OF_ENDER_DEATH: Int32 = 2003
"""The particles eye of ender death level event."""
comptime LEVEL_EVENT_PARTICLES_MOB_BLOCK_SPAWN: Int32 = 2004
"""The particles mob block spawn level event."""
comptime LEVEL_EVENT_PARTICLE_CROP_GROWTH: Int32 = 2005
"""The particle crop growth level event."""
comptime LEVEL_EVENT_PARTICLE_SOUND_GUARDIAN_GHOST: Int32 = 2006
"""The particle sound guardian ghost level event."""
comptime LEVEL_EVENT_PARTICLE_DEATH_SMOKE: Int32 = 2007
"""The particle death smoke level event."""
comptime LEVEL_EVENT_PARTICLE_DENY_BLOCK: Int32 = 2008
"""The particle deny block level event."""
comptime LEVEL_EVENT_PARTICLE_GENERIC_SPAWN: Int32 = 2009
"""The particle generic spawn level event."""
comptime LEVEL_EVENT_PARTICLES_DRAGON_EGG: Int32 = 2010
"""The particles dragon egg level event."""
comptime LEVEL_EVENT_PARTICLES_CROP_EATEN: Int32 = 2011
"""The particles crop eaten level event."""
comptime LEVEL_EVENT_PARTICLES_CRITICAL: Int32 = 2012
"""The particles critical level event."""
comptime LEVEL_EVENT_PARTICLES_TELEPORT: Int32 = 2013
"""The particles teleport level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK: Int32 = 2014
"""The particles crack block level event."""
comptime LEVEL_EVENT_PARTICLES_BUBBLE: Int32 = 2015
"""The particles bubble level event."""
comptime LEVEL_EVENT_PARTICLES_EVAPORATE: Int32 = 2016
"""The particles evaporate level event."""
comptime LEVEL_EVENT_PARTICLES_DESTROY_ARMOR_STAND: Int32 = 2017
"""The particles destroy armor stand level event."""
comptime LEVEL_EVENT_PARTICLES_BREAKING_EGG: Int32 = 2018
"""The particles breaking egg level event."""
comptime LEVEL_EVENT_PARTICLE_DESTROY_EGG: Int32 = 2019
"""The particle destroy egg level event."""
comptime LEVEL_EVENT_PARTICLES_EVAPORATE_WATER: Int32 = 2020
"""The particles evaporate water level event."""
comptime LEVEL_EVENT_PARTICLES_DESTROY_BLOCK_NO_SOUND: Int32 = 2021
"""The particles destroy block no sound level event."""
comptime LEVEL_EVENT_PARTICLES_KNOCKBACK_ROAR: Int32 = 2022
"""The particles knockback roar level event."""
comptime LEVEL_EVENT_PARTICLES_TELEPORT_TRAIL: Int32 = 2023
"""The particles teleport trail level event."""
comptime LEVEL_EVENT_PARTICLES_POINT_CLOUD: Int32 = 2024
"""The particles point cloud level event."""
comptime LEVEL_EVENT_PARTICLES_EXPLOSION: Int32 = 2025
"""The particles explosion level event."""
comptime LEVEL_EVENT_PARTICLES_BLOCK_EXPLOSION: Int32 = 2026
"""The particles block explosion level event."""
comptime LEVEL_EVENT_PARTICLES_VIBRATION_SIGNAL: Int32 = 2027
"""The particles vibration signal level event."""
comptime LEVEL_EVENT_PARTICLES_DRIPSTONE_DRIP: Int32 = 2028
"""The particles dripstone drip level event."""
comptime LEVEL_EVENT_PARTICLES_FIZZ_EFFECT: Int32 = 2029
"""The particles fizz effect level event."""
comptime LEVEL_EVENT_WAX_ON: Int32 = 2030
"""The wax on level event."""
comptime LEVEL_EVENT_WAX_OFF: Int32 = 2031
"""The wax off level event."""
comptime LEVEL_EVENT_SCRAPE: Int32 = 2032
"""The scrape level event."""
comptime LEVEL_EVENT_PARTICLES_ELECTRIC_SPARK: Int32 = 2033
"""The particles electric spark level event."""
comptime LEVEL_EVENT_PARTICLE_TURTLE_EGG: Int32 = 2034
"""The particle turtle egg level event."""
comptime LEVEL_EVENT_PARTICLE_SCULK_SHRIEK: Int32 = 2035
"""The particle sculk shriek level event."""
comptime LEVEL_EVENT_SCULK_CATALYST_BLOOM: Int32 = 2036
"""The sculk catalyst bloom level event."""
comptime LEVEL_EVENT_SCULK_CHARGE: Int32 = 2037
"""The sculk charge level event."""
comptime LEVEL_EVENT_SCULK_CHARGE_POP: Int32 = 2038
"""The sculk charge pop level event."""
comptime LEVEL_EVENT_SONIC_EXPLOSION: Int32 = 2039
"""The sonic explosion level event."""
comptime LEVEL_EVENT_DUST_PLUME: Int32 = 2040
"""The dust plume level event."""
comptime LEVEL_EVENT_START_RAINING: Int32 = 3001
"""The start raining level event."""
comptime LEVEL_EVENT_START_THUNDERSTORM: Int32 = 3002
"""The start thunderstorm level event."""
comptime LEVEL_EVENT_STOP_RAINING: Int32 = 3003
"""The stop raining level event."""
comptime LEVEL_EVENT_STOP_THUNDERSTORM: Int32 = 3004
"""The stop thunderstorm level event."""
comptime LEVEL_EVENT_GLOBAL_PAUSE: Int32 = 3005
"""The global pause level event."""
comptime LEVEL_EVENT_SIM_TIME_STEP: Int32 = 3006
"""The sim time step level event."""
comptime LEVEL_EVENT_SIM_TIME_SCALE: Int32 = 3007
"""The sim time scale level event."""
comptime LEVEL_EVENT_ACTIVATE_BLOCK: Int32 = 3500
"""The activate block level event."""
comptime LEVEL_EVENT_CAULDRON_EXPLODE: Int32 = 3501
"""The cauldron explode level event."""
comptime LEVEL_EVENT_CAULDRON_DYE_ARMOR: Int32 = 3502
"""The cauldron dye armor level event."""
comptime LEVEL_EVENT_CAULDRON_CLEAN_ARMOR: Int32 = 3503
"""The cauldron clean armor level event."""
comptime LEVEL_EVENT_CAULDRON_FILL_POTION: Int32 = 3504
"""The cauldron fill potion level event."""
comptime LEVEL_EVENT_CAULDRON_TAKE_POTION: Int32 = 3505
"""The cauldron take potion level event."""
comptime LEVEL_EVENT_CAULDRON_FILL_WATER: Int32 = 3506
"""The cauldron fill water level event."""
comptime LEVEL_EVENT_CAULDRON_TAKE_WATER: Int32 = 3507
"""The cauldron take water level event."""
comptime LEVEL_EVENT_CAULDRON_ADD_DYE: Int32 = 3508
"""The cauldron add dye level event."""
comptime LEVEL_EVENT_CAULDRON_CLEAN_BANNER: Int32 = 3509
"""The cauldron clean banner level event."""
comptime LEVEL_EVENT_CAULDRON_FLUSH: Int32 = 3510
"""The cauldron flush level event."""
comptime LEVEL_EVENT_AGENT_SPAWN_EFFECT: Int32 = 3511
"""The agent spawn effect level event."""
comptime LEVEL_EVENT_CAULDRON_FILL_LAVA: Int32 = 3512
"""The cauldron fill lava level event."""
comptime LEVEL_EVENT_CAULDRON_TAKE_LAVA: Int32 = 3513
"""The cauldron take lava level event."""
comptime LEVEL_EVENT_CAULDRON_FILL_POWDER_SNOW: Int32 = 3514
"""The cauldron fill powder snow level event."""
comptime LEVEL_EVENT_CAULDRON_TAKE_POWDER_SNOW: Int32 = 3515
"""The cauldron take powder snow level event."""
comptime LEVEL_EVENT_START_BLOCK_CRACKING: Int32 = 3600
"""The start block cracking level event."""
comptime LEVEL_EVENT_STOP_BLOCK_CRACKING: Int32 = 3601
"""The stop block cracking level event."""
comptime LEVEL_EVENT_UPDATE_BLOCK_CRACKING: Int32 = 3602
"""The update block cracking level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK_DOWN: Int32 = 3603
"""The particles crack block down level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK_UP: Int32 = 3604
"""The particles crack block up level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK_NORTH: Int32 = 3605
"""The particles crack block north level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK_SOUTH: Int32 = 3606
"""The particles crack block south level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK_WEST: Int32 = 3607
"""The particles crack block west level event."""
comptime LEVEL_EVENT_PARTICLES_CRACK_BLOCK_EAST: Int32 = 3608
"""The particles crack block east level event."""
comptime LEVEL_EVENT_PARTICLES_SHOOT_WHITE_SMOKE: Int32 = 3609
"""The particles shoot white smoke level event."""
comptime LEVEL_EVENT_PARTICLES_BREEZE_WIND_EXPLOSION: Int32 = 3610
"""The particles breeze wind explosion level event."""
comptime LEVEL_EVENT_PARTICLES_TRIAL_SPAWNER_DETECTION: Int32 = 3611
"""The particles trial spawner detection level event."""
comptime LEVEL_EVENT_PARTICLES_TRIAL_SPAWNER_SPAWNING: Int32 = 3612
"""The particles trial spawner spawning level event."""
comptime LEVEL_EVENT_PARTICLES_TRIAL_SPAWNER_EJECTING: Int32 = 3613
"""The particles trial spawner ejecting level event."""
comptime LEVEL_EVENT_PARTICLES_WIND_EXPLOSION: Int32 = 3614
"""The particles wind explosion level event."""
comptime LEVEL_EVENT_PARTICLES_TRIAL_SPAWNER_DETECTION_CHARGED: Int32 = 3615
"""The particles trial spawner detection charged level event."""
comptime LEVEL_EVENT_PARTICLES_TRIAL_SPAWNER_BECOME_CHARGED: Int32 = 3616
"""The particles trial spawner become charged level event."""
comptime LEVEL_EVENT_ALL_PLAYERS_SLEEPING: Int32 = 9800
"""The all players sleeping level event."""
comptime LEVEL_EVENT_SLEEPING_PLAYERS: Int32 = 9801
"""The sleeping players level event."""
comptime LEVEL_EVENT_JUMP_PREVENTED: Int32 = 9810
"""The jump prevented level event."""
comptime LEVEL_EVENT_ANIMATION_VAULT_ACTIVATE: Int32 = 9811
"""The animation vault activate level event."""
comptime LEVEL_EVENT_ANIMATION_VAULT_DEACTIVATE: Int32 = 9812
"""The animation vault deactivate level event."""
comptime LEVEL_EVENT_ANIMATION_VAULT_EJECT_ITEM: Int32 = 9813
"""The animation vault eject item level event."""
comptime LEVEL_EVENT_ANIMATION_SPAWN_COBWEB: Int32 = 9814
"""The animation spawn cobweb level event."""
comptime LEVEL_EVENT_PARTICLE_SMASH_ATTACK_GROUND_DUST: Int32 = 9815
"""The particle smash attack ground dust level event."""
comptime LEVEL_EVENT_PARTICLE_CREAKING_HEART_TRAIL: Int32 = 9816
"""The particle creaking heart trail level event."""
comptime LEVEL_EVENT_PARTICLE_LEGACY_EVENT: Int32 = 16384
"""The particle legacy event level event."""


struct LevelEvent(Packet):
    """Sent by the server to make a certain event in the level occur."""

    comptime ID: UInt32 = ID_LEVEL_EVENT
    """The packet ID."""
    var event_type: Int32
    """The ID of the event that is being 'called'."""
    var position: Vec3
    """The position of the level event."""
    var event_data: Int32
    """An integer holding additional data of the event."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.event_type = 0
        self.position = Vec3()
        self.event_data = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.event_type)
        vec3(io, self.position)
        io.varint32(self.event_data)
