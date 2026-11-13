from minecraft.protocol.item import ItemInstance, ItemStack, ItemType
from minecraft.protocol.map import PixelRequest
from minecraft.protocol.color import RGBA
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.map_create_locked_copy import (
    MapCreateLockedCopy,
)
from minecraft.protocol.packet.map_info_request import MapInfoRequest
from minecraft.protocol.packet.mob_armour_equipment import MobArmourEquipment
from minecraft.protocol.packet.mob_effect import (
    EFFECT_POISON,
    MOB_EFFECT_ADD,
    MobEffect,
)
from minecraft.protocol.packet.mob_equipment import MobEquipment
from minecraft.protocol.packet.modal_form_request import ModalFormRequest
from minecraft.protocol.packet.modal_form_response import (
    MODAL_FORM_CANCEL_REASON_USER_BUSY,
    ModalFormResponse,
)
from minecraft.protocol.packet.motion_prediction_hints import (
    MotionPredictionHints,
)
from minecraft.protocol.packet.move_actor_absolute import (
    MOVE_FLAG_ON_GROUND,
    MOVE_FLAG_TELEPORT,
    MoveActorAbsolute,
)
from minecraft.protocol.packet.move_actor_delta import MoveActorDelta
from minecraft.protocol.packet.move_player import (
    MOVE_MODE_NORMAL,
    MOVE_MODE_TELEPORT,
    TELEPORT_CAUSE_COMMAND,
    MovePlayer,
)
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.player import TeleportData
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


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


def test_map_create_locked_copy() raises:
    var pk = MapCreateLockedCopy()
    pk.original_map_id = -5
    pk.new_map_id = 300
    var back = _round_trip(pk, "830109d804")
    assert_equal(back.original_map_id, -5)
    assert_equal(back.new_map_id, 300)


def test_map_info_request() raises:
    var pk = MapInfoRequest()
    pk.map_id = 77
    var a = PixelRequest()
    a.colour = RGBA(1, 2, 3, 4)
    a.index = 9
    var b = PixelRequest()
    b.colour = RGBA(255, 0, 128, 255)
    b.index = 513
    pk.client_pixels = [a^, b^]
    var back = _round_trip(pk, "449a0102000000010203040900ff0080ff0102")
    assert_equal(len(back.client_pixels), 2)
    assert_equal(back.client_pixels[1].index, 513)
    # A count far beyond the payload raises instead of allocating.
    with assert_raises():
        _ = PacketData.parse(Span(hex_decode("4401ffffffff"))).decode[
            MapInfoRequest
        ]()


def test_mob_armour_equipment() raises:
    var pk = MobArmourEquipment()
    pk.entity_runtime_id = 12
    pk.helmet = _item(5, 1, 1, 3)
    pk.body = _item(7, 2, 0, 0)
    var back = _round_trip(
        pk,
        "200c05000100010106000a00000000000000000000000000000000000000000000"
        + "000000000000000000000000070002000000000a00000000000000000000",
    )
    assert_equal(back.helmet.stack_network_id, 3)
    assert_equal(back.helmet.stack.item_type.network_id, 5)
    assert_equal(back.body.stack.count, 2)
    assert_equal(back.boots.stack.item_type.network_id, 0)


def test_mob_effect() raises:
    var pk = MobEffect()
    pk.entity_runtime_id = 1
    pk.operation = MOB_EFFECT_ADD
    pk.effect_type = EFFECT_POISON
    pk.amplifier = -1
    pk.particles = True
    pk.duration = 600
    pk.tick = 1234
    pk.ambient = True
    var back = _round_trip(pk, "1c0101260101b009d20901")
    assert_equal(back.amplifier, -1)
    assert_equal(back.tick, 1234)


def test_mob_equipment() raises:
    var pk = MobEquipment()
    pk.entity_runtime_id = 2
    pk.new_item = _item(5, 3, 0, 9)
    pk.inventory_slot = 4
    pk.hot_bar_slot = 4
    pk.window_id = 119
    var back = _round_trip(
        pk, "1f0205000300000112000a00000000000000000000040477"
    )
    assert_equal(back.new_item.stack_network_id, 9)
    assert_equal(back.window_id, 119)


