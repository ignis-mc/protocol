"""The `LevelSoundEvent` packet (gophertunnel `packet/level_sound_event.go`)."""

from ..io import IO, optional_vec3, vec3
from ..math import Vec3
from .id import ID_LEVEL_SOUND_EVENT
from .packet import Packet

comptime SOUND_EVENT_ITEM_USE_ON: StaticString = "item.use.on"
"""The `item.use.on` sound event."""
comptime SOUND_EVENT_HIT: StaticString = "hit"
"""The `hit` sound event."""
comptime SOUND_EVENT_STEP: StaticString = "step"
"""The `step` sound event."""
comptime SOUND_EVENT_FLY: StaticString = "fly"
"""The `fly` sound event."""
comptime SOUND_EVENT_JUMP: StaticString = "jump"
"""The `jump` sound event."""
comptime SOUND_EVENT_BREAK: StaticString = "break"
"""The `break` sound event."""
comptime SOUND_EVENT_PLACE: StaticString = "place"
"""The `place` sound event."""
comptime SOUND_EVENT_HEAVY_STEP: StaticString = "heavy.step"
"""The `heavy.step` sound event."""
comptime SOUND_EVENT_GALLOP: StaticString = "gallop"
"""The `gallop` sound event."""
comptime SOUND_EVENT_FALL: StaticString = "fall"
"""The `fall` sound event."""
comptime SOUND_EVENT_AMBIENT: StaticString = "ambient"
"""The `ambient` sound event."""
comptime SOUND_EVENT_AMBIENT_BABY: StaticString = "ambient.baby"
"""The `ambient.baby` sound event."""
comptime SOUND_EVENT_AMBIENT_IN_WATER: StaticString = "ambient.in.water"
"""The `ambient.in.water` sound event."""
comptime SOUND_EVENT_BREATHE: StaticString = "breathe"
"""The `breathe` sound event."""
comptime SOUND_EVENT_DEATH: StaticString = "death"
"""The `death` sound event."""
comptime SOUND_EVENT_DEATH_IN_WATER: StaticString = "death.in.water"
"""The `death.in.water` sound event."""
comptime SOUND_EVENT_DEATH_TO_ZOMBIE: StaticString = "death.to.zombie"
"""The `death.to.zombie` sound event."""
comptime SOUND_EVENT_HURT: StaticString = "hurt"
"""The `hurt` sound event."""
comptime SOUND_EVENT_HURT_IN_WATER: StaticString = "hurt.in.water"
"""The `hurt.in.water` sound event."""
comptime SOUND_EVENT_MAD: StaticString = "mad"
"""The `mad` sound event."""
comptime SOUND_EVENT_BOOST: StaticString = "boost"
"""The `boost` sound event."""
comptime SOUND_EVENT_BOW: StaticString = "bow"
"""The `bow` sound event."""
comptime SOUND_EVENT_SQUISH_BIG: StaticString = "squish.big"
"""The `squish.big` sound event."""
comptime SOUND_EVENT_SQUISH_SMALL: StaticString = "squish.small"
"""The `squish.small` sound event."""
comptime SOUND_EVENT_FALL_BIG: StaticString = "fall.big"
"""The `fall.big` sound event."""
comptime SOUND_EVENT_FALL_SMALL: StaticString = "fall.small"
"""The `fall.small` sound event."""
comptime SOUND_EVENT_SPLASH: StaticString = "splash"
"""The `splash` sound event."""
comptime SOUND_EVENT_FIZZ: StaticString = "fizz"
"""The `fizz` sound event."""
comptime SOUND_EVENT_FLAP: StaticString = "flap"
"""The `flap` sound event."""
comptime SOUND_EVENT_SWIM: StaticString = "swim"
"""The `swim` sound event."""
comptime SOUND_EVENT_DRINK: StaticString = "drink"
"""The `drink` sound event."""
comptime SOUND_EVENT_EAT: StaticString = "eat"
"""The `eat` sound event."""
comptime SOUND_EVENT_TAKEOFF: StaticString = "takeoff"
"""The `takeoff` sound event."""
comptime SOUND_EVENT_SHAKE: StaticString = "shake"
"""The `shake` sound event."""
comptime SOUND_EVENT_PLOP: StaticString = "plop"
"""The `plop` sound event."""
comptime SOUND_EVENT_LAND: StaticString = "land"
"""The `land` sound event."""
comptime SOUND_EVENT_SADDLE: StaticString = "saddle"
"""The `saddle` sound event."""
comptime SOUND_EVENT_ARMOR: StaticString = "armor"
"""The `armor` sound event."""
comptime SOUND_EVENT_ARMOR_PLACE: StaticString = "mob.armor_stand.place"
"""The `mob.armor_stand.place` sound event."""
comptime SOUND_EVENT_ADD_CHEST: StaticString = "add.chest"
"""The `add.chest` sound event."""
comptime SOUND_EVENT_THROW: StaticString = "throw"
"""The `throw` sound event."""
comptime SOUND_EVENT_ATTACK: StaticString = "attack"
"""The `attack` sound event."""
comptime SOUND_EVENT_ATTACK_NO_DAMAGE: StaticString = "attack.nodamage"
"""The `attack.nodamage` sound event."""
comptime SOUND_EVENT_ATTACK_STRONG: StaticString = "attack.strong"
"""The `attack.strong` sound event."""
comptime SOUND_EVENT_WARN: StaticString = "warn"
"""The `warn` sound event."""
comptime SOUND_EVENT_SHEAR: StaticString = "shear"
"""The `shear` sound event."""
comptime SOUND_EVENT_MILK: StaticString = "milk"
"""The `milk` sound event."""
comptime SOUND_EVENT_THUNDER: StaticString = "thunder"
"""The `thunder` sound event."""
comptime SOUND_EVENT_EXPLODE: StaticString = "explode"
"""The `explode` sound event."""
comptime SOUND_EVENT_FIRE: StaticString = "fire"
"""The `fire` sound event."""
comptime SOUND_EVENT_IGNITE: StaticString = "ignite"
"""The `ignite` sound event."""
comptime SOUND_EVENT_FUSE: StaticString = "fuse"
"""The `fuse` sound event."""
comptime SOUND_EVENT_STARE: StaticString = "stare"
"""The `stare` sound event."""
comptime SOUND_EVENT_SPAWN: StaticString = "spawn"
"""The `spawn` sound event."""
comptime SOUND_EVENT_SHOOT: StaticString = "shoot"
"""The `shoot` sound event."""
comptime SOUND_EVENT_BREAK_BLOCK: StaticString = "break.block"
"""The `break.block` sound event."""
comptime SOUND_EVENT_LAUNCH: StaticString = "launch"
"""The `launch` sound event."""
comptime SOUND_EVENT_BLAST: StaticString = "blast"
"""The `blast` sound event."""
comptime SOUND_EVENT_LARGE_BLAST: StaticString = "large.blast"
"""The `large.blast` sound event."""
comptime SOUND_EVENT_TWINKLE: StaticString = "twinkle"
"""The `twinkle` sound event."""
comptime SOUND_EVENT_REMEDY: StaticString = "remedy"
"""The `remedy` sound event."""
comptime SOUND_EVENT_UNFECT: StaticString = "unfect"
"""The `unfect` sound event."""
comptime SOUND_EVENT_LEVEL_UP: StaticString = "levelup"
"""The `levelup` sound event."""
comptime SOUND_EVENT_BOW_HIT: StaticString = "bow.hit"
"""The `bow.hit` sound event."""
comptime SOUND_EVENT_BULLET_HIT: StaticString = "bullet.hit"
"""The `bullet.hit` sound event."""
comptime SOUND_EVENT_EXTINGUISH_FIRE: StaticString = "extinguish.fire"
"""The `extinguish.fire` sound event."""
comptime SOUND_EVENT_ITEM_FIZZ: StaticString = "item.fizz"
"""The `item.fizz` sound event."""
comptime SOUND_EVENT_CHEST_OPEN: StaticString = "chest.open"
"""The `chest.open` sound event."""
comptime SOUND_EVENT_CHEST_CLOSED: StaticString = "chest.closed"
"""The `chest.closed` sound event."""
comptime SOUND_EVENT_SHULKER_BOX_OPEN: StaticString = "shulkerbox.open"
"""The `shulkerbox.open` sound event."""
comptime SOUND_EVENT_SHULKER_BOX_CLOSED: StaticString = "shulkerbox.closed"
"""The `shulkerbox.closed` sound event."""
comptime SOUND_EVENT_ENDER_CHEST_OPEN: StaticString = "enderchest.open"
"""The `enderchest.open` sound event."""
comptime SOUND_EVENT_ENDER_CHEST_CLOSED: StaticString = "enderchest.closed"
"""The `enderchest.closed` sound event."""
comptime SOUND_EVENT_POWER_ON: StaticString = "power.on"
"""The `power.on` sound event."""
comptime SOUND_EVENT_POWER_OFF: StaticString = "power.off"
"""The `power.off` sound event."""
comptime SOUND_EVENT_ATTACH: StaticString = "attach"
"""The `attach` sound event."""
comptime SOUND_EVENT_DETACH: StaticString = "detach"
"""The `detach` sound event."""
comptime SOUND_EVENT_DENY: StaticString = "deny"
"""The `deny` sound event."""
comptime SOUND_EVENT_TRIPOD: StaticString = "tripod"
"""The `tripod` sound event."""
comptime SOUND_EVENT_POP: StaticString = "pop"
"""The `pop` sound event."""
comptime SOUND_EVENT_DROP_SLOT: StaticString = "drop.slot"
"""The `drop.slot` sound event."""
comptime SOUND_EVENT_NOTE: StaticString = "note"
"""The `note` sound event."""
comptime SOUND_EVENT_THORNS: StaticString = "thorns"
"""The `thorns` sound event."""
comptime SOUND_EVENT_PISTON_IN: StaticString = "piston.in"
"""The `piston.in` sound event."""
comptime SOUND_EVENT_PISTON_OUT: StaticString = "piston.out"
"""The `piston.out` sound event."""
comptime SOUND_EVENT_PORTAL: StaticString = "portal"
"""The `portal` sound event."""
comptime SOUND_EVENT_WATER: StaticString = "water"
"""The `water` sound event."""
comptime SOUND_EVENT_LAVA_POP: StaticString = "lava.pop"
"""The `lava.pop` sound event."""
comptime SOUND_EVENT_LAVA: StaticString = "lava"
"""The `lava` sound event."""
comptime SOUND_EVENT_BURP: StaticString = "burp"
"""The `burp` sound event."""
comptime SOUND_EVENT_BUCKET_FILL_WATER: StaticString = "bucket.fill.water"
"""The `bucket.fill.water` sound event."""
comptime SOUND_EVENT_BUCKET_FILL_LAVA: StaticString = "bucket.fill.lava"
"""The `bucket.fill.lava` sound event."""
comptime SOUND_EVENT_BUCKET_EMPTY_WATER: StaticString = "bucket.empty.water"
"""The `bucket.empty.water` sound event."""
comptime SOUND_EVENT_BUCKET_EMPTY_LAVA: StaticString = "bucket.empty.lava"
"""The `bucket.empty.lava` sound event."""
comptime SOUND_EVENT_EQUIP_CHAIN: StaticString = "armor.equip_chain"
"""The `armor.equip_chain` sound event."""
comptime SOUND_EVENT_EQUIP_DIAMOND: StaticString = "armor.equip_diamond"
"""The `armor.equip_diamond` sound event."""
comptime SOUND_EVENT_EQUIP_GENERIC: StaticString = "armor.equip_generic"
"""The `armor.equip_generic` sound event."""
comptime SOUND_EVENT_EQUIP_GOLD: StaticString = "armor.equip_gold"
"""The `armor.equip_gold` sound event."""
comptime SOUND_EVENT_EQUIP_IRON: StaticString = "armor.equip_iron"
"""The `armor.equip_iron` sound event."""
comptime SOUND_EVENT_EQUIP_LEATHER: StaticString = "armor.equip_leather"
"""The `armor.equip_leather` sound event."""
comptime SOUND_EVENT_EQUIP_ELYTRA: StaticString = "armor.equip_elytra"
"""The `armor.equip_elytra` sound event."""
comptime SOUND_EVENT_RECORD13: StaticString = "record.13"
"""The `record.13` sound event."""
comptime SOUND_EVENT_RECORD_CAT: StaticString = "record.cat"
"""The `record.cat` sound event."""
comptime SOUND_EVENT_RECORD_BLOCKS: StaticString = "record.blocks"
"""The `record.blocks` sound event."""
comptime SOUND_EVENT_RECORD_CHIRP: StaticString = "record.chirp"
"""The `record.chirp` sound event."""
comptime SOUND_EVENT_RECORD_FAR: StaticString = "record.far"
"""The `record.far` sound event."""
comptime SOUND_EVENT_RECORD_MALL: StaticString = "record.mall"
"""The `record.mall` sound event."""
comptime SOUND_EVENT_RECORD_MELLOHI: StaticString = "record.mellohi"
"""The `record.mellohi` sound event."""
comptime SOUND_EVENT_RECORD_STAL: StaticString = "record.stal"
"""The `record.stal` sound event."""
comptime SOUND_EVENT_RECORD_STRAD: StaticString = "record.strad"
"""The `record.strad` sound event."""
comptime SOUND_EVENT_RECORD_WARD: StaticString = "record.ward"
"""The `record.ward` sound event."""
comptime SOUND_EVENT_RECORD11: StaticString = "record.11"
"""The `record.11` sound event."""
comptime SOUND_EVENT_RECORD_WAIT: StaticString = "record.wait"
"""The `record.wait` sound event."""
comptime SOUND_EVENT_RECORD_NULL: StaticString = "record.null"
"""The `record.null` sound event."""
comptime SOUND_EVENT_FLOP: StaticString = "flop"
"""The `flop` sound event."""
comptime SOUND_EVENT_GUARDIAN_CURSE: StaticString = "elderguardian.curse"
"""The `elderguardian.curse` sound event."""
comptime SOUND_EVENT_MOB_WARNING: StaticString = "mob.warning"
"""The `mob.warning` sound event."""
comptime SOUND_EVENT_MOB_WARNING_BABY: StaticString = "mob.warning.baby"
"""The `mob.warning.baby` sound event."""
comptime SOUND_EVENT_TELEPORT: StaticString = "teleport"
"""The `teleport` sound event."""
comptime SOUND_EVENT_SHULKER_OPEN: StaticString = "shulker.open"
"""The `shulker.open` sound event."""
comptime SOUND_EVENT_SHULKER_CLOSE: StaticString = "shulker.close"
"""The `shulker.close` sound event."""
comptime SOUND_EVENT_HAGGLE: StaticString = "haggle"
"""The `haggle` sound event."""
comptime SOUND_EVENT_HAGGLE_YES: StaticString = "haggle.yes"
"""The `haggle.yes` sound event."""
comptime SOUND_EVENT_HAGGLE_NO: StaticString = "haggle.no"
"""The `haggle.no` sound event."""
comptime SOUND_EVENT_HAGGLE_IDLE: StaticString = "haggle.idle"
"""The `haggle.idle` sound event."""
comptime SOUND_EVENT_CHORUS_GROW: StaticString = "chorusgrow"
"""The `chorusgrow` sound event."""
comptime SOUND_EVENT_CHORUS_DEATH: StaticString = "chorusdeath"
"""The `chorusdeath` sound event."""
comptime SOUND_EVENT_GLASS: StaticString = "glass"
"""The `glass` sound event."""
comptime SOUND_EVENT_POTION_BREWED: StaticString = "potion.brewed"
"""The `potion.brewed` sound event."""
comptime SOUND_EVENT_CAST_SPELL: StaticString = "cast.spell"
"""The `cast.spell` sound event."""
comptime SOUND_EVENT_PREPARE_ATTACK_SPELL: StaticString = "prepare.attack"
"""The `prepare.attack` sound event."""
comptime SOUND_EVENT_PREPARE_SUMMON: StaticString = "prepare.summon"
"""The `prepare.summon` sound event."""
comptime SOUND_EVENT_PREPARE_WOLOLO: StaticString = "prepare.wololo"
"""The `prepare.wololo` sound event."""
comptime SOUND_EVENT_FANG: StaticString = "fang"
"""The `fang` sound event."""
comptime SOUND_EVENT_CHARGE: StaticString = "charge"
"""The `charge` sound event."""
comptime SOUND_EVENT_TAKE_PICTURE: StaticString = "camera.take_picture"
"""The `camera.take_picture` sound event."""
comptime SOUND_EVENT_PLACE_LEASH_KNOT: StaticString = "leashknot.place"
"""The `leashknot.place` sound event."""
comptime SOUND_EVENT_BREAK_LEASH_KNOT: StaticString = "leashknot.break"
"""The `leashknot.break` sound event."""
comptime SOUND_EVENT_AMBIENT_GROWL: StaticString = "growl"
"""The `growl` sound event."""
comptime SOUND_EVENT_AMBIENT_WHINE: StaticString = "whine"
"""The `whine` sound event."""
comptime SOUND_EVENT_AMBIENT_PANT: StaticString = "pant"
"""The `pant` sound event."""
comptime SOUND_EVENT_AMBIENT_PURR: StaticString = "purr"
"""The `purr` sound event."""
comptime SOUND_EVENT_AMBIENT_PURREOW: StaticString = "purreow"
"""The `purreow` sound event."""
comptime SOUND_EVENT_DEATH_MIN_VOLUME: StaticString = "death.min.volume"
"""The `death.min.volume` sound event."""
comptime SOUND_EVENT_DEATH_MID_VOLUME: StaticString = "death.mid.volume"
"""The `death.mid.volume` sound event."""
comptime SOUND_EVENT_IMITATE_BLAZE: StaticString = "imitate.blaze"
"""The `imitate.blaze` sound event."""
comptime SOUND_EVENT_IMITATE_CAVE_SPIDER: StaticString = "imitate.cave_spider"
"""The `imitate.cave_spider` sound event."""
comptime SOUND_EVENT_IMITATE_CREEPER: StaticString = "imitate.creeper"
"""The `imitate.creeper` sound event."""
comptime SOUND_EVENT_IMITATE_ELDER_GUARDIAN: StaticString = (
    "imitate.elder_guardian"
)
"""The `imitate.elder_guardian` sound event."""
comptime SOUND_EVENT_IMITATE_ENDER_DRAGON: StaticString = "imitate.ender_dragon"
"""The `imitate.ender_dragon` sound event."""
comptime SOUND_EVENT_IMITATE_ENDERMAN: StaticString = "imitate.enderman"
"""The `imitate.enderman` sound event."""
comptime SOUND_EVENT_IMITATE_ENDERMITE: StaticString = "imitate.endermite"
"""The `imitate.endermite` sound event."""
comptime SOUND_EVENT_IMITATE_EVOCATION_ILLAGER: StaticString = (
    "imitate.evocation_illager"
)
"""The `imitate.evocation_illager` sound event."""
comptime SOUND_EVENT_IMITATE_GHAST: StaticString = "imitate.ghast"
"""The `imitate.ghast` sound event."""
comptime SOUND_EVENT_IMITATE_HUSK: StaticString = "imitate.husk"
"""The `imitate.husk` sound event."""
comptime SOUND_EVENT_IMITATE_ILLUSION_ILLAGER: StaticString = (
    "imitate.illusion_illager"
)
"""The `imitate.illusion_illager` sound event."""
comptime SOUND_EVENT_IMITATE_MAGMA_CUBE: StaticString = "imitate.magma_cube"
"""The `imitate.magma_cube` sound event."""
comptime SOUND_EVENT_IMITATE_POLAR_BEAR: StaticString = "imitate.polar_bear"
"""The `imitate.polar_bear` sound event."""
comptime SOUND_EVENT_IMITATE_SHULKER: StaticString = "imitate.shulker"
"""The `imitate.shulker` sound event."""
comptime SOUND_EVENT_IMITATE_SILVERFISH: StaticString = "imitate.silverfish"
"""The `imitate.silverfish` sound event."""
comptime SOUND_EVENT_IMITATE_SKELETON: StaticString = "imitate.skeleton"
"""The `imitate.skeleton` sound event."""
comptime SOUND_EVENT_IMITATE_SLIME: StaticString = "imitate.slime"
"""The `imitate.slime` sound event."""
comptime SOUND_EVENT_IMITATE_SPIDER: StaticString = "imitate.spider"
"""The `imitate.spider` sound event."""
comptime SOUND_EVENT_IMITATE_STRAY: StaticString = "imitate.stray"
"""The `imitate.stray` sound event."""
comptime SOUND_EVENT_IMITATE_VEX: StaticString = "imitate.vex"
"""The `imitate.vex` sound event."""
comptime SOUND_EVENT_IMITATE_VINDICATION_ILLAGER: StaticString = (
    "imitate.vindication_illager"
)
"""The `imitate.vindication_illager` sound event."""
comptime SOUND_EVENT_IMITATE_WITCH: StaticString = "imitate.witch"
"""The `imitate.witch` sound event."""
comptime SOUND_EVENT_IMITATE_WITHER: StaticString = "imitate.wither"
"""The `imitate.wither` sound event."""
comptime SOUND_EVENT_IMITATE_WITHER_SKELETON: StaticString = (
    "imitate.wither_skeleton"
)
"""The `imitate.wither_skeleton` sound event."""
comptime SOUND_EVENT_IMITATE_WOLF: StaticString = "imitate.wolf"
"""The `imitate.wolf` sound event."""
comptime SOUND_EVENT_IMITATE_ZOMBIE: StaticString = "imitate.zombie"
"""The `imitate.zombie` sound event."""
comptime SOUND_EVENT_IMITATE_ZOMBIE_PIGMAN: StaticString = (
    "imitate.zombie_pigman"
)
"""The `imitate.zombie_pigman` sound event."""
comptime SOUND_EVENT_IMITATE_ZOMBIE_VILLAGER: StaticString = (
    "imitate.zombie_villager"
)
"""The `imitate.zombie_villager` sound event."""
comptime SOUND_EVENT_ENDER_EYE_PLACED: StaticString = (
    "block.end_portal_frame.fill"
)
"""The `block.end_portal_frame.fill` sound event."""
comptime SOUND_EVENT_END_PORTAL_CREATED: StaticString = "block.end_portal.spawn"
"""The `block.end_portal.spawn` sound event."""
comptime SOUND_EVENT_ANVIL_USE: StaticString = "random.anvil_use"
"""The `random.anvil_use` sound event."""
comptime SOUND_EVENT_BOTTLE_DRAGON_BREATH: StaticString = "bottle.dragonbreath"
"""The `bottle.dragonbreath` sound event."""
comptime SOUND_EVENT_PORTAL_TRAVEL: StaticString = "portal.travel"
"""The `portal.travel` sound event."""
comptime SOUND_EVENT_TRIDENT_HIT: StaticString = "item.trident.hit"
"""The `item.trident.hit` sound event."""
comptime SOUND_EVENT_TRIDENT_RETURN: StaticString = "item.trident.return"
"""The `item.trident.return` sound event."""
comptime SOUND_EVENT_TRIDENT_RIPTIDE1: StaticString = "item.trident.riptide_1"
"""The `item.trident.riptide_1` sound event."""
comptime SOUND_EVENT_TRIDENT_RIPTIDE2: StaticString = "item.trident.riptide_2"
"""The `item.trident.riptide_2` sound event."""
comptime SOUND_EVENT_TRIDENT_RIPTIDE3: StaticString = "item.trident.riptide_3"
"""The `item.trident.riptide_3` sound event."""
comptime SOUND_EVENT_TRIDENT_THROW: StaticString = "item.trident.throw"
"""The `item.trident.throw` sound event."""
comptime SOUND_EVENT_TRIDENT_THUNDER: StaticString = "item.trident.thunder"
"""The `item.trident.thunder` sound event."""
comptime SOUND_EVENT_TRIDENT_HIT_GROUND: StaticString = (
    "item.trident.hit_ground"
)
"""The `item.trident.hit_ground` sound event."""
comptime SOUND_EVENT_DEFAULT: StaticString = "default"
"""The `default` sound event."""
comptime SOUND_EVENT_FLETCHING_TABLE_USE: StaticString = (
    "block.fletching_table.use"
)
"""The `block.fletching_table.use` sound event."""
comptime SOUND_EVENT_ELEM_CONSTRUCT_OPEN: StaticString = "elemconstruct.open"
"""The `elemconstruct.open` sound event."""
comptime SOUND_EVENT_ICE_BOMB_HIT: StaticString = "icebomb.hit"
"""The `icebomb.hit` sound event."""
comptime SOUND_EVENT_BALLOON_POP: StaticString = "balloonpop"
"""The `balloonpop` sound event."""
comptime SOUND_EVENT_LT_REACTION_ICE_BOMB: StaticString = "lt.reaction.icebomb"
"""The `lt.reaction.icebomb` sound event."""
comptime SOUND_EVENT_LT_REACTION_BLEACH: StaticString = "lt.reaction.bleach"
"""The `lt.reaction.bleach` sound event."""
comptime SOUND_EVENT_LT_REACTION_ELEPHANT_TOOTHPASTE: StaticString = (
    "lt.reaction.epaste"
)
"""The `lt.reaction.epaste` sound event."""
comptime SOUND_EVENT_LT_REACTION_ELEPHANT_TOOTHPASTE2: StaticString = (
    "lt.reaction.epaste2"
)
"""The `lt.reaction.epaste2` sound event."""
comptime SOUND_EVENT_LT_REACTION_GLOW_STICK: StaticString = (
    "lt.reaction.glow_stick"
)
"""The `lt.reaction.glow_stick` sound event."""
comptime SOUND_EVENT_LT_REACTION_GLOW_STICK2: StaticString = (
    "lt.reaction.glow_stick2"
)
"""The `lt.reaction.glow_stick2` sound event."""
comptime SOUND_EVENT_LT_REACTION_LUMINOL: StaticString = "lt.reaction.luminol"
"""The `lt.reaction.luminol` sound event."""
comptime SOUND_EVENT_LT_REACTION_SALT: StaticString = "lt.reaction.salt"
"""The `lt.reaction.salt` sound event."""
comptime SOUND_EVENT_LT_REACTION_FERTILIZER: StaticString = (
    "lt.reaction.fertilizer"
)
"""The `lt.reaction.fertilizer` sound event."""
comptime SOUND_EVENT_LT_REACTION_FIREBALL: StaticString = "lt.reaction.fireball"
"""The `lt.reaction.fireball` sound event."""
comptime SOUND_EVENT_LT_REACTION_MAGNESIUM_SALT: StaticString = (
    "lt.reaction.mgsalt"
)
"""The `lt.reaction.mgsalt` sound event."""
comptime SOUND_EVENT_LT_REACTION_MISC_FIRE: StaticString = (
    "lt.reaction.miscfire"
)
"""The `lt.reaction.miscfire` sound event."""
comptime SOUND_EVENT_LT_REACTION_FIRE: StaticString = "lt.reaction.fire"
"""The `lt.reaction.fire` sound event."""
comptime SOUND_EVENT_LT_REACTION_MISC_EXPLOSION: StaticString = (
    "lt.reaction.miscexplosion"
)
"""The `lt.reaction.miscexplosion` sound event."""
comptime SOUND_EVENT_LT_REACTION_MISC_MYSTICAL: StaticString = (
    "lt.reaction.miscmystical"
)
"""The `lt.reaction.miscmystical` sound event."""
comptime SOUND_EVENT_LT_REACTION_MISC_MYSTICAL2: StaticString = (
    "lt.reaction.miscmystical2"
)
"""The `lt.reaction.miscmystical2` sound event."""
comptime SOUND_EVENT_LT_REACTION_PRODUCT: StaticString = "lt.reaction.product"
"""The `lt.reaction.product` sound event."""
comptime SOUND_EVENT_SPARKLER_USE: StaticString = "sparkler.use"
"""The `sparkler.use` sound event."""
comptime SOUND_EVENT_GLOW_STICK_USE: StaticString = "glowstick.use"
"""The `glowstick.use` sound event."""
comptime SOUND_EVENT_SPARKLER_ACTIVE: StaticString = "sparkler.active"
"""The `sparkler.active` sound event."""
comptime SOUND_EVENT_CONVERT_TO_DROWNED: StaticString = "convert_to_drowned"
"""The `convert_to_drowned` sound event."""
comptime SOUND_EVENT_BUCKET_FILL_FISH: StaticString = "bucket.fill.fish"
"""The `bucket.fill.fish` sound event."""
comptime SOUND_EVENT_BUCKET_EMPTY_FISH: StaticString = "bucket.empty.fish"
"""The `bucket.empty.fish` sound event."""
comptime SOUND_EVENT_BUBBLE_COLUMN_UPWARDS: StaticString = "bubble.up"
"""The `bubble.up` sound event."""
comptime SOUND_EVENT_BUBBLE_COLUMN_DOWNWARDS: StaticString = "bubble.down"
"""The `bubble.down` sound event."""
comptime SOUND_EVENT_BUBBLE_POP: StaticString = "bubble.pop"
"""The `bubble.pop` sound event."""
comptime SOUND_EVENT_BUBBLE_UP_INSIDE: StaticString = "bubble.upinside"
"""The `bubble.upinside` sound event."""
comptime SOUND_EVENT_BUBBLE_DOWN_INSIDE: StaticString = "bubble.downinside"
"""The `bubble.downinside` sound event."""
comptime SOUND_EVENT_HURT_BABY: StaticString = "hurt.baby"
"""The `hurt.baby` sound event."""
comptime SOUND_EVENT_DEATH_BABY: StaticString = "death.baby"
"""The `death.baby` sound event."""
comptime SOUND_EVENT_STEP_BABY: StaticString = "step.baby"
"""The `step.baby` sound event."""
comptime SOUND_EVENT_SPAWN_BABY: StaticString = "spawn.baby"
"""The `spawn.baby` sound event."""
comptime SOUND_EVENT_BORN: StaticString = "born"
"""The `born` sound event."""
comptime SOUND_EVENT_TURTLE_EGG_BREAK: StaticString = "block.turtle_egg.break"
"""The `block.turtle_egg.break` sound event."""
comptime SOUND_EVENT_TURTLE_EGG_CRACK: StaticString = "block.turtle_egg.crack"
"""The `block.turtle_egg.crack` sound event."""
comptime SOUND_EVENT_TURTLE_EGG_HATCHED: StaticString = "block.turtle_egg.hatch"
"""The `block.turtle_egg.hatch` sound event."""
comptime SOUND_EVENT_LAY_EGG: StaticString = "lay_egg"
"""The `lay_egg` sound event."""
comptime SOUND_EVENT_TURTLE_EGG_ATTACKED: StaticString = (
    "block.turtle_egg.attack"
)
"""The `block.turtle_egg.attack` sound event."""
comptime SOUND_EVENT_BEACON_ACTIVATE: StaticString = "beacon.activate"
"""The `beacon.activate` sound event."""
comptime SOUND_EVENT_BEACON_AMBIENT: StaticString = "beacon.ambient"
"""The `beacon.ambient` sound event."""
comptime SOUND_EVENT_BEACON_DEACTIVATE: StaticString = "beacon.deactivate"
"""The `beacon.deactivate` sound event."""
comptime SOUND_EVENT_BEACON_POWER: StaticString = "beacon.power"
"""The `beacon.power` sound event."""
comptime SOUND_EVENT_CONDUIT_ACTIVATE: StaticString = "conduit.activate"
"""The `conduit.activate` sound event."""
comptime SOUND_EVENT_CONDUIT_AMBIENT: StaticString = "conduit.ambient"
"""The `conduit.ambient` sound event."""
comptime SOUND_EVENT_CONDUIT_ATTACK: StaticString = "conduit.attack"
"""The `conduit.attack` sound event."""
comptime SOUND_EVENT_CONDUIT_DEACTIVATE: StaticString = "conduit.deactivate"
"""The `conduit.deactivate` sound event."""
comptime SOUND_EVENT_CONDUIT_SHORT: StaticString = "conduit.short"
"""The `conduit.short` sound event."""
comptime SOUND_EVENT_SWOOP: StaticString = "swoop"
"""The `swoop` sound event."""
comptime SOUND_EVENT_BAMBOO_SAPLING_PLACE: StaticString = (
    "block.bamboo_sapling.place"
)
"""The `block.bamboo_sapling.place` sound event."""
comptime SOUND_EVENT_PRE_SNEEZE: StaticString = "presneeze"
"""The `presneeze` sound event."""
comptime SOUND_EVENT_SNEEZE: StaticString = "sneeze"
"""The `sneeze` sound event."""
comptime SOUND_EVENT_AMBIENT_TAME: StaticString = "ambient.tame"
"""The `ambient.tame` sound event."""
comptime SOUND_EVENT_SCARED: StaticString = "scared"
"""The `scared` sound event."""
comptime SOUND_EVENT_SCAFFOLDING_CLIMB: StaticString = "block.scaffolding.climb"
"""The `block.scaffolding.climb` sound event."""
comptime SOUND_EVENT_CROSSBOW_LOADING_START: StaticString = (
    "crossbow.loading.start"
)
"""The `crossbow.loading.start` sound event."""
comptime SOUND_EVENT_CROSSBOW_LOADING_MIDDLE: StaticString = (
    "crossbow.loading.middle"
)
"""The `crossbow.loading.middle` sound event."""
comptime SOUND_EVENT_CROSSBOW_LOADING_END: StaticString = "crossbow.loading.end"
"""The `crossbow.loading.end` sound event."""
comptime SOUND_EVENT_CROSSBOW_SHOOT: StaticString = "crossbow.shoot"
"""The `crossbow.shoot` sound event."""
comptime SOUND_EVENT_CROSSBOW_QUICK_CHARGE_START: StaticString = (
    "crossbow.quick_charge.start"
)
"""The `crossbow.quick_charge.start` sound event."""
comptime SOUND_EVENT_CROSSBOW_QUICK_CHARGE_MIDDLE: StaticString = (
    "crossbow.quick_charge.middle"
)
"""The `crossbow.quick_charge.middle` sound event."""
comptime SOUND_EVENT_CROSSBOW_QUICK_CHARGE_END: StaticString = (
    "crossbow.quick_charge.end"
)
"""The `crossbow.quick_charge.end` sound event."""
comptime SOUND_EVENT_AMBIENT_AGGRESSIVE: StaticString = "ambient.aggressive"
"""The `ambient.aggressive` sound event."""
comptime SOUND_EVENT_AMBIENT_WORRIED: StaticString = "ambient.worried"
"""The `ambient.worried` sound event."""
comptime SOUND_EVENT_CANT_BREED: StaticString = "cant_breed"
"""The `cant_breed` sound event."""
comptime SOUND_EVENT_SHIELD_BLOCK: StaticString = "item.shield.block"
"""The `item.shield.block` sound event."""
comptime SOUND_EVENT_LECTERN_BOOK_PLACE: StaticString = "item.book.put"
"""The `item.book.put` sound event."""
comptime SOUND_EVENT_GRINDSTONE_USE: StaticString = "block.grindstone.use"
"""The `block.grindstone.use` sound event."""
comptime SOUND_EVENT_BELL: StaticString = "block.bell.hit"
"""The `block.bell.hit` sound event."""
comptime SOUND_EVENT_CAMPFIRE_CRACKLE: StaticString = "block.campfire.crackle"
"""The `block.campfire.crackle` sound event."""
comptime SOUND_EVENT_ROAR: StaticString = "roar"
"""The `roar` sound event."""
comptime SOUND_EVENT_STUN: StaticString = "stun"
"""The `stun` sound event."""
comptime SOUND_EVENT_SWEET_BERRY_BUSH_HURT: StaticString = (
    "block.sweet_berry_bush.hurt"
)
"""The `block.sweet_berry_bush.hurt` sound event."""
comptime SOUND_EVENT_SWEET_BERRY_BUSH_PICK: StaticString = (
    "block.sweet_berry_bush.pick"
)
"""The `block.sweet_berry_bush.pick` sound event."""
comptime SOUND_EVENT_CARTOGRAPHY_TABLE_USE: StaticString = (
    "block.cartography_table.use"
)
"""The `block.cartography_table.use` sound event."""
comptime SOUND_EVENT_STONECUTTER_USE: StaticString = "block.stonecutter.use"
"""The `block.stonecutter.use` sound event."""
comptime SOUND_EVENT_COMPOSTER_EMPTY: StaticString = "block.composter.empty"
"""The `block.composter.empty` sound event."""
comptime SOUND_EVENT_COMPOSTER_FILL: StaticString = "block.composter.fill"
"""The `block.composter.fill` sound event."""
comptime SOUND_EVENT_COMPOSTER_FILL_LAYER: StaticString = (
    "block.composter.fill_success"
)
"""The `block.composter.fill_success` sound event."""
comptime SOUND_EVENT_COMPOSTER_READY: StaticString = "block.composter.ready"
"""The `block.composter.ready` sound event."""
comptime SOUND_EVENT_BARREL_OPEN: StaticString = "block.barrel.open"
"""The `block.barrel.open` sound event."""
comptime SOUND_EVENT_BARREL_CLOSE: StaticString = "block.barrel.close"
"""The `block.barrel.close` sound event."""
comptime SOUND_EVENT_RAID_HORN: StaticString = "raid.horn"
"""The `raid.horn` sound event."""
comptime SOUND_EVENT_LOOM_USE: StaticString = "block.loom.use"
"""The `block.loom.use` sound event."""
comptime SOUND_EVENT_AMBIENT_IN_RAID: StaticString = "ambient.in.raid"
"""The `ambient.in.raid` sound event."""
comptime SOUND_EVENT_UICARTOGRAPHY_TABLE_USE: StaticString = (
    "ui.cartography_table.take_result"
)
"""The `ui.cartography_table.take_result` sound event."""
comptime SOUND_EVENT_UISTONECUTTER_USE: StaticString = (
    "ui.stonecutter.take_result"
)
"""The `ui.stonecutter.take_result` sound event."""
comptime SOUND_EVENT_UILOOM_USE: StaticString = "ui.loom.take_result"
"""The `ui.loom.take_result` sound event."""
comptime SOUND_EVENT_SMOKER_USE: StaticString = "block.smoker.smoke"
"""The `block.smoker.smoke` sound event."""
comptime SOUND_EVENT_BLAST_FURNACE_USE: StaticString = (
    "block.blastfurnace.fire_crackle"
)
"""The `block.blastfurnace.fire_crackle` sound event."""
comptime SOUND_EVENT_SMITHING_TABLE_USE: StaticString = (
    "block.smithing_table.use"
)
"""The `block.smithing_table.use` sound event."""
comptime SOUND_EVENT_SCREECH: StaticString = "screech"
"""The `screech` sound event."""
comptime SOUND_EVENT_SLEEP: StaticString = "sleep"
"""The `sleep` sound event."""
comptime SOUND_EVENT_FURNACE_USE: StaticString = "block.furnace.lit"
"""The `block.furnace.lit` sound event."""
comptime SOUND_EVENT_MOOSHROOM_CONVERT: StaticString = "convert_mooshroom"
"""The `convert_mooshroom` sound event."""
comptime SOUND_EVENT_MILK_SUSPICIOUSLY: StaticString = "milk_suspiciously"
"""The `milk_suspiciously` sound event."""
comptime SOUND_EVENT_CELEBRATE: StaticString = "celebrate"
"""The `celebrate` sound event."""
comptime SOUND_EVENT_JUMP_PREVENT: StaticString = "jump.prevent"
"""The `jump.prevent` sound event."""
comptime SOUND_EVENT_AMBIENT_POLLINATE: StaticString = "ambient.pollinate"
"""The `ambient.pollinate` sound event."""
comptime SOUND_EVENT_BEEHIVE_DRIP: StaticString = "block.beehive.drip"
"""The `block.beehive.drip` sound event."""
comptime SOUND_EVENT_BEEHIVE_ENTER: StaticString = "block.beehive.enter"
"""The `block.beehive.enter` sound event."""
comptime SOUND_EVENT_BEEHIVE_EXIT: StaticString = "block.beehive.exit"
"""The `block.beehive.exit` sound event."""
comptime SOUND_EVENT_BEEHIVE_WORK: StaticString = "block.beehive.work"
"""The `block.beehive.work` sound event."""
comptime SOUND_EVENT_BEEHIVE_SHEAR: StaticString = "block.beehive.shear"
"""The `block.beehive.shear` sound event."""
comptime SOUND_EVENT_HONEYBOTTLE_DRINK: StaticString = "drink.honey"
"""The `drink.honey` sound event."""
comptime SOUND_EVENT_AMBIENT_CAVE: StaticString = "ambient.cave"
"""The `ambient.cave` sound event."""
comptime SOUND_EVENT_RETREAT: StaticString = "retreat"
"""The `retreat` sound event."""
comptime SOUND_EVENT_CONVERT_TO_ZOMBIFIED: StaticString = (
    "converted_to_zombified"
)
"""The `converted_to_zombified` sound event."""
comptime SOUND_EVENT_ADMIRE: StaticString = "admire"
"""The `admire` sound event."""
comptime SOUND_EVENT_STEP_LAVA: StaticString = "step_lava"
"""The `step_lava` sound event."""
comptime SOUND_EVENT_TEMPT: StaticString = "tempt"
"""The `tempt` sound event."""
comptime SOUND_EVENT_PANIC: StaticString = "panic"
"""The `panic` sound event."""
comptime SOUND_EVENT_ANGRY: StaticString = "angry"
"""The `angry` sound event."""
comptime SOUND_EVENT_AMBIENT_MOOD_WARPED_FOREST: StaticString = (
    "ambient.warped_forest.mood"
)
"""The `ambient.warped_forest.mood` sound event."""
comptime SOUND_EVENT_AMBIENT_MOOD_SOULSAND_VALLEY: StaticString = (
    "ambient.soulsand_valley.mood"
)
"""The `ambient.soulsand_valley.mood` sound event."""
comptime SOUND_EVENT_AMBIENT_MOOD_NETHER_WASTES: StaticString = (
    "ambient.nether_wastes.mood"
)
"""The `ambient.nether_wastes.mood` sound event."""
comptime SOUND_EVENT_AMBIENT_MOOD_BASALT_DELTAS: StaticString = (
    "ambient.basalt_deltas.mood"
)
"""The `ambient.basalt_deltas.mood` sound event."""
comptime SOUND_EVENT_AMBIENT_MOOD_CRIMSON_FOREST: StaticString = (
    "ambient.crimson_forest.mood"
)
"""The `ambient.crimson_forest.mood` sound event."""
comptime SOUND_EVENT_RESPAWN_ANCHOR_CHARGE: StaticString = (
    "respawn_anchor.charge"
)
"""The `respawn_anchor.charge` sound event."""
comptime SOUND_EVENT_RESPAWN_ANCHOR_DEPLETE: StaticString = (
    "respawn_anchor.deplete"
)
"""The `respawn_anchor.deplete` sound event."""
comptime SOUND_EVENT_RESPAWN_ANCHOR_SET_SPAWN: StaticString = (
    "respawn_anchor.set_spawn"
)
"""The `respawn_anchor.set_spawn` sound event."""
comptime SOUND_EVENT_RESPAWN_ANCHOR_AMBIENT: StaticString = (
    "respawn_anchor.ambient"
)
"""The `respawn_anchor.ambient` sound event."""
comptime SOUND_EVENT_SOUL_ESCAPE_QUIET: StaticString = (
    "particle.soul_escape.quiet"
)
"""The `particle.soul_escape.quiet` sound event."""
comptime SOUND_EVENT_SOUL_ESCAPE_LOUD: StaticString = (
    "particle.soul_escape.loud"
)
"""The `particle.soul_escape.loud` sound event."""
comptime SOUND_EVENT_RECORD_PIGSTEP: StaticString = "record.pigstep"
"""The `record.pigstep` sound event."""
comptime SOUND_EVENT_LINK_COMPASS_TO_LODESTONE: StaticString = (
    "lodestone_compass.link_compass_to_lodestone"
)
"""The `lodestone_compass.link_compass_to_lodestone` sound event."""
comptime SOUND_EVENT_USE_SMITHING_TABLE: StaticString = "smithing_table.use"
"""The `smithing_table.use` sound event."""
comptime SOUND_EVENT_EQUIP_NETHERITE: StaticString = "armor.equip_netherite"
"""The `armor.equip_netherite` sound event."""
comptime SOUND_EVENT_AMBIENT_LOOP_WARPED_FOREST: StaticString = (
    "ambient.warped_forest.loop"
)
"""The `ambient.warped_forest.loop` sound event."""
comptime SOUND_EVENT_AMBIENT_LOOP_SOULSAND_VALLEY: StaticString = (
    "ambient.soulsand_valley.loop"
)
"""The `ambient.soulsand_valley.loop` sound event."""
comptime SOUND_EVENT_AMBIENT_LOOP_NETHER_WASTES: StaticString = (
    "ambient.nether_wastes.loop"
)
"""The `ambient.nether_wastes.loop` sound event."""
comptime SOUND_EVENT_AMBIENT_LOOP_BASALT_DELTAS: StaticString = (
    "ambient.basalt_deltas.loop"
)
"""The `ambient.basalt_deltas.loop` sound event."""
comptime SOUND_EVENT_AMBIENT_LOOP_CRIMSON_FOREST: StaticString = (
    "ambient.crimson_forest.loop"
)
"""The `ambient.crimson_forest.loop` sound event."""
comptime SOUND_EVENT_AMBIENT_ADDITION_WARPED_FOREST: StaticString = (
    "ambient.warped_forest.additions"
)
"""The `ambient.warped_forest.additions` sound event."""
comptime SOUND_EVENT_AMBIENT_ADDITION_SOULSAND_VALLEY: StaticString = (
    "ambient.soulsand_valley.additions"
)
"""The `ambient.soulsand_valley.additions` sound event."""
comptime SOUND_EVENT_AMBIENT_ADDITION_NETHER_WASTES: StaticString = (
    "ambient.nether_wastes.additions"
)
"""The `ambient.nether_wastes.additions` sound event."""
comptime SOUND_EVENT_AMBIENT_ADDITION_BASALT_DELTAS: StaticString = (
    "ambient.basalt_deltas.additions"
)
"""The `ambient.basalt_deltas.additions` sound event."""
comptime SOUND_EVENT_AMBIENT_ADDITION_CRIMSON_FOREST: StaticString = (
    "ambient.crimson_forest.additions"
)
"""The `ambient.crimson_forest.additions` sound event."""
comptime SOUND_EVENT_SCULK_SENSOR_POWER_ON: StaticString = (
    "power.on.sculk_sensor"
)
"""The `power.on.sculk_sensor` sound event."""
comptime SOUND_EVENT_SCULK_SENSOR_POWER_OFF: StaticString = (
    "power.off.sculk_sensor"
)
"""The `power.off.sculk_sensor` sound event."""
comptime SOUND_EVENT_BUCKET_FILL_POWDER_SNOW: StaticString = (
    "bucket.fill.powder_snow"
)
"""The `bucket.fill.powder_snow` sound event."""
comptime SOUND_EVENT_BUCKET_EMPTY_POWDER_SNOW: StaticString = (
    "bucket.empty.powder_snow"
)
"""The `bucket.empty.powder_snow` sound event."""
comptime SOUND_EVENT_POINTED_DRIPSTONE_CAULDRON_DRIP_WATER: StaticString = (
    "cauldron_drip.water.pointed_dripstone"
)
"""The `cauldron_drip.water.pointed_dripstone` sound event."""
comptime SOUND_EVENT_POINTED_DRIPSTONE_CAULDRON_DRIP_LAVA: StaticString = (
    "cauldron_drip.lava.pointed_dripstone"
)
"""The `cauldron_drip.lava.pointed_dripstone` sound event."""
comptime SOUND_EVENT_POINTED_DRIPSTONE_DRIP_WATER: StaticString = (
    "drip.water.pointed_dripstone"
)
"""The `drip.water.pointed_dripstone` sound event."""
comptime SOUND_EVENT_POINTED_DRIPSTONE_DRIP_LAVA: StaticString = (
    "drip.lava.pointed_dripstone"
)
"""The `drip.lava.pointed_dripstone` sound event."""
comptime SOUND_EVENT_CAVE_VINES_PICK_BERRIES: StaticString = (
    "pick_berries.cave_vines"
)
"""The `pick_berries.cave_vines` sound event."""
comptime SOUND_EVENT_BIG_DRIPLEAF_TILT_DOWN: StaticString = (
    "tilt_down.big_dripleaf"
)
"""The `tilt_down.big_dripleaf` sound event."""
comptime SOUND_EVENT_BIG_DRIPLEAF_TILT_UP: StaticString = "tilt_up.big_dripleaf"
"""The `tilt_up.big_dripleaf` sound event."""
comptime SOUND_EVENT_COPPER_WAX_ON: StaticString = "copper.wax.on"
"""The `copper.wax.on` sound event."""
comptime SOUND_EVENT_COPPER_WAX_OFF: StaticString = "copper.wax.off"
"""The `copper.wax.off` sound event."""
comptime SOUND_EVENT_SCRAPE: StaticString = "scrape"
"""The `scrape` sound event."""
comptime SOUND_EVENT_PLAYER_HURT_DROWN: StaticString = "mob.player.hurt_drown"
"""The `mob.player.hurt_drown` sound event."""
comptime SOUND_EVENT_PLAYER_HURT_ON_FIRE: StaticString = (
    "mob.player.hurt_on_fire"
)
"""The `mob.player.hurt_on_fire` sound event."""
comptime SOUND_EVENT_PLAYER_HURT_FREEZE: StaticString = "mob.player.hurt_freeze"
"""The `mob.player.hurt_freeze` sound event."""
comptime SOUND_EVENT_USE_SPYGLASS: StaticString = "item.spyglass.use"
"""The `item.spyglass.use` sound event."""
comptime SOUND_EVENT_STOP_USING_SPYGLASS: StaticString = (
    "item.spyglass.stop_using"
)
"""The `item.spyglass.stop_using` sound event."""
comptime SOUND_EVENT_AMETHYST_BLOCK_CHIME: StaticString = "chime.amethyst_block"
"""The `chime.amethyst_block` sound event."""
comptime SOUND_EVENT_AMBIENT_SCREAMER: StaticString = "ambient.screamer"
"""The `ambient.screamer` sound event."""
comptime SOUND_EVENT_HURT_SCREAMER: StaticString = "hurt.screamer"
"""The `hurt.screamer` sound event."""
comptime SOUND_EVENT_DEATH_SCREAMER: StaticString = "death.screamer"
"""The `death.screamer` sound event."""
comptime SOUND_EVENT_MILK_SCREAMER: StaticString = "milk.screamer"
"""The `milk.screamer` sound event."""
comptime SOUND_EVENT_JUMP_TO_BLOCK: StaticString = "jump_to_block"
"""The `jump_to_block` sound event."""
comptime SOUND_EVENT_PRE_RAM: StaticString = "pre_ram"
"""The `pre_ram` sound event."""
comptime SOUND_EVENT_PRE_RAM_SCREAMER: StaticString = "pre_ram.screamer"
"""The `pre_ram.screamer` sound event."""
comptime SOUND_EVENT_RAM_IMPACT: StaticString = "ram_impact"
"""The `ram_impact` sound event."""
comptime SOUND_EVENT_RAM_IMPACT_SCREAMER: StaticString = "ram_impact.screamer"
"""The `ram_impact.screamer` sound event."""
comptime SOUND_EVENT_SQUID_INK_SQUIRT: StaticString = "squid.ink_squirt"
"""The `squid.ink_squirt` sound event."""
comptime SOUND_EVENT_GLOW_SQUID_INK_SQUIRT: StaticString = (
    "glow_squid.ink_squirt"
)
"""The `glow_squid.ink_squirt` sound event."""
comptime SOUND_EVENT_CONVERT_TO_STRAY: StaticString = "convert_to_stray"
"""The `convert_to_stray` sound event."""
comptime SOUND_EVENT_CAKE_ADD_CANDLE: StaticString = "cake.add_candle"
"""The `cake.add_candle` sound event."""
comptime SOUND_EVENT_EXTINGUISH_CANDLE: StaticString = "extinguish.candle"
"""The `extinguish.candle` sound event."""
comptime SOUND_EVENT_AMBIENT_CANDLE: StaticString = "ambient.candle"
"""The `ambient.candle` sound event."""
comptime SOUND_EVENT_BLOCK_CLICK: StaticString = "block.click"
"""The `block.click` sound event."""
comptime SOUND_EVENT_BLOCK_CLICK_FAIL: StaticString = "block.click.fail"
"""The `block.click.fail` sound event."""
comptime SOUND_EVENT_SCULK_CATALYST_BLOOM: StaticString = (
    "block.sculk_catalyst.bloom"
)
"""The `block.sculk_catalyst.bloom` sound event."""
comptime SOUND_EVENT_SCULK_SHRIEKER_SHRIEK: StaticString = (
    "block.sculk_shrieker.shriek"
)
"""The `block.sculk_shrieker.shriek` sound event."""
comptime SOUND_EVENT_WARDEN_NEARBY_CLOSE: StaticString = "nearby_close"
"""The `nearby_close` sound event."""
comptime SOUND_EVENT_WARDEN_NEARBY_CLOSER: StaticString = "nearby_closer"
"""The `nearby_closer` sound event."""
comptime SOUND_EVENT_WARDEN_NEARBY_CLOSEST: StaticString = "nearby_closest"
"""The `nearby_closest` sound event."""
comptime SOUND_EVENT_WARDEN_SLIGHTLY_ANGRY: StaticString = "agitated"
"""The `agitated` sound event."""
comptime SOUND_EVENT_RECORD_OTHERSIDE: StaticString = "record.otherside"
"""The `record.otherside` sound event."""
comptime SOUND_EVENT_TONGUE: StaticString = "tongue"
"""The `tongue` sound event."""
comptime SOUND_EVENT_CRACK_IRON_GOLEM: StaticString = "irongolem.crack"
"""The `irongolem.crack` sound event."""
comptime SOUND_EVENT_REPAIR_IRON_GOLEM: StaticString = "irongolem.repair"
"""The `irongolem.repair` sound event."""
comptime SOUND_EVENT_LISTENING: StaticString = "listening"
"""The `listening` sound event."""
comptime SOUND_EVENT_HEARTBEAT: StaticString = "heartbeat"
"""The `heartbeat` sound event."""
comptime SOUND_EVENT_HORN_BREAK: StaticString = "horn_break"
"""The `horn_break` sound event."""
comptime SOUND_EVENT_SCULK_SPREAD: StaticString = "block.sculk.spread"
"""The `block.sculk.spread` sound event."""
comptime SOUND_EVENT_SCULK_CHARGE: StaticString = "charge.sculk"
"""The `charge.sculk` sound event."""
comptime SOUND_EVENT_SCULK_SENSOR_PLACE: StaticString = (
    "block.sculk_sensor.place"
)
"""The `block.sculk_sensor.place` sound event."""
comptime SOUND_EVENT_SCULK_SHRIEKER_PLACE: StaticString = (
    "block.sculk_shrieker.place"
)
"""The `block.sculk_shrieker.place` sound event."""
comptime SOUND_EVENT_GOAT_CALL0: StaticString = "horn_call0"
"""The `horn_call0` sound event."""
comptime SOUND_EVENT_GOAT_CALL1: StaticString = "horn_call1"
"""The `horn_call1` sound event."""
comptime SOUND_EVENT_GOAT_CALL2: StaticString = "horn_call2"
"""The `horn_call2` sound event."""
comptime SOUND_EVENT_GOAT_CALL3: StaticString = "horn_call3"
"""The `horn_call3` sound event."""
comptime SOUND_EVENT_GOAT_CALL4: StaticString = "horn_call4"
"""The `horn_call4` sound event."""
comptime SOUND_EVENT_GOAT_CALL5: StaticString = "horn_call5"
"""The `horn_call5` sound event."""
comptime SOUND_EVENT_GOAT_CALL6: StaticString = "horn_call6"
"""The `horn_call6` sound event."""
comptime SOUND_EVENT_GOAT_CALL7: StaticString = "horn_call7"
"""The `horn_call7` sound event."""
comptime SOUND_EVENT_IMITATE_WARDEN: StaticString = "imitate.warden"
"""The `imitate.warden` sound event."""
comptime SOUND_EVENT_LISTENING_ANGRY: StaticString = "listening_angry"
"""The `listening_angry` sound event."""
comptime SOUND_EVENT_ITEM_GIVEN: StaticString = "item_given"
"""The `item_given` sound event."""
comptime SOUND_EVENT_ITEM_TAKEN: StaticString = "item_taken"
"""The `item_taken` sound event."""
comptime SOUND_EVENT_DISAPPEARED: StaticString = "disappeared"
"""The `disappeared` sound event."""
comptime SOUND_EVENT_REAPPEARED: StaticString = "reappeared"
"""The `reappeared` sound event."""
comptime SOUND_EVENT_DRINK_MILK: StaticString = "drink.milk"
"""The `drink.milk` sound event."""
comptime SOUND_EVENT_FROGSPAWN_HATCHED: StaticString = "block.frog_spawn.hatch"
"""The `block.frog_spawn.hatch` sound event."""
comptime SOUND_EVENT_LAY_SPAWN: StaticString = "lay_spawn"
"""The `lay_spawn` sound event."""
comptime SOUND_EVENT_FROGSPAWN_BREAK: StaticString = "block.frog_spawn.break"
"""The `block.frog_spawn.break` sound event."""
comptime SOUND_EVENT_SONIC_BOOM: StaticString = "sonic_boom"
"""The `sonic_boom` sound event."""
comptime SOUND_EVENT_SONIC_CHARGE: StaticString = "sonic_charge"
"""The `sonic_charge` sound event."""
comptime SOUND_EVENT_ITEM_THROWN: StaticString = "item_thrown"
"""The `item_thrown` sound event."""
comptime SOUND_EVENT_RECORD5: StaticString = "record.5"
"""The `record.5` sound event."""
comptime SOUND_EVENT_CONVERT_TO_FROG: StaticString = "convert_to_frog"
"""The `convert_to_frog` sound event."""
comptime SOUND_EVENT_RECORD_PLAYING: StaticString = "record.playing"
"""The `record.playing` sound event."""
comptime SOUND_EVENT_ENCHANTING_TABLE_USE: StaticString = (
    "block.enchanting_table.use"
)
"""The `block.enchanting_table.use` sound event."""
comptime SOUND_EVENT_STEP_SAND: StaticString = "step_sand"
"""The `step_sand` sound event."""
comptime SOUND_EVENT_DASH_READY: StaticString = "dash_ready"
"""The `dash_ready` sound event."""
comptime SOUND_EVENT_BUNDLE_DROP_CONTENTS: StaticString = "bundle.drop_contents"
"""The `bundle.drop_contents` sound event."""
comptime SOUND_EVENT_BUNDLE_INSERT: StaticString = "bundle.insert"
"""The `bundle.insert` sound event."""
comptime SOUND_EVENT_BUNDLE_REMOVE_ONE: StaticString = "bundle.remove_one"
"""The `bundle.remove_one` sound event."""
comptime SOUND_EVENT_PRESSURE_PLATE_CLICK_OFF: StaticString = (
    "pressure_plate.click_off"
)
"""The `pressure_plate.click_off` sound event."""
comptime SOUND_EVENT_PRESSURE_PLATE_CLICK_ON: StaticString = (
    "pressure_plate.click_on"
)
"""The `pressure_plate.click_on` sound event."""
comptime SOUND_EVENT_BUTTON_CLICK_OFF: StaticString = "button.click_off"
"""The `button.click_off` sound event."""
comptime SOUND_EVENT_BUTTON_CLICK_ON: StaticString = "button.click_on"
"""The `button.click_on` sound event."""
comptime SOUND_EVENT_DOOR_OPEN: StaticString = "door.open"
"""The `door.open` sound event."""
comptime SOUND_EVENT_DOOR_CLOSE: StaticString = "door.close"
"""The `door.close` sound event."""
comptime SOUND_EVENT_TRAPDOOR_OPEN: StaticString = "trapdoor.open"
"""The `trapdoor.open` sound event."""
comptime SOUND_EVENT_TRAPDOOR_CLOSE: StaticString = "trapdoor.close"
"""The `trapdoor.close` sound event."""
comptime SOUND_EVENT_FENCE_GATE_OPEN: StaticString = "fence_gate.open"
"""The `fence_gate.open` sound event."""
comptime SOUND_EVENT_FENCE_GATE_CLOSE: StaticString = "fence_gate.close"
"""The `fence_gate.close` sound event."""
comptime SOUND_EVENT_INSERT: StaticString = "insert"
"""The `insert` sound event."""
comptime SOUND_EVENT_PICKUP: StaticString = "pickup"
"""The `pickup` sound event."""
comptime SOUND_EVENT_INSERT_ENCHANTED: StaticString = "insert_enchanted"
"""The `insert_enchanted` sound event."""
comptime SOUND_EVENT_PICKUP_ENCHANTED: StaticString = "pickup_enchanted"
"""The `pickup_enchanted` sound event."""
comptime SOUND_EVENT_BRUSH: StaticString = "brush"
"""The `brush` sound event."""
comptime SOUND_EVENT_BRUSH_COMPLETED: StaticString = "brush_completed"
"""The `brush_completed` sound event."""
comptime SOUND_EVENT_SHATTER_DECORATED_POT: StaticString = "shatter_pot"
"""The `shatter_pot` sound event."""
comptime SOUND_EVENT_BREAK_DECORATED_POT: StaticString = "break_pot"
"""The `break_pot` sound event."""
comptime SOUND_EVENT_SNIFFER_EGG_CRACK: StaticString = "block.sniffer_egg.crack"
"""The `block.sniffer_egg.crack` sound event."""
comptime SOUND_EVENT_SNIFFER_EGG_HATCHED: StaticString = (
    "block.sniffer_egg.hatch"
)
"""The `block.sniffer_egg.hatch` sound event."""
comptime SOUND_EVENT_WAXED_SIGN_INTERACT_FAIL: StaticString = (
    "block.sign.waxed_interact_fail"
)
"""The `block.sign.waxed_interact_fail` sound event."""
comptime SOUND_EVENT_RECORD_RELIC: StaticString = "record.relic"
"""The `record.relic` sound event."""
comptime SOUND_EVENT_BUMP: StaticString = "note.bass"
"""The `note.bass` sound event."""
comptime SOUND_EVENT_PUMPKIN_CARVE: StaticString = "pumpkin.carve"
"""The `pumpkin.carve` sound event."""
comptime SOUND_EVENT_CONVERT_HUSK_TO_ZOMBIE: StaticString = (
    "mob.husk.convert_to_zombie"
)
"""The `mob.husk.convert_to_zombie` sound event."""
comptime SOUND_EVENT_PIG_DEATH: StaticString = "mob.pig.death"
"""The `mob.pig.death` sound event."""
comptime SOUND_EVENT_HOGLIN_ZOMBIFIED: StaticString = (
    "mob.hoglin.converted_to_zombified"
)
"""The `mob.hoglin.converted_to_zombified` sound event."""
comptime SOUND_EVENT_AMBIENT_UNDERWATER_ENTER: StaticString = (
    "ambient.underwater.enter"
)
"""The `ambient.underwater.enter` sound event."""
comptime SOUND_EVENT_AMBIENT_UNDERWATER_EXIT: StaticString = (
    "ambient.underwater.exit"
)
"""The `ambient.underwater.exit` sound event."""
comptime SOUND_EVENT_BOTTLE_FILL: StaticString = "bottle.fill"
"""The `bottle.fill` sound event."""
comptime SOUND_EVENT_BOTTLE_EMPTY: StaticString = "bottle.empty"
"""The `bottle.empty` sound event."""
comptime SOUND_EVENT_CRAFTER_CRAFT: StaticString = "crafter.craft"
"""The `crafter.craft` sound event."""
comptime SOUND_EVENT_CRAFTER_FAIL: StaticString = "crafter.fail"
"""The `crafter.fail` sound event."""
comptime SOUND_EVENT_DECORATED_POT_INSERT: StaticString = (
    "block.decorated_pot.insert"
)
"""The `block.decorated_pot.insert` sound event."""
comptime SOUND_EVENT_DECORATED_POT_INSERT_FAIL: StaticString = (
    "block.decorated_pot.insert_fail"
)
"""The `block.decorated_pot.insert_fail` sound event."""
comptime SOUND_EVENT_CRAFTER_DISABLE_SLOT: StaticString = "crafter.disable_slot"
"""The `crafter.disable_slot` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_OPEN_SHUTTER: StaticString = (
    "trial_spawner.open_shutter"
)
"""The `trial_spawner.open_shutter` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_EJECT_ITEM: StaticString = (
    "trial_spawner.eject_item"
)
"""The `trial_spawner.eject_item` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_DETECT_PLAYER: StaticString = (
    "trial_spawner.detect_player"
)
"""The `trial_spawner.detect_player` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_SPAWN_MOB: StaticString = (
    "trial_spawner.spawn_mob"
)
"""The `trial_spawner.spawn_mob` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_CLOSE_SHUTTER: StaticString = (
    "trial_spawner.close_shutter"
)
"""The `trial_spawner.close_shutter` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_AMBIENT: StaticString = (
    "trial_spawner.ambient"
)
"""The `trial_spawner.ambient` sound event."""
comptime SOUND_EVENT_COPPER_BULB_TURN_ON: StaticString = (
    "block.copper_bulb.turn_on"
)
"""The `block.copper_bulb.turn_on` sound event."""
comptime SOUND_EVENT_COPPER_BULB_TURN_OFF: StaticString = (
    "block.copper_bulb.turn_off"
)
"""The `block.copper_bulb.turn_off` sound event."""
comptime SOUND_EVENT_AMBIENT_IN_AIR: StaticString = "ambient.in.air"
"""The `ambient.in.air` sound event."""
comptime SOUND_EVENT_BREEZE_WIND_CHARGE_BURST: StaticString = (
    "breeze_wind_charge.burst"
)
"""The `breeze_wind_charge.burst` sound event."""
comptime SOUND_EVENT_IMITATE_BREEZE: StaticString = "imitate.breeze"
"""The `imitate.breeze` sound event."""
comptime SOUND_EVENT_ARMADILLO_BRUSH: StaticString = "mob.armadillo.brush"
"""The `mob.armadillo.brush` sound event."""
comptime SOUND_EVENT_ARMADILLO_SCUTE_DROP: StaticString = (
    "mob.armadillo.scute_drop"
)
"""The `mob.armadillo.scute_drop` sound event."""
comptime SOUND_EVENT_EQUIP_WOLF: StaticString = "armor.equip_wolf"
"""The `armor.equip_wolf` sound event."""
comptime SOUND_EVENT_UNEQUIP_WOLF: StaticString = "armor.unequip_wolf"
"""The `armor.unequip_wolf` sound event."""
comptime SOUND_EVENT_REFLECT: StaticString = "reflect"
"""The `reflect` sound event."""
comptime SOUND_EVENT_VAULT_OPEN_SHUTTER: StaticString = "vault.open_shutter"
"""The `vault.open_shutter` sound event."""
comptime SOUND_EVENT_VAULT_CLOSE_SHUTTER: StaticString = "vault.close_shutter"
"""The `vault.close_shutter` sound event."""
comptime SOUND_EVENT_VAULT_EJECT_ITEM: StaticString = "vault.eject_item"
"""The `vault.eject_item` sound event."""
comptime SOUND_EVENT_VAULT_INSERT_ITEM: StaticString = "vault.insert_item"
"""The `vault.insert_item` sound event."""
comptime SOUND_EVENT_VAULT_INSERT_ITEM_FAIL: StaticString = (
    "vault.insert_item_fail"
)
"""The `vault.insert_item_fail` sound event."""
comptime SOUND_EVENT_VAULT_AMBIENT: StaticString = "vault.ambient"
"""The `vault.ambient` sound event."""
comptime SOUND_EVENT_VAULT_ACTIVATE: StaticString = "vault.activate"
"""The `vault.activate` sound event."""
comptime SOUND_EVENT_VAULT_DEACTIVE: StaticString = "vault.deactivate"
"""The `vault.deactivate` sound event."""
comptime SOUND_EVENT_HURT_REDUCED: StaticString = "hurt.reduced"
"""The `hurt.reduced` sound event."""
comptime SOUND_EVENT_WIND_CHARGE_BURST: StaticString = "wind_charge.burst"
"""The `wind_charge.burst` sound event."""
comptime SOUND_EVENT_IMITATE_BOGGED: StaticString = "imitate.bogged"
"""The `imitate.bogged` sound event."""
comptime SOUND_EVENT_WOLF_ARMOUR_CRACK: StaticString = "armor.crack_wolf"
"""The `armor.crack_wolf` sound event."""
comptime SOUND_EVENT_WOLF_ARMOUR_BREAK: StaticString = "armor.break_wolf"
"""The `armor.break_wolf` sound event."""
comptime SOUND_EVENT_WOLF_ARMOUR_REPAIR: StaticString = "armor.repair_wolf"
"""The `armor.repair_wolf` sound event."""
comptime SOUND_EVENT_MACE_SMASH_AIR: StaticString = "mace.smash_air"
"""The `mace.smash_air` sound event."""
comptime SOUND_EVENT_MACE_SMASH_GROUND: StaticString = "mace.smash_ground"
"""The `mace.smash_ground` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_CHARGE_ACTIVATE: StaticString = (
    "trial_spawner.charge_activate"
)
"""The `trial_spawner.charge_activate` sound event."""
comptime SOUND_EVENT_TRIAL_SPAWNER_AMBIENT_OMINOUS: StaticString = (
    "trial_spawner.ambient_ominous"
)
"""The `trial_spawner.ambient_ominous` sound event."""
comptime SOUND_EVENT_OMINIOUS_ITEM_SPAWNER_SPAWN_ITEM: StaticString = (
    "ominous_item_spawner.spawn_item"
)
"""The `ominous_item_spawner.spawn_item` sound event."""
comptime SOUND_EVENT_OMINOUS_BOTTLE_END_USE: StaticString = (
    "ominous_bottle.end_use"
)
"""The `ominous_bottle.end_use` sound event."""
comptime SOUND_EVENT_MACE_HEAVY_SMASH_GROUND: StaticString = (
    "mace.heavy_smash_ground"
)
"""The `mace.heavy_smash_ground` sound event."""
comptime SOUND_EVENT_OMINOUS_ITEM_SPAWNER_SPAWN_ITEM_BEGIN: StaticString = (
    "ominous_item_spawner.spawn_item_begin"
)
"""The `ominous_item_spawner.spawn_item_begin` sound event."""
comptime SOUND_EVENT_APPLY_EFFECT_BAD_OMEN: StaticString = (
    "apply_effect.bad_omen"
)
"""The `apply_effect.bad_omen` sound event."""
comptime SOUND_EVENT_APPLY_EFFECT_RAID_OMEN: StaticString = (
    "apply_effect.raid_omen"
)
"""The `apply_effect.raid_omen` sound event."""
comptime SOUND_EVENT_APPLY_EFFECT_TRIAL_OMEN: StaticString = (
    "apply_effect.trial_omen"
)
"""The `apply_effect.trial_omen` sound event."""
comptime SOUND_EVENT_OMINOUS_ITEM_SPAWNER_ABOUT_TO_SPAWN_ITEM: StaticString = (
    "ominous_item_spawner.about_to_spawn_item"
)
"""The `ominous_item_spawner.about_to_spawn_item` sound event."""
comptime SOUND_EVENT_RECORD_CREATOR: StaticString = "record.creator"
"""The `record.creator` sound event."""
comptime SOUND_EVENT_RECORD_CREATOR_MUSIC_BOX: StaticString = (
    "record.creator_music_box"
)
"""The `record.creator_music_box` sound event."""
comptime SOUND_EVENT_RECORD_PRECIPICE: StaticString = "record.precipice"
"""The `record.precipice` sound event."""
comptime SOUND_EVENT_VAULT_REJECT_REWARDED_PLAYER: StaticString = (
    "vault.reject_rewarded_player"
)
"""The `vault.reject_rewarded_player` sound event."""
comptime SOUND_EVENT_IMITATE_DROWNED: StaticString = "imitate.drowned"
"""The `imitate.drowned` sound event."""
comptime SOUND_EVENT_IMITATE_CREAKING: StaticString = "imitate.creaking"
"""The `imitate.creaking` sound event."""
comptime SOUND_EVENT_BUNDLE_INSERT_FAILED: StaticString = "bundle.insert_fail"
"""The `bundle.insert_fail` sound event."""
comptime SOUND_EVENT_SPONGE_ABSORB: StaticString = "sponge.absorb"
"""The `sponge.absorb` sound event."""
comptime SOUND_EVENT_BLOCK_CREAKING_HEART_TRAIL: StaticString = (
    "block.creaking_heart.trail"
)
"""The `block.creaking_heart.trail` sound event."""
comptime SOUND_EVENT_CREAKING_HEART_SPAWN: StaticString = "creaking_heart_spawn"
"""The `creaking_heart_spawn` sound event."""
comptime SOUND_EVENT_ACTIVATE: StaticString = "activate"
"""The `activate` sound event."""
comptime SOUND_EVENT_DEACTIVATE: StaticString = "deactivate"
"""The `deactivate` sound event."""
comptime SOUND_EVENT_FREEZE: StaticString = "freeze"
"""The `freeze` sound event."""
comptime SOUND_EVENT_UNFREEZE: StaticString = "unfreeze"
"""The `unfreeze` sound event."""
comptime SOUND_EVENT_OPEN: StaticString = "open"
"""The `open` sound event."""
comptime SOUND_EVENT_OPEN_LONG: StaticString = "open_long"
"""The `open_long` sound event."""
comptime SOUND_EVENT_CLOSE: StaticString = "close"
"""The `close` sound event."""
comptime SOUND_EVENT_CLOSE_LONG: StaticString = "close_long"
"""The `close_long` sound event."""
comptime SOUND_EVENT_IMITATE_PHANTOM: StaticString = "imitate.phantom"
"""The `imitate.phantom` sound event."""
comptime SOUND_EVENT_IMITATE_ZOGLIN: StaticString = "imitate.zoglin"
"""The `imitate.zoglin` sound event."""
comptime SOUND_EVENT_IMITATE_GUARDIAN: StaticString = "imitate.guardian"
"""The `imitate.guardian` sound event."""
comptime SOUND_EVENT_IMITATE_RAVAGER: StaticString = "imitate.ravager"
"""The `imitate.ravager` sound event."""
comptime SOUND_EVENT_IMITATE_PILLAGER: StaticString = "imitate.pillager"
"""The `imitate.pillager` sound event."""
comptime SOUND_EVENT_PLACE_IN_WATER: StaticString = "place_in_water"
"""The `place_in_water` sound event."""
comptime SOUND_EVENT_STATE_CHANGE: StaticString = "state_change"
"""The `state_change` sound event."""
comptime SOUND_EVENT_IMITATE_HAPPY_GHAST: StaticString = "imitate.happy_ghast"
"""The `imitate.happy_ghast` sound event."""
comptime SOUND_EVENT_UNIQUE_GENERIC: StaticString = "armor.unequip_generic"
"""The `armor.unequip_generic` sound event."""
comptime SOUND_EVENT_RECORD_TEARS: StaticString = "record.tears"
"""The `record.tears` sound event."""
comptime SOUND_EVENT_THE_END_LIGHT_FLASH: StaticString = (
    "ambient.weather.the_end_light_flash"
)
"""The `ambient.weather.the_end_light_flash` sound event."""
comptime SOUND_EVENT_LEAD_LEASH: StaticString = "lead.leash"
"""The `lead.leash` sound event."""
comptime SOUND_EVENT_LEAD_UNLEASH: StaticString = "lead.unleash"
"""The `lead.unleash` sound event."""
comptime SOUND_EVENT_LEAD_BREAK: StaticString = "lead.break"
"""The `lead.break` sound event."""
comptime SOUND_EVENT_UNSADDLE: StaticString = "unsaddle"
"""The `unsaddle` sound event."""
comptime SOUND_EVENT_EQUIP_COPPER: StaticString = "armor.equip_copper"
"""The `armor.equip_copper` sound event."""
comptime SOUND_EVENT_RECORD_LAVA_CHICKEN: StaticString = "record.lava_chicken"
"""The `record.lava_chicken` sound event."""
comptime SOUND_EVENT_PLACE_ITEM: StaticString = "place_item"
"""The `place_item` sound event."""
comptime SOUND_EVENT_SINGLE_ITEM_SWAP: StaticString = "single_swap"
"""The `single_swap` sound event."""
comptime SOUND_EVENT_MULTI_ITEM_SWAP: StaticString = "multi_swap"
"""The `multi_swap` sound event."""
comptime SOUND_EVENT_ITEM_ENCHANT_LUNGE1: StaticString = "item.enchant.lunge1"
"""The `item.enchant.lunge1` sound event."""
comptime SOUND_EVENT_ITEM_ENCHANT_LUNGE2: StaticString = "item.enchant.lunge2"
"""The `item.enchant.lunge2` sound event."""
comptime SOUND_EVENT_ITEM_ENCHANT_LUNGE3: StaticString = "item.enchant.lunge3"
"""The `item.enchant.lunge3` sound event."""
comptime SOUND_EVENT_ATTACK_CRITICAL: StaticString = "attack.critical"
"""The `attack.critical` sound event."""
comptime SOUND_EVENT_ITEM_SPEAR_ATTACK_HIT: StaticString = (
    "item.spear.attack_hit"
)
"""The `item.spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_SPEAR_ATTACK_MISS: StaticString = (
    "item.spear.attack_miss"
)
"""The `item.spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_WOODEN_SPEAR_ATTACK_HIT: StaticString = (
    "item.wooden_spear.attack_hit"
)
"""The `item.wooden_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_WOODEN_SPEAR_ATTACK_MISS: StaticString = (
    "item.wooden_spear.attack_miss"
)
"""The `item.wooden_spear.attack_miss` sound event."""
comptime SOUND_EVENT_IMITATE_PARCHED: StaticString = "imitate.parched"
"""The `imitate.parched` sound event."""
comptime SOUND_EVENT_IMITATE_CAMEL_HUSK: StaticString = "imitate.camel_husk"
"""The `imitate.camel_husk` sound event."""
comptime SOUND_EVENT_ITEM_SPEAR_USE: StaticString = "item.spear.use"
"""The `item.spear.use` sound event."""
comptime SOUND_EVENT_ITEM_WOODEN_SPEAR_USE: StaticString = (
    "item.wooden_spear.use"
)
"""The `item.wooden_spear.use` sound event."""
comptime SOUND_EVENT_SADDLE_IN_WATER: StaticString = "saddle_in_water"
"""The `saddle_in_water` sound event."""
comptime SOUND_EVENT_ITEM_STONE_SPEAR_ATTACK_HIT: StaticString = (
    "item.stone_spear.attack_hit"
)
"""The `item.stone_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_IRON_SPEAR_ATTACK_HIT: StaticString = (
    "item.iron_spear.attack_hit"
)
"""The `item.iron_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_COPPER_SPEAR_ATTACK_HIT: StaticString = (
    "item.copper_spear.attack_hit"
)
"""The `item.copper_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_GOLDEN_SPEAR_ATTACK_HIT: StaticString = (
    "item.golden_spear.attack_hit"
)
"""The `item.golden_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_DIAMOND_SPEAR_ATTACK_HIT: StaticString = (
    "item.diamond_spear.attack_hit"
)
"""The `item.diamond_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_NETHERITE_SPEAR_ATTACK_HIT: StaticString = (
    "item.netherite_spear.attack_hit"
)
"""The `item.netherite_spear.attack_hit` sound event."""
comptime SOUND_EVENT_ITEM_STONE_SPEAR_ATTACK_MISS: StaticString = (
    "item.stone_spear.attack_miss"
)
"""The `item.stone_spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_IRON_SPEAR_ATTACK_MISS: StaticString = (
    "item.iron_spear.attack_miss"
)
"""The `item.iron_spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_COPPER_SPEAR_ATTACK_MISS: StaticString = (
    "item.copper_spear.attack_miss"
)
"""The `item.copper_spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_GOLDEN_SPEAR_ATTACK_MISS: StaticString = (
    "item.golden_spear.attack_miss"
)
"""The `item.golden_spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_DIAMOND_SPEAR_ATTACK_MISS: StaticString = (
    "item.diamond_spear.attack_miss"
)
"""The `item.diamond_spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_NETHERITE_SPEAR_ATTACK_MISS: StaticString = (
    "item.netherite_spear.attack_miss"
)
"""The `item.netherite_spear.attack_miss` sound event."""
comptime SOUND_EVENT_ITEM_STONE_SPEAR_USE: StaticString = "item.stone_spear.use"
"""The `item.stone_spear.use` sound event."""
comptime SOUND_EVENT_ITEM_IRON_SPEAR_USE: StaticString = "item.iron_spear.use"
"""The `item.iron_spear.use` sound event."""
comptime SOUND_EVENT_ITEM_COPPER_SPEAR_USE: StaticString = (
    "item.copper_spear.use"
)
"""The `item.copper_spear.use` sound event."""
comptime SOUND_EVENT_ITEM_GOLDEN_SPEAR_USE: StaticString = (
    "item.golden_spear.use"
)
"""The `item.golden_spear.use` sound event."""
comptime SOUND_EVENT_ITEM_DIAMOND_SPEAR_USE: StaticString = (
    "item.diamond_spear.use"
)
"""The `item.diamond_spear.use` sound event."""
comptime SOUND_EVENT_ITEM_NETHERITE_SPEAR_USE: StaticString = (
    "item.netherite_spear.use"
)
"""The `item.netherite_spear.use` sound event."""
comptime SOUND_EVENT_PAUSE_GROWTH: StaticString = "pause_growth"
"""The `pause_growth` sound event."""
comptime SOUND_EVENT_RESET_GROWTH: StaticString = "reset_growth"
"""The `reset_growth` sound event."""
comptime SOUND_EVENT_PUSHED_BY_PLAYER: StaticString = "pushed_by_player"
"""The `pushed_by_player` sound event."""
comptime SOUND_EVENT_BOUNCE: StaticString = "bounce"
"""The `bounce` sound event."""
comptime SOUND_EVENT_SLIME_LANDING: StaticString = "slime_landing"
"""The `slime_landing` sound event."""
comptime SOUND_EVENT_ABSORB_BLOCK: StaticString = "absorb_block"
"""The `absorb_block` sound event."""
comptime SOUND_EVENT_EJECT_BLOCK: StaticString = "eject_block"
"""The `eject_block` sound event."""
comptime SOUND_EVENT_GEYSER_ERUPTION_START: StaticString = (
    "geyser_eruption_start"
)
"""The `geyser_eruption_start` sound event."""
comptime SOUND_EVENT_GEYSER_ERUPTION_ACTIVE: StaticString = (
    "geyser_eruption_active"
)
"""The `geyser_eruption_active` sound event."""
comptime SOUND_EVENT_RECORD_BOUNCE: StaticString = "record.bounce"
"""The `record.bounce` sound event."""
comptime SOUND_EVENT_BUCKET_FILL_LAND_ANIMAL: StaticString = (
    "bucket.fill.land_animal"
)
"""The `bucket.fill.land_animal` sound event."""
comptime SOUND_EVENT_BUCKET_EMPTY_LAND_ANIMAL: StaticString = (
    "bucket.empty.land_animal"
)
"""The `bucket.empty.land_animal` sound event."""
comptime SOUND_EVENT_GEYSER_CONTINUOUS_ERUPTION_START: StaticString = (
    "geyser_continuous_eruption_start"
)
"""The `geyser_continuous_eruption_start` sound event."""
comptime SOUND_EVENT_GEYSER_CONTINUOUS_ERUPTION_ACTIVE: StaticString = (
    "geyser_continuous_eruption_active"
)
"""The `geyser_continuous_eruption_active` sound event."""
comptime SOUND_EVENT_MOUNT: StaticString = "mount"
"""The `mount` sound event."""
comptime SOUND_EVENT_DISMOUNT: StaticString = "dismount"
"""The `dismount` sound event."""
comptime SOUND_EVENT_STRAW_BED_BREAK_LEAVE: StaticString = (
    "straw_bed.break_leave"
)
"""The `straw_bed.break_leave` sound event."""
comptime SOUND_EVENT_UNDEFINED: StaticString = "undefined"
"""The `undefined` sound event."""


struct LevelSoundEvent(Packet):
    """Sent by the server to make any kind of built-in sound heard to a player.
    """

    comptime ID: UInt32 = ID_LEVEL_SOUND_EVENT
    """The packet ID."""
    var sound_type: String
    """The sound to play, one of the `SOUND_EVENT_*` values."""
    var position: Vec3
    """The position of the sound event."""
    var extra_data: Int32
    """A packed integer that some sound types use to provide extra data."""
    var entity_type: String
    """The string entity type of the entity that emitted the sound, for example
    'minecraft:skeleton'.
    """
    var baby_mob: Bool
    """Whether the sound is that of a baby mob."""
    var disable_relative_volume: Bool
    """Whether the sound plays at full volume regardless of distance."""
    var entity_unique_id: Int64
    """The unique ID of a source entity."""
    var fire_at_position: Optional[Vec3]
    """The position in the same world at which the event should fire."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.sound_type = String()
        self.position = Vec3()
        self.extra_data = 0
        self.entity_type = String()
        self.baby_mob = False
        self.disable_relative_volume = False
        self.entity_unique_id = 0
        self.fire_at_position = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.sound_type)
        vec3(io, self.position)
        io.varint32(self.extra_data)
        io.string(self.entity_type)
        io.bool(self.baby_mob)
        io.bool(self.disable_relative_volume)
        # gophertunnel `ActorUniqueIDInt64`: a little-endian int64.
        io.int64(self.entity_unique_id)
        optional_vec3(io, self.fire_at_position)
