from minecraft.protocol.ability import AbilityValue
from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.experiments import ExperimentData
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.packet.purchase_receipt import PurchaseReceipt
from minecraft.protocol.packet.record_started import RecordStarted
from minecraft.protocol.packet.refresh_entitlements import (
    RefreshEntitlements,
)
from minecraft.protocol.packet.remove_actor import RemoveActor
from minecraft.protocol.packet.remove_objective import RemoveObjective
from minecraft.protocol.packet.remove_volume_entity import RemoveVolumeEntity
from minecraft.protocol.packet.request_ability import (
    ABILITY_FLYING,
    ABILITY_FLY_SPEED,
    RequestAbility,
)
from minecraft.protocol.packet.request_permissions import RequestPermissions
from minecraft.protocol.packet.resource_pack_chunk_data import (
    ResourcePackChunkData,
)
from minecraft.protocol.packet.resource_pack_chunk_request import (
    ResourcePackChunkRequest,
)
from minecraft.protocol.packet.resource_pack_data_info import (
    RESOURCE_PACK_TYPE_RESOURCES,
    ResourcePackDataInfo,
)
from minecraft.protocol.packet.resource_pack_stack import ResourcePackStack
from minecraft.protocol.resource_pack import StackResourcePack
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _round_trip[P: Packet](mut pk: P, expected: String) raises -> P:
    """Checks the encoding against Go, then decodes and re-encodes it."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var back = PacketData.parse(Span(hex_decode(expected))).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def test_purchase_receipt() raises:
    var pk = PurchaseReceipt()
    pk.receipts = ["r1", "r2"]
    var back = _round_trip(pk, "5c02027231027232")
    assert_equal(back.receipts[1], "r2")


def test_record_started() raises:
    var pk = RecordStarted()
    pk.position = BlockPos(1, 2, 3)
    pk.handle = 0x1122334455667788
    var back = _round_trip(pk, "e0020204068877665544332211")
    assert_equal(back.handle, 0x1122334455667788)


def test_refresh_entitlements() raises:
    var pk = RefreshEntitlements()
    _ = _round_trip(pk, "b102")
    # Trailing bytes after an empty packet are rejected.
    with assert_raises(contains="unread"):
        _ = PacketData.parse(Span(hex_decode("b10200"))).decode[
            RefreshEntitlements
        ]()


def test_remove_actor() raises:
    var pk = RemoveActor()
    pk.entity_unique_id = -7
    var back = _round_trip(pk, "0e0d")
    assert_equal(back.entity_unique_id, -7)


def test_remove_objective() raises:
    var pk = RemoveObjective()
    pk.objective_name = "obj"
    var back = _round_trip(pk, "6a036f626a")
    assert_equal(back.objective_name, "obj")


def test_remove_volume_entity() raises:
    var pk = RemoveVolumeEntity()
    pk.entity_runtime_id = 300
    pk.dimension = 1
    var back = _round_trip(pk, "a701ac0202")
    assert_equal(back.entity_runtime_id, 300)


def test_request_ability_branches() raises:
    var flying = RequestAbility()
    flying.ability = ABILITY_FLYING
    flying.value = AbilityValue(True)
    var back = _round_trip(flying, "b80112010100000000")
    assert_true(back.value.value[Bool])
    var speed = RequestAbility()
    speed.ability = ABILITY_FLY_SPEED
    speed.value = AbilityValue(Float32(0.25))
    var back2 = _round_trip(speed, "b8011a02000000803e")
    assert_equal(back2.value.value[Float32], 0.25)
    # Value type 3 is neither bool nor float.
    with assert_raises(contains="ability value type"):
        _ = PacketData.parse(Span(hex_decode("b8011a030000000000"))).decode[
            RequestAbility
        ]()


def test_request_permissions() raises:
    var pk = RequestPermissions()
    pk.entity_unique_id = -3
    pk.permission_level = 2
    pk.requested_permissions = 0x1FF
    var back = _round_trip(pk, "b901fdffffffffffffff04ff01")
    assert_equal(back.entity_unique_id, -3)
    assert_equal(back.requested_permissions, 0x1FF)


def test_resource_pack_chunk_data() raises:
    var pk = ResourcePackChunkData()
    pk.uuid = "u"
    pk.chunk_index = 2
    pk.data_offset = 1 << 20
    pk.data = [9, 8, 7]
    var back = _round_trip(pk, "53017502000000000010000000000003090807")
    assert_equal(back.data_offset, 1 << 20)
    assert_equal(len(back.data), 3)


def test_resource_pack_chunk_request() raises:
    var pk = ResourcePackChunkRequest()
    pk.uuid = "u"
    pk.chunk_index = 3
    var back = _round_trip(pk, "54017503000000")
    assert_equal(back.chunk_index, 3)


def test_resource_pack_data_info() raises:
    var pk = ResourcePackDataInfo()
    pk.uuid = "u"
    pk.data_chunk_size = 1 << 20
    pk.chunk_count = 2
    pk.size = 1500000
    pk.hash = [0xAA, 0xBB]
    pk.premium = True
    pk.pack_type = RESOURCE_PACK_TYPE_RESOURCES
    var back = _round_trip(
        pk, "520175000010000200000060e316000000000002aabb0106"
    )
    assert_equal(back.size, 1500000)
    assert_equal(back.pack_type, RESOURCE_PACK_TYPE_RESOURCES)


def test_resource_pack_stack() raises:
    var pk = ResourcePackStack()
    pk.texture_pack_required = True
    var pack = StackResourcePack()
    pack.uuid = "u"
    pack.version = "1.0.0"
    pack.sub_pack_name = "s"
    pk.texture_packs = [pack^]
    pk.base_game_version = "*"
    pk.experiments = [ExperimentData("gametest", True)]
    pk.experiments_previously_toggled = True
    pk.include_editor_packs = True
    var back = _round_trip(
        pk, "070101017505312e302e300173012a010000000867616d6574657374010101"
    )
    assert_equal(back.texture_packs[0].version, "1.0.0")
    assert_equal(back.experiments[0].name, "gametest")
    assert_true(back.include_editor_packs)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
