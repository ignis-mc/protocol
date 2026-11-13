# Expected bytes come from gophertunnel v1.63.0 (header and payload).
from minecraft.protocol.ability import AbilityData, AbilityLayer
from minecraft.protocol.attribute import AttributeValue
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.entity_link import EntityLink, PassengerOfBlockData
from minecraft.protocol.entity_metadata import (
    ENTITY_DATA_KEY_NAME,
    EntityDataValue,
    EntityMetadata,
)
from minecraft.protocol.entity_properties import (
    EntityProperties,
    FloatEntityProperty,
    IntegerEntityProperty,
)
from minecraft.protocol.item import ItemInstance, ItemStack, ItemType
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.actor_event import (
    ACTOR_EVENT_FEED,
    ACTOR_EVENT_HURT,
    ACTOR_EVENT_HURT_WITHOUT_RECEIVING_DAMAGE,
    ACTOR_EVENT_SHAKE,
    ActorEvent,
)
from minecraft.protocol.packet.actor_pick_request import ActorPickRequest
from minecraft.protocol.packet.add_actor import AddActor
from minecraft.protocol.packet.add_behaviour_tree import AddBehaviourTree
from minecraft.protocol.packet.add_item_actor import AddItemActor
from minecraft.protocol.packet.add_painting import AddPainting
from minecraft.protocol.packet.add_player import AddPlayer
from minecraft.protocol.packet.add_volume_entity import AddVolumeEntity
from minecraft.protocol.packet.adventure_settings import (
    ACTION_PERMISSION_BUILD,
    ACTION_PERMISSION_MINE,
    ADVENTURE_FLAG_ALLOW_FLIGHT,
    ADVENTURE_FLAG_MUTED,
    PERMISSION_LEVEL_OPERATOR,
    AdventureSettings,
)
from minecraft.protocol.packet.agent_action import (
    AGENT_ACTION_TYPE_TURN,
    AgentAction,
)
from minecraft.protocol.packet.agent_animation import AgentAnimation
from minecraft.protocol.packet.animate import (
    ANIMATE_ACTION_CRITICAL_HIT,
    ANIMATE_ACTION_SWING_ARM,
    ANIMATE_SWING_SOURCE_THROW_ITEM,
    Animate,
)
from minecraft.protocol.packet.animate_entity import AnimateEntity
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.uuid import UUID
from minecraft.nbt.nbt import NBT, NETWORK_LITTLE_ENDIAN
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime _NBT = "0a000301610200"
"""Go `map[string]any{"a": int32(1)}` in network little-endian NBT."""


def _check[P: Packet](mut pk: P, want: StringSpan) raises -> P:
    """Checks the encoding, a decode of it, and that every prefix raises."""
    assert_equal(hex_encode(Span(encode_packet(pk))), String(want))
    var raw = hex_decode(want)
    var back = PacketData.parse(Span(raw)).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), String(want))
    for n in range(len(raw)):
        var cut = List[UInt8](Span(raw)[:n])
        var raised = False
        try:
            _ = PacketData.parse(Span(cut)).decode[P]()
        except:
            raised = True
        assert_true(raised, String(t"a {n}-byte prefix decoded"))
    return back^


def _metadata() -> EntityMetadata:
    var md = EntityMetadata()
    md.set(ENTITY_DATA_KEY_NAME, EntityDataValue(String("x")))
    return md^


def _properties() -> EntityProperties:
    var p = EntityProperties()
    var i = IntegerEntityProperty()
    i.index = 1
    i.value = -2
    p.integer_properties.append(i^)
    var f = FloatEntityProperty()
    f.index = 3
    f.value = 0.5
    p.float_properties.append(f^)
    return p^


def _link() -> EntityLink:
    var l = EntityLink()
    l.ridden_entity_unique_id = 1
    l.rider_entity_unique_id = -2
    l.type = 1
    l.immediate = True
    l.vehicle_angular_velocity = 1.5
    return l^


def _passenger() -> PassengerOfBlockData:
    var p = PassengerOfBlockData()
    p.block_position = BlockPos(1, 2, 3)
    p.offset = Vec3(0.5, 1, -0.5)
    p.rotation = 90
    p.rotation_limit = 45
    p.emote_type = 2
    return p^


def _item() -> ItemInstance:
    return ItemInstance(5, ItemStack(ItemType(3, 1), 2))


