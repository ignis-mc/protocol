from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.color import RGBA
from minecraft.protocol.container import FullContainerName
from minecraft.protocol.enchant import EnchantmentInstance, EnchantmentOption
from minecraft.protocol.inventory import (
    LegacySetItemSlot,
    UseItemTransactionData,
)
from minecraft.protocol.item import ItemInstance, ItemStack, ItemType
from minecraft.protocol.item_stack import (
    DestroyStackRequestAction,
    ItemStackRequest,
    StackRequestAction,
)
from minecraft.protocol.math import Vec2, Vec3
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.packet.photo_info_request import PhotoInfoRequest
from minecraft.protocol.packet.photo_transfer import (
    PHOTO_TYPE_BOOK,
    PHOTO_TYPE_PHOTO_ITEM,
    PhotoTransfer,
)
from minecraft.protocol.packet.play_sound import PlaySound
from minecraft.protocol.packet.player_action import PlayerAction
from minecraft.protocol.packet.player_armour_damage import PlayerArmourDamage
from minecraft.protocol.packet.player_auth_input import (
    INPUT_FLAG_INTERNAL_UPDATE,
    INPUT_FLAG_JUMPING,
    INPUT_FLAG_PERFORM_ITEM_INTERACTION,
    INPUT_MODE_MOUSE,
    INPUT_MODE_TOUCH,
    INTERACTION_MODEL_CLASSIC,
    INTERACTION_MODEL_CROSSHAIR,
    PLAY_MODE_NORMAL,
    PLAY_MODE_NUM_MODES,
    PLAY_MODE_SCREEN,
    PlayerAuthInput,
)
from minecraft.protocol.packet.player_enchant_options import (
    PlayerEnchantOptions,
)
from minecraft.protocol.packet.player_fog import PlayerFog
from minecraft.protocol.packet.player_hot_bar import PlayerHotBar
from minecraft.protocol.packet.player_list import PlayerList
from minecraft.protocol.player import (
    PLAYER_LIST_ACTION_ADD,
    PLAYER_LIST_ACTION_REMOVE,
    PlayerArmourDamageEntry,
    PlayerBlockAction,
    PlayerListEntry,
)
from minecraft.protocol.skin import Skin
from minecraft.protocol.uuid import UUID
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _round_trip[P: Packet](mut pk: P, expected: String) raises -> P:
    """Checks the encoding against Go, then decodes and re-encodes it."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var back = PacketData.parse(Span(hex_decode(expected))).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def _item(
    network_id: Int32, count: UInt16, meta: UInt32, stack_network_id: Int32
) -> ItemInstance:
    return ItemInstance(
        stack_network_id, ItemStack(ItemType(network_id, meta), count)
    )


def test_photo_info_request() raises:
    var pk = PhotoInfoRequest()
    pk.photo_id = -9
    var back = _round_trip(pk, "ad0111")
    assert_equal(back.photo_id, -9)


def test_photo_transfer() raises:
    var pk = PhotoTransfer()
    pk.photo_name = "a.png"
    pk.photo_data = [1, 2, 3]
    pk.book_id = "b"
    pk.photo_type = PHOTO_TYPE_BOOK
    pk.source_type = PHOTO_TYPE_PHOTO_ITEM
    pk.owner_entity_unique_id = -2
    pk.new_photo_name = "n"
    var back = _round_trip(
        pk, "6305612e706e670301020301620201feffffffffffffff016e"
    )
    assert_equal(back.owner_entity_unique_id, -2)
    assert_equal(back.new_photo_name, "n")


def test_play_sound_branches() raises:
    var pk = PlaySound()
    pk.sound_name = "note.harp"
    pk.position = Vec3(1.5, 2, -3.125)
    pk.volume = 1
    pk.pitch = 0.5
    pk.loop_count = -1
    pk.bypass_listener_range_check = True
    pk.handle = UInt64(7)
    pk.playback_position_seconds = Float32(2.5)
    var back = _round_trip(
        pk,
        "56096e6f74652e686172701820310000803f0000003f0101010700000000000000"
        + "0100002040",
    )
    assert_equal(back.position.z, -3.125)
    assert_equal(back.handle.value(), 7)
    assert_equal(back.playback_position_seconds.value(), 2.5)
    var plain = PlaySound()
    plain.sound_name = "random.click"
    plain.volume = 0.5
    plain.pitch = 1
    var back2 = _round_trip(
        plain, "560c72616e646f6d2e636c69636b0000000000003f0000803f00000000"
    )
    assert_true(back2.handle is None)
    assert_true(back2.playback_position_seconds is None)


def test_player_action() raises:
    var pk = PlayerAction()
    pk.entity_runtime_id = 1
    pk.action_type = 18
    pk.block_position = BlockPos(1, -2, 3)
    pk.result_position = BlockPos(4, 5, 6)
    pk.block_face = 2
    var back = _round_trip(pk, "240124020306080a0c04")
    assert_true(back.block_position == BlockPos(1, -2, 3))


def test_player_armour_damage() raises:
    var pk = PlayerArmourDamage()
    var a = PlayerArmourDamageEntry()
    a.armour_slot = 1
    a.damage = 5
    var b = PlayerArmourDamageEntry()
    b.armour_slot = 3
    b.damage = -1
    pk.list = [a^, b^]
    var back = _round_trip(pk, "95010202050006ffff")
    assert_equal(back.list[1].damage, -1)


def test_player_auth_input_full() raises:
    var pk = PlayerAuthInput()
    pk.pitch = 10
    pk.yaw = -20
    pk.position = Vec3(1, 2, 3)
    pk.move_vector = Vec2(0.5, 1)
    pk.head_yaw = 30
    pk.input_data.set(INPUT_FLAG_JUMPING)
    pk.input_data.set(INPUT_FLAG_PERFORM_ITEM_INTERACTION)
    pk.input_data.set(INPUT_FLAG_INTERNAL_UPDATE)
    pk.input_mode = INPUT_MODE_TOUCH
    pk.play_mode = PLAY_MODE_SCREEN
    pk.interaction_model = INTERACTION_MODEL_CROSSHAIR
    pk.interact_pitch = 1.5
    pk.interact_yaw = 2.5
    pk.tick = 1000
    pk.delta = Vec3(0.25, 0, -0.25)
    var use = UseItemTransactionData()
    use.legacy_request_id = -2
    use.legacy_set_item_slots = List[LegacySetItemSlot](
        [LegacySetItemSlot(3, [1, 2])]
    )
    use.action_type = 1
    use.trigger_type = 1
    use.block_position = BlockPos(4, 5, 6)
    use.block_face = 1
    use.hot_bar_slot = 2
    use.held_item = _item(5, 1, 0, 0)
    use.position = Vec3(1, 2, 3)
    use.clicked_position = Vec3(0.5, 0.5, 0.5)
    use.block_runtime_id = 99
    pk.item_interaction_data = use^
    var destroy = DestroyStackRequestAction()
    destroy.count = 2
    var container = FullContainerName()
    container.container_id = 3
    destroy.source.container = container^
    destroy.source.slot = 4
    destroy.source.stack_network_id = 5
    var request = ItemStackRequest()
    request.request_id = -3
    request.actions = [StackRequestAction(destroy^)]
    request.filter_strings = ["f"]
    request.filter_cause = 1
    pk.item_stack_request = request^
    var action = PlayerBlockAction()
    action.action = 18
    action.block_pos = BlockPos(7, 8, 9)
    action.face = 3
    pk.block_actions = List[PlayerBlockAction]([action^])
    pk.vehicle_rotation = Vec2(4, 5)
    pk.client_predicted_vehicle = Int64(-6)
    pk.analogue_move_vector = Vec2(0.25, 0.75)
    pk.camera_orientation = Vec3(0, 0, 1)
    pk.raw_move_vector = Vec2(1, -1)
    var back = _round_trip(
        pk,
        "9001000020410000a0c10000803f00000040000040400000003f0000803f0000f0"
        + "41030c4482010202020000c03f00002040e8070000803e00000000000080be01"
        + "03010103020102000201080a0c010400050001000000000a0000000000000000"
        + "00000000803f00000040000040400000003f0000003f0000003f630000010501"
        + "04040203000405000000010166010000000101240e10120601000080400000a0"
        + "40010b0000803e0000403f00000000000000000000803f0000803f000080bf",
    )
    assert_true(back.input_data.load(INPUT_FLAG_JUMPING))
    assert_true(back.input_data.load(INPUT_FLAG_INTERNAL_UPDATE))
    assert_false(back.input_data.load(0))
    var data = back.item_interaction_data.value().copy()
    assert_equal(data.block_runtime_id, 99)
    assert_equal(data.legacy_set_item_slots.value()[0].container_id, 3)
    assert_equal(back.item_stack_request.value().request_id, -3)
    assert_equal(back.block_actions.value()[0].face, 3)
    assert_equal(back.vehicle_rotation.value().y, 5)
    assert_equal(back.client_predicted_vehicle.value(), -6)
    assert_equal(back.raw_move_vector.y, -1)


def test_player_auth_input_minimal() raises:
    var pk = PlayerAuthInput()
    pk.pitch = 1
    pk.position = Vec3(0, 64, 0)
    pk.input_mode = INPUT_MODE_MOUSE
    pk.play_mode = PLAY_MODE_NORMAL
    pk.interaction_model = INTERACTION_MODEL_CLASSIC
    pk.tick = 5
    var expected = (
        "90010000803f0000000000000000000080420000000000000000000000000000"
        + "0000000100040000000000000000050000000000000000000000000000000000"
        + "00000000000000000000000000000000000000000000000000000000"
    )
    var back = _round_trip(pk, expected)
    assert_equal(len(back.input_data.ids()), 0)
    assert_true(back.item_interaction_data is None)
    assert_true(back.item_stack_request is None)
    assert_true(back.block_actions is None)
    assert_equal(PLAY_MODE_NUM_MODES, 9)
    # A flag ID outside [0, INPUT_FLAG_COUNT) raises.
    var bad = hex_decode(expected)
    bad[34] = 0x01  # one flag ID follows
    var flag = List[UInt8](Span(bad)[:35])
    flag.append(0x84)  # varint32 66
    flag.append(0x01)
    flag.extend(Span(bad)[35:])
    with assert_raises():
        _ = PacketData.parse(Span(flag)).decode[PlayerAuthInput]()


def test_player_enchant_options() raises:
    var option = EnchantmentOption()
    option.cost = 3
    option.enchantments.slot = 2
    var first = EnchantmentInstance()
    first.type = 9
    first.level = 1
    option.enchantments.enchantments[0] = [first^]
    var second = EnchantmentInstance()
    second.type = 12
    second.level = 2
    var third = EnchantmentInstance()
    third.type = 13
    third.level = 3
    option.enchantments.enchantments[2] = [second^, third^]
    option.name = "abc"
    option.recipe_network_id = 77
    var pk = PlayerEnchantOptions()
    pk.options = [option^]
    var back = _round_trip(pk, "920101030200000001090100020c020d03036162634d")
    assert_equal(back.options[0].name, "abc")
    assert_equal(len(back.options[0].enchantments.enchantments[2]), 2)


def test_player_fog() raises:
    var pk = PlayerFog()
    pk.stack = ["minecraft:fog_ocean", "minecraft:fog_hell"]
    var back = _round_trip(
        pk,
        "a00102136d696e6563726166743a666f675f6f6365616e126d696e656372616674"
        + "3a666f675f68656c6c",
    )
    assert_equal(back.stack[1], "minecraft:fog_hell")


def test_player_hot_bar() raises:
    var pk = PlayerHotBar()
    pk.selected_hot_bar_slot = 3
    pk.select_hot_bar_slot = True
    var back = _round_trip(pk, "30030001")
    assert_equal(back.selected_hot_bar_slot, 3)


def _skin() -> Skin:
    var s = Skin()
    s.skin_id = "skin"
    s.skin_image_width = 1
    s.skin_image_height = 1
    s.skin_data = [1, 2, 3, 4]
    s.skin_geometry = List[UInt8]("{}".as_bytes())
    s.cape_id = "cape"
    s.full_id = "full"
    s.arm_size = 1
    s.skin_colour = RGBA(1, 2, 3, 4)
    s.premium_skin = True
    s.trusted = True
    s.profile_hash = "ph"
    return s^


def test_player_list() raises:
    var add = PlayerListEntry()
    add.action_type = PLAYER_LIST_ACTION_ADD
    add.uuid = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    add.entity_unique_id = -4
    add.username = "Steve"
    add.xuid = "123"
    add.play_fab_id = "pf"
    add.platform_chat_id = "pc"
    add.build_platform = 7
    add.skin = _skin()
    add.host = True
    add.player_colour = RGBA(10, 20, 30, 255)
    var remove = PlayerListEntry()
    remove.action_type = PLAYER_LIST_ACTION_REMOVE
    remove.uuid = UUID.parse("0f1e2d3c-4b5a-6978-8796-a5b4c3d2e1f0")
    var pk = PlayerList()
    pk.entries = [add^, remove^]
    var back = _round_trip(
        pk,
        "3f0201007766554433221100ffeeddccbbaa998807055374657665033132330270"
        + "660270630700000004736b696e00010000000100000004010203040000000000"
        + "0000000000027b7d000004636170650466756c6c010302010400000100000000"
        + "04747275650270680001001e140aff000178695a4b3c2d1e0ff0e1d2c3b4a59687",
    )
    assert_equal(back.entries[0].username, "Steve")
    assert_true(back.entries[0].skin.trusted)
    assert_equal(back.entries[1].action_type, PLAYER_LIST_ACTION_REMOVE)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
