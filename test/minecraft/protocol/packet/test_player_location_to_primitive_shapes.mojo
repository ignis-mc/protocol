from minecraft.nbt.nbt import NETWORK_LITTLE_ENDIAN, NBT
from minecraft.protocol.color import RGBA
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from minecraft.protocol.packet.player_location import (
    PLAYER_LOCATION_TYPE_COORDINATES,
    PLAYER_LOCATION_TYPE_HIDE,
    PlayerLocation,
)
from minecraft.protocol.packet.player_skin import PlayerSkin
from minecraft.protocol.packet.player_toggle_crafter_slot_request import (
    PlayerToggleCrafterSlotRequest,
)
from minecraft.protocol.packet.player_update_entity_overrides import (
    PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_CLEAR_ALL,
    PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_FLOAT,
    PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_INT,
    PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_REMOVE,
    PlayerUpdateEntityOverrides,
)
from minecraft.protocol.packet.player_video_capture import (
    PLAYER_VIDEO_CAPTURE_ACTION_START,
    PLAYER_VIDEO_CAPTURE_ACTION_STOP,
    PlayerVideoCapture,
)
from minecraft.protocol.packet.position_tracking_db_client_request import (
    POSITION_TRACKING_DB_REQUEST_ACTION_QUERY,
    PositionTrackingDBClientRequest,
)
from minecraft.protocol.packet.position_tracking_db_server_broadcast import (
    POSITION_TRACKING_DB_BROADCAST_ACTION_DESTROY,
    PositionTrackingDBServerBroadcast,
)
from minecraft.protocol.packet.primitive_shapes import PrimitiveShapes
from minecraft.protocol.shape import BoxShape, PrimitiveShape, ShapeData
from minecraft.protocol.skin import Skin
from minecraft.protocol.uuid import UUID
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _round_trip[P: Packet](mut pk: P, expected: String) raises -> P:
    """Checks the encoding against Go, then decodes and re-encodes it."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var back = PacketData.parse(Span(hex_decode(expected))).decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def test_player_location_branches() raises:
    var pk = PlayerLocation()
    pk.type = PLAYER_LOCATION_TYPE_COORDINATES
    pk.entity_unique_id = -8
    pk.position = Vec3(1, 2, 3)
    var back = _round_trip(pk, "c6020f00000000803f0000004000004040")
    assert_equal(back.position.z, 3)
    var hide = PlayerLocation()
    hide.type = PLAYER_LOCATION_TYPE_HIDE
    hide.entity_unique_id = 8
    var back2 = _round_trip(hide, "c602100102")
    assert_equal(back2.type, PLAYER_LOCATION_TYPE_HIDE)
    assert_equal(back2.entity_unique_id, 8)
    # Go panics on type 5 when writing; both directions raise here.
    var bad = PlayerLocation()
    bad.type = 5
    with assert_raises(contains="player location type"):
        _ = encode_packet(bad)
    with assert_raises(contains="player location type"):
        _ = PacketData.parse(Span(hex_decode("c602000a0a"))).decode[
            PlayerLocation
        ]()


def test_player_skin() raises:
    var skin = Skin()
    skin.skin_id = "skin"
    skin.skin_image_width = 1
    skin.skin_image_height = 1
    skin.skin_data = [1, 2, 3, 4]
    skin.skin_geometry = List[UInt8]("{}".as_bytes())
    skin.cape_id = "cape"
    skin.full_id = "full"
    skin.arm_size = 1
    skin.skin_colour = RGBA(1, 2, 3, 4)
    skin.premium_skin = True
    skin.trusted = True
    skin.profile_hash = "ph"
    var pk = PlayerSkin()
    pk.uuid = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    pk.skin = skin^
    pk.new_skin_name = "new"
    pk.old_skin_name = "old"
    var back = _round_trip(
        pk,
        "5d7766554433221100ffeeddccbbaa998804736b696e00010000000100000004"
        + "0102030400000000000000000000027b7d000004636170650466756c6c010302"
        + "0104000001000000000474727565027068036e6577036f6c64",
    )
    assert_equal(back.skin.skin_id, "skin")
    assert_equal(back.old_skin_name, "old")
    # A skin whose data does not match its size is rejected.
    var wrong = PlayerSkin()
    wrong.skin.skin_image_width = 2
    wrong.skin.skin_image_height = 2
    with assert_raises():
        _ = encode_packet(wrong)


def test_player_toggle_crafter_slot_request() raises:
    var pk = PlayerToggleCrafterSlotRequest()
    pk.pos_x = 1
    pk.pos_y = -2
    pk.pos_z = 3
    pk.slot = 8
    pk.disabled = True
    var back = _round_trip(pk, "b20201000000feffffff030000000801")
    assert_equal(back.pos_y, -2)
    assert_true(back.disabled)


def test_player_update_entity_overrides_branches() raises:
    var clear = PlayerUpdateEntityOverrides()
    clear.entity_unique_id = -1
    clear.property_index = 2
    clear.type = PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_CLEAR_ALL
    _ = _round_trip(clear, "c5020102000e636c6561726f7665727269646573")
    var remove = PlayerUpdateEntityOverrides()
    remove.entity_unique_id = 1
    remove.property_index = 3
    remove.type = PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_REMOVE
    _ = _round_trip(remove, "c5020203010e72656d6f76656f76657272696465")
    var int_override = PlayerUpdateEntityOverrides()
    int_override.entity_unique_id = 1
    int_override.property_index = 4
    int_override.type = PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_INT
    int_override.int_value = -5
    var back = _round_trip(
        int_override, "c5020204020e736574696e746f76657272696465fbffffff"
    )
    assert_equal(back.int_value, -5)
    var float_override = PlayerUpdateEntityOverrides()
    float_override.entity_unique_id = 1
    float_override.property_index = 5
    float_override.type = PLAYER_UPDATE_ENTITY_OVERRIDES_TYPE_FLOAT
    float_override.float_value = 2.5
    var back2 = _round_trip(
        float_override, "c50202050310736574666c6f61746f7665727269646500002040"
    )
    assert_equal(back2.float_value, 2.5)
    var bad = PlayerUpdateEntityOverrides()
    bad.type = 4
    with assert_raises(contains="entity override type"):
        _ = encode_packet(bad)
    with assert_raises(contains="entity override type"):
        _ = PacketData.parse(Span(hex_decode("c502020504"))).decode[
            PlayerUpdateEntityOverrides
        ]()


def test_player_video_capture_branches() raises:
    var start = PlayerVideoCapture()
    start.action = PLAYER_VIDEO_CAPTURE_ACTION_START
    start.frame_rate = 30
    start.file_prefix = "f"
    var back = _round_trip(start, "c402011e0000000166")
    assert_equal(back.frame_rate, 30)
    assert_equal(back.file_prefix, "f")
    var stop = PlayerVideoCapture()
    stop.action = PLAYER_VIDEO_CAPTURE_ACTION_STOP
    stop.frame_rate = 30
    stop.file_prefix = "f"
    var back2 = _round_trip(stop, "c40200")
    assert_equal(back2.frame_rate, 0)


def test_position_tracking_db_client_request() raises:
    var pk = PositionTrackingDBClientRequest()
    pk.request_action = POSITION_TRACKING_DB_REQUEST_ACTION_QUERY
    pk.tracking_id = 5
    var back = _round_trip(pk, "9a01000a")
    assert_equal(back.tracking_id, 5)


def test_position_tracking_db_server_broadcast() raises:
    var pk = PositionTrackingDBServerBroadcast()
    pk.broadcast_action = POSITION_TRACKING_DB_BROADCAST_ACTION_DESTROY
    pk.tracking_id = 5
    # {"version": byte(1)} in network little endian, from Go.
    pk.payload = NBT(
        hex_decode("0a00010776657273696f6e0100"), NETWORK_LITTLE_ENDIAN
    )
    var back = _round_trip(pk, "9901010a0a00010776657273696f6e0100")
    assert_equal(len(back.payload.raw), 13)
    # The zero value matches Go's nil map: an empty compound.
    var empty = PositionTrackingDBServerBroadcast()
    _ = _round_trip(empty, "990100000a0000")
    # A truncated compound raises.
    with assert_raises():
        _ = PacketData.parse(Span(hex_decode("990100000a0001"))).decode[
            PositionTrackingDBServerBroadcast
        ]()


def test_primitive_shapes() raises:
    var shape = PrimitiveShape()
    shape.network_id = 5
    shape.type = UInt8(1)
    shape.location = Vec3(1, 2, 3)
    shape.colour = RGBA(255, 0, 0, 255)
    shape.dimension_id = Int32(0)
    var box = BoxShape()
    box.box_bound = Vec3(1, 1, 1)
    shape.extra_shape_data = ShapeData(box^)
    var pk = PrimitiveShapes()
    pk.shapes = [shape^]
    var back = _round_trip(
        pk,
        "c80201050101010000803f000000400000404000000000010000ffff0100000300"
        + "00803f0000803f0000803f",
    )
    assert_equal(back.shapes[0].network_id, 5)
    assert_true(back.shapes[0].extra_shape_data.value.isa[BoxShape]())


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