def _abilities() -> AbilityData:
    var a = AbilityData()
    a.entity_unique_id = 9
    a.player_permissions = 1
    a.command_permissions = 2
    var l = AbilityLayer()
    l.type = 1
    l.abilities = 3
    l.values = 1
    l.fly_speed = 0.5
    l.vertical_fly_speed = 1
    l.walk_speed = 0.1
    a.layers.append(l^)
    return a^


def test_actor_event() raises:
    assert_equal(ACTOR_EVENT_SHAKE, 39)
    assert_equal(ACTOR_EVENT_FEED, 57)
    assert_equal(ACTOR_EVENT_HURT_WITHOUT_RECEIVING_DAMAGE, 81)
    var pk = ActorEvent()
    pk.entity_runtime_id = 300
    pk.event_type = ACTOR_EVENT_FEED
    pk.event_data = -7
    pk.fire_at_position = Vec3(1, 2.5, -3)
    var back = _check(pk, "1bac02390d010000803f00002040000040c0")
    assert_equal(back.fire_at_position.value().y, 2.5)
    var none = ActorEvent()
    none.entity_runtime_id = 1
    none.event_type = ACTOR_EVENT_HURT
    assert_true(_check(none, "1b01020000").fire_at_position is None)


def test_actor_pick_request() raises:
    var pk = ActorPickRequest()
    pk.entity_unique_id = -5
    pk.hot_bar_slot = 3
    pk.with_data = True
    var back = _check(pk, "23fbffffffffffffff0301")
    assert_equal(back.entity_unique_id, -5)


def test_add_actor() raises:
    var pk = AddActor()
    pk.entity_unique_id = -9
    pk.entity_runtime_id = 9
    pk.entity_type = "minecraft:pig"
    pk.position = Vec3(1, 2, 3)
    pk.velocity = Vec3(0, -0.5, 0)
    pk.pitch = 10
    pk.yaw = 20
    pk.head_yaw = 30
    pk.body_yaw = 40
    var attr = AttributeValue()
    attr.name = "minecraft:health"
    attr.value = 10
    attr.max = 20
    pk.attributes.append(attr^)
    pk.entity_metadata = _metadata()
    pk.entity_properties = _properties()
    pk.entity_links.append(_link())
    pk.passenger_of_block = _passenger()
    var back = _check(
        pk,
        (
            "0d11090d6d696e6563726166743a7069670000803f0000004000004040000000"
            "00000000bf00000000000020410000a0410000f0410000204201106d696e6563"
            "726166743a6865616c746800000000000020410000a041010404040178010103"
            "01030000003f0102030101000000c03f010204060000003f0000803f000000bf"
            "0000b4420000344202"
        ),
    )
    assert_equal(back.entity_type, "minecraft:pig")
    assert_equal(back.attributes[0].max, 20)
    assert_equal(back.entity_links[0].rider_entity_unique_id, -2)
    assert_equal(back.passenger_of_block.value().emote_type, 2)


def test_add_behaviour_tree() raises:
    var pk = AddBehaviourTree()
    pk.behaviour_tree = "tree"
    assert_equal(_check(pk, "590474726565").behaviour_tree, "tree")


def test_add_item_actor() raises:
    var pk = AddItemActor()
    pk.entity_unique_id = 4
    pk.entity_runtime_id = 4
    pk.item = _item()
    pk.position = Vec3(1, 2, 3)
    pk.velocity = Vec3(0.25, 0, 0)
    pk.entity_metadata = _metadata()
    pk.from_fishing = True
    var back = _check(
        pk,
        (
            "0f08040300020001010a000a000000000000000000000000803f000000400000"
            "40400000803e000000000000000001040404017801"
        ),
    )
    assert_equal(back.item.stack_network_id, 5)
    assert_equal(back.item.stack.count, 2)
    assert_true(back.from_fishing)


def test_add_painting() raises:
    var pk = AddPainting()
    pk.entity_unique_id = 7
    pk.entity_runtime_id = 8
    pk.position = Vec3(1, 2, 3)
    pk.direction = 2
    pk.title = "Kebab"
    var back = _check(pk, "160e080000803f000000400000404004054b65626162")
    assert_equal(back.title, "Kebab")