def test_modal_form_request() raises:
    var pk = ModalFormRequest()
    pk.form_id = 3
    pk.form_data = List[UInt8]('{"type":"form"}'.as_bytes())
    var back = _round_trip(pk, "64030f7b2274797065223a22666f726d227d")
    assert_equal(len(back.form_data), 15)


def test_modal_form_response_branches() raises:
    var data = ModalFormResponse()
    data.form_id = 3
    data.response_data = List[UInt8]("true".as_bytes())
    var back = _round_trip(data, "650301047472756500")
    assert_equal(len(back.response_data.value()), 4)
    assert_true(back.cancel_reason is None)
    var cancel = ModalFormResponse()
    cancel.form_id = 4
    cancel.cancel_reason = MODAL_FORM_CANCEL_REASON_USER_BUSY
    var back2 = _round_trip(cancel, "6504000101")
    assert_true(back2.response_data is None)
    assert_equal(back2.cancel_reason.value(), 1)


def test_motion_prediction_hints() raises:
    var pk = MotionPredictionHints()
    pk.entity_runtime_id = 9
    pk.velocity = Vec3(0.5, -1, 2.25)
    pk.on_ground = True
    var back = _round_trip(pk, "9d01090000003f000080bf0000104001")
    assert_equal(back.velocity.z, 2.25)


def test_move_actor_absolute() raises:
    var pk = MoveActorAbsolute()
    pk.entity_runtime_id = 10
    pk.flags = MOVE_FLAG_ON_GROUND | MOVE_FLAG_TELEPORT
    pk.position = Vec3(1.5, 64, -3)
    pk.rotation = Vec3(90, 45, 180)
    var back = _round_trip(pk, "120a030000c03f00008042000040c0402080")
    assert_equal(back.rotation.x, 90)
    assert_equal(back.rotation.z, 180)


def test_move_actor_delta() raises:
    var pk = MoveActorDelta()
    pk.entity_runtime_id = 11
    pk.position_x = Float32(1.5)
    pk.position_z = Float32(-2)
    pk.rotation_y = Float32(90)
    pk.on_ground = True
    pk.force_completion = True
    pk.ticks = 3
    var back = _round_trip(pk, "6f0b010000c03f0001000000c0000140000100000103")
    assert_true(back.position_y is None)
    assert_equal(back.position_z.value(), -2)
    assert_equal(back.rotation_y.value(), 90)
    assert_true(back.force_completion)


def test_move_player_branches() raises:
    var pk = MovePlayer()
    pk.entity_runtime_id = 1
    pk.position = Vec3(1, 2, 3)
    pk.pitch = 10
    pk.yaw = 20
    pk.head_yaw = 30
    pk.mode = MOVE_MODE_TELEPORT
    pk.on_ground = True
    pk.ridden_entity_runtime_id = 5
    var data = TeleportData()
    data.teleport_cause = TELEPORT_CAUSE_COMMAND
    data.teleport_source_entity_type = 87
    pk.teleport_data = data^
    pk.tick = 77
    var back = _round_trip(
        pk,
        "13010000803f0000004000004040000020410000a0410000f041020105010300"
        + "0000570000004d",
    )
    assert_equal(back.teleport_data.value().teleport_source_entity_type, 87)
    var normal = MovePlayer()
    normal.entity_runtime_id = 1
    normal.position = Vec3(1, 2, 3)
    normal.mode = MOVE_MODE_NORMAL
    normal.tick = 1
    var back2 = _round_trip(
        normal,
        "13010000803f00000040000040400000000000000000000000000000000001",
    )
    assert_true(back2.teleport_data is None)
    # Truncated input raises.
    with assert_raises():
        _ = PacketData.parse(Span(hex_decode("1301"))).decode[MovePlayer]()


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