def test_add_player() raises:
    var pk = AddPlayer()
    pk.uuid = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    pk.username = "Steve"
    pk.entity_runtime_id = 12
    pk.platform_chat_id = "pc"
    pk.position = Vec3(1, 64, 1)
    pk.velocity = Vec3(0, 0, 0.5)
    pk.pitch = 1
    pk.yaw = 2
    pk.head_yaw = 3
    pk.held_item = _item()
    pk.game_type = 1
    pk.entity_metadata = _metadata()
    pk.entity_properties = _properties()
    pk.ability_data = _abilities()
    pk.entity_links.append(_link())
    pk.passenger_of_block = _passenger()
    pk.device_id = "dev"
    pk.build_platform = 7
    var back = _check(
        pk,
        (
            "0c7766554433221100ffeeddccbbaa99880553746576650c0270630000803f00"
            "0080420000803f00000000000000000000003f0000803f000000400000404003"
            "00020001010a000a000000000000000000000201040404017801010301030000"
            "003f0900000000000000010201010003000000010000000000003f0000803fcd"
            "cccc3d0102030101000000c03f010204060000003f0000803f000000bf0000b4"
            "4200003442020364657607000000"
        ),
    )
    assert_equal(back.username, "Steve")
    assert_equal(back.ability_data.layers[0].walk_speed, Float32(0.1))
    assert_equal(back.build_platform, 7)


def test_add_volume_entity() raises:
    var pk = AddVolumeEntity()
    pk.entity_runtime_id = 300
    pk.entity_metadata = NBT(hex_decode(_NBT), NETWORK_LITTLE_ENDIAN)
    pk.encoding_identifier = "ns:vol"
    pk.instance_identifier = "fog"
    pk.bounds[0] = BlockPos(-1, 0, -2)
    pk.bounds[1] = BlockPos(3, 4, 5)
    pk.dimension = 1
    pk.engine_version = "1.17.0"
    var back = _check(
        pk,
        (
            "a601ac020a000301610200066e733a766f6c03666f67"
            "01000306080a0206312e31372e30"
        ),
    )
    assert_true(back.bounds[1] == BlockPos(3, 4, 5))
    assert_equal(hex_encode(Span(back.entity_metadata.raw)), _NBT)


def test_adventure_settings() raises:
    var pk = AdventureSettings()
    pk.flags = ADVENTURE_FLAG_ALLOW_FLIGHT | ADVENTURE_FLAG_MUTED
    pk.command_permission_level = 1
    pk.action_permissions = ACTION_PERMISSION_BUILD | ACTION_PERMISSION_MINE
    pk.permission_level = PERMISSION_LEVEL_OPERATOR
    pk.custom_stored_permissions = 300
    pk.player_unique_id = -77
    var back = _check(pk, "37c00801810102ac02b3ffffffffffffff")
    assert_equal(back.player_unique_id, -77)


def test_agent_action() raises:
    var pk = AgentAction()
    pk.identifier = "id"
    pk.action = AGENT_ACTION_TYPE_TURN
    pk.response = List[UInt8]('{"ok":1}'.as_bytes())
    var back = _check(pk, "b50102696412000000087b226f6b223a317d")
    assert_equal(back.action, 18)


def test_agent_animation() raises:
    var pk = AgentAnimation()
    pk.animation = 2
    pk.entity_runtime_id = 200
    assert_equal(_check(pk, "b00202c801").entity_runtime_id, 200)


def test_animate() raises:
    var pk = Animate()
    pk.action_type = ANIMATE_ACTION_SWING_ARM
    pk.entity_runtime_id = 3
    pk.data = 0.5
    pk.swing_source = ANIMATE_SWING_SOURCE_THROW_ITEM
    pk.hand = 1
    var back = _check(pk, "2c01030000003f01097468726f776974656d01")
    assert_equal(back.swing_source, ANIMATE_SWING_SOURCE_THROW_ITEM)
    var none = Animate()
    none.action_type = ANIMATE_ACTION_CRITICAL_HIT
    none.entity_runtime_id = 3
    assert_equal(_check(none, "2c0403000000000000").swing_source, 0)


def test_animate_unknown_swing_source() raises:
    # "bogus" is not a swing source name.
    var raw = hex_decode("2c0103000000000105626f67757301")
    with assert_raises(contains="unknown source"):
        _ = PacketData.parse(Span(raw)).decode[Animate]()
    var pk = Animate()
    pk.swing_source = 42
    with assert_raises(contains="unknown source"):
        _ = encode_packet(pk)


def test_animate_entity() raises:
    var pk = AnimateEntity()
    pk.animation = "a"
    pk.next_state = "n"
    pk.stop_condition = "q.x"
    pk.stop_condition_version = 1
    pk.controller = "c"
    pk.blend_out_time = 0.25
    pk.entity_runtime_ids = [1, 300]
    var back = _check(pk, "9e010161016e03712e780100000001630000803e0201ac02")
    assert_equal(back.entity_runtime_ids[1], 300)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
