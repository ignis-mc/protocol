from minecraft.nbt.decode import from_nbt
from minecraft.nbt.encode import to_nbt
from minecraft.nbt.nbt import NETWORK_LITTLE_ENDIAN
from minecraft.nbt.tree import Tree
from minecraft.protocol.block_pos import BlockPos, SubChunkPos
from minecraft.protocol.clock import (
    CLOCK_PAYLOAD_TYPE_ADD_TIME_MARKER,
    CLOCK_PAYLOAD_TYPE_INITIALIZE_REGISTRY,
    CLOCK_PAYLOAD_TYPE_REMOVE_TIME_MARKER,
    CLOCK_PAYLOAD_TYPE_SYNC_STATE,
    SyncWorldClockStateData,
    TimeMarkerData,
    WorldClockData,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.packet.stop_sound import StopSound
from minecraft.protocol.packet.structure_block_update import (
    STRUCTURE_BLOCK_LOAD,
    STRUCTURE_REDSTONE_SAVE_MODE_DISK,
    StructureBlockUpdate,
)
from minecraft.protocol.packet.structure_template_data_request import (
    STRUCTURE_TEMPLATE_REQUEST_QUERY_SAVED_STRUCTURE,
    StructureTemplateDataRequest,
)
from minecraft.protocol.packet.structure_template_data_response import (
    STRUCTURE_TEMPLATE_RESPONSE_EXPORT,
    STRUCTURE_TEMPLATE_RESPONSE_QUERY,
    StructureTemplateDataResponse,
)
from minecraft.protocol.packet.sub_chunk import SubChunk
from minecraft.protocol.packet.sub_chunk_request import SubChunkRequest
from minecraft.protocol.packet.sub_client_login import SubClientLogin
from minecraft.protocol.packet.sync_actor_property import SyncActorProperty
from minecraft.protocol.packet.sync_world_clocks import SyncWorldClocks
from minecraft.protocol.packet.take_item_actor import TakeItemActor
from minecraft.protocol.packet.ticking_areas_load_status import (
    TickingAreasLoadStatus,
)
from minecraft.protocol.packet.toast_request import ToastRequest
from minecraft.protocol.packet.transfer import Transfer
from minecraft.protocol.server_join_information import GatheringJoinInfo
from minecraft.protocol.structure import (
    ANIMATION_MODE_LAYERS,
    STRUCTURE_MIRROR_X_AXIS,
    STRUCTURE_ROTATION_ROTATE90,
    StructureSettings,
)
from minecraft.protocol.sub_chunk import (
    HEIGHT_MAP_DATA_HAS_DATA,
    HEIGHT_MAP_DATA_TOO_HIGH,
    HEIGHT_MAP_DATA_TOO_LOW,
    SUB_CHUNK_RESULT_SUCCESS,
    SUB_CHUNK_RESULT_SUCCESS_ALL_AIR,
    HeightMap,
    SubChunkEntry,
    SubChunkOffset,
)
from minecraft.protocol.uuid import UUID

from minecraft.protocol.packet.packet import Packet, PacketData, encode_packet
from nethernet.wire import hex_decode, hex_encode
from std.testing import (
    TestSuite,
    assert_equal,
    assert_false,
    assert_raises,
    assert_true,
)


def _check[P: Packet](mut pk: P, expected: String) raises -> P:
    """Encodes `pk`, compares with Go's bytes, then decodes and re-encodes."""
    assert_equal(hex_encode(Span(encode_packet(pk))), expected)
    var data = PacketData.parse(Span(hex_decode(expected)))
    var back = data.decode[P]()
    assert_equal(hex_encode(Span(encode_packet(back))), expected)
    return back^


def _truncated[P: Packet](expected: String) raises:
    """Checks that every strict prefix of the payload fails to decode."""
    var raw = hex_decode(expected)
    var full = PacketData.parse(Span(raw))
    for n in range(len(full.payload)):
        var cut = PacketData(full.header, List[UInt8](Span(full.payload)[:n]))
        with assert_raises():
            _ = cut.decode[P]()


def test_stop_sound() raises:
    var pk = StopSound()
    pk.sound_name = "music.game"
    pk.stop_music_legacy = True
    var back = _check(pk, "570a6d757369632e67616d650001")
    _truncated[StopSound]("570a6d757369632e67616d650001")
    assert_equal(back.sound_name, "music.game")
    assert_false(back.stop_all)
    assert_true(back.stop_music_legacy)


def test_structure_block_update() raises:
    var pk = StructureBlockUpdate()
    var s = StructureSettings()
    s.palette_name = "default"
    s.ignore_entities = True
    s.allow_non_ticking_chunks = True
    s.size = BlockPos(5, 6, 7)
    s.offset = BlockPos(-1, 0, 2)
    s.last_editing_player_unique_id = -12345
    s.rotation = STRUCTURE_ROTATION_ROTATE90
    s.mirror = STRUCTURE_MIRROR_X_AXIS
    s.animation_mode = ANIMATION_MODE_LAYERS
    s.animation_duration = 2.5
    s.integrity = 0.75
    s.seed = 0xDEADBEEF
    s.pivot = Vec3(0.5, 1, 1.5)

    pk.position = BlockPos(10, 20, 30)
    pk.structure_name = "house"
    pk.filtered_structure_name = "h***e"
    pk.data_field = "data"
    pk.include_players = True
    pk.show_bounding_box = True
    pk.structure_block_type = STRUCTURE_BLOCK_LOAD
    pk.settings = s^
    pk.redstone_save_mode = STRUCTURE_REDSTONE_SAVE_MODE_DISK
    pk.should_trigger = True
    pk.waterlogged = True
    var back = _check(
        pk,
        (
            "5a14283c05686f75736505682a2a2a650464617461010104076465666175"
            "6c740100010a0c0e010004f1c001010101000020400000403fefbeadde00"
            "00003f0000803f0000c03f010101"
        ),
    )
    _truncated[StructureBlockUpdate](
        "5a14283c05686f75736505682a2a2a650464617461010104076465666175"
        "6c740100010a0c0e010004f1c001010101000020400000403fefbeadde00"
        "00003f0000803f0000c03f010101"
    )
    assert_equal(back.settings.seed, 0xDEADBEEF)
    assert_equal(back.structure_block_type, STRUCTURE_BLOCK_LOAD)
    assert_true(back.waterlogged)


def test_structure_template_data_request() raises:
    var pk = StructureTemplateDataRequest()
    var s = StructureSettings()
    s.palette_name = "default"
    s.ignore_entities = True
    s.allow_non_ticking_chunks = True
    s.size = BlockPos(5, 6, 7)
    s.offset = BlockPos(-1, 0, 2)
    s.last_editing_player_unique_id = -12345
    s.rotation = STRUCTURE_ROTATION_ROTATE90
    s.mirror = STRUCTURE_MIRROR_X_AXIS
    s.animation_mode = ANIMATION_MODE_LAYERS
    s.animation_duration = 2.5
    s.integrity = 0.75
    s.seed = 0xDEADBEEF
    s.pivot = Vec3(0.5, 1, 1.5)

    pk.structure_name = "house"
    pk.position = BlockPos(1, 2, 3)
    pk.settings = s^
    pk.request_type = STRUCTURE_TEMPLATE_REQUEST_QUERY_SAVED_STRUCTURE
    var back = _check(
        pk,
        (
            "840105686f7573650204060764656661756c740100010a0c0e010004f1c0"
            "01010101000020400000403fefbeadde0000003f0000803f0000c03f03"
        ),
    )
    _truncated[StructureTemplateDataRequest](
        "840105686f7573650204060764656661756c740100010a0c0e010004f1c0"
        "01010101000020400000403fefbeadde0000003f0000803f0000c03f03"
    )
    assert_equal(back.settings.palette_name, "default")
    assert_equal(back.request_type, 3)


def test_structure_template_data_response_success() raises:
    var pk = StructureTemplateDataResponse()
    var t = Tree()
    _ = t.put_int(t.root(), "format_version", 1)
    pk.structure_name = "house"
    pk.success = True
    pk.response_type = STRUCTURE_TEMPLATE_RESPONSE_EXPORT
    pk.structure_template = to_nbt(t, NETWORK_LITTLE_ENDIAN)
    var back = _check(
        pk, "850105686f757365010a00030e666f726d61745f76657273696f6e020001"
    )
    _truncated[StructureTemplateDataResponse](
        "850105686f757365010a00030e666f726d61745f76657273696f6e020001"
    )
    var tree = from_nbt(back.structure_template)
    assert_equal(tree.get_int(tree.root(), "format_version"), 1)


def test_structure_template_data_response_failure() raises:
    var pk = StructureTemplateDataResponse()
    pk.structure_name = "house"
    pk.response_type = STRUCTURE_TEMPLATE_RESPONSE_QUERY
    var back = _check(pk, "850105686f7573650002")
    _truncated[StructureTemplateDataResponse]("850105686f7573650002")
    assert_false(back.success)
    assert_equal(back.response_type, STRUCTURE_TEMPLATE_RESPONSE_QUERY)


def test_sub_chunk() raises:
    var pk = SubChunk()
    pk.cache_enabled = True
    pk.dimension = 1
    pk.position = SubChunkPos(3, -4, 5)
    var a = SubChunkEntry()
    a.offset = SubChunkOffset(0, 1, -1)
    a.result = SUB_CHUNK_RESULT_SUCCESS
    var payload: List[UInt8] = [1, 2, 3]
    a.raw_payload = payload^
    a.height_map_type = HEIGHT_MAP_DATA_HAS_DATA
    var h = HeightMap()
    var r = HeightMap()
    for z in range(16):
        for x in range(16):
            h[z, x] = Int8(-100 + z * 16 + x)
            r[z, x] = Int8(-50 + z * 16 + x)
    a.height_map_data = h^
    a.render_height_map_type = HEIGHT_MAP_DATA_HAS_DATA
    a.render_height_map_data = r^
    var b = SubChunkEntry()
    b.offset = SubChunkOffset(1, 0, 0)
    b.result = SUB_CHUNK_RESULT_SUCCESS_ALL_AIR
    b.height_map_type = HEIGHT_MAP_DATA_TOO_HIGH
    b.render_height_map_type = HEIGHT_MAP_DATA_TOO_LOW
    b.blob_hash = UInt64(0x1122334455667788)
    pk.sub_chunk_entries = [a^, b^]
    var back = _check(
        pk,
        (
            "ae01010203000000fcffffff05000000020001ff0101030102030101109c"
            "9d9e9fa0a1a2a3a4a5a6a7a8a9aaab10acadaeafb0b1b2b3b4b5b6b7b8b9"
            "babb10bcbdbebfc0c1c2c3c4c5c6c7c8c9cacb10cccdcecfd0d1d2d3d4d5"
            "d6d7d8d9dadb10dcdddedfe0e1e2e3e4e5e6e7e8e9eaeb10ecedeeeff0f1"
            "f2f3f4f5f6f7f8f9fafb10fcfdfeff000102030405060708090a0b100c0d"
            "0e0f101112131415161718191a1b101c1d1e1f202122232425262728292a"
            "2b102c2d2e2f303132333435363738393a3b103c3d3e3f40414243444546"
            "4748494a4b104c4d4e4f505152535455565758595a5b105c5d5e5f606162"
            "636465666768696a6b106c6d6e6f707172737475767778797a7b107c7d7e"
            "7f808182838485868788898a8b108c8d8e8f909192939495969798999a9b"
            "010110cecfd0d1d2d3d4d5d6d7d8d9dadbdcdd10dedfe0e1e2e3e4e5e6e7"
            "e8e9eaebeced10eeeff0f1f2f3f4f5f6f7f8f9fafbfcfd10feff00010203"
            "0405060708090a0b0c0d100e0f101112131415161718191a1b1c1d101e1f"
            "202122232425262728292a2b2c2d102e2f303132333435363738393a3b3c"
            "3d103e3f404142434445464748494a4b4c4d104e4f505152535455565758"
            "595a5b5c5d105e5f606162636465666768696a6b6c6d106e6f7071727374"
            "75767778797a7b7c7d107e7f808182838485868788898a8b8c8d108e8f90"
            "9192939495969798999a9b9c9d109e9fa0a1a2a3a4a5a6a7a8a9aaabacad"
            "10aeafb0b1b2b3b4b5b6b7b8b9babbbcbd10bebfc0c1c2c3c4c5c6c7c8c9"
            "cacbcccd00010000060002000300018877665544332211"
        ),
    )
    _truncated[SubChunk](
        "ae01010203000000fcffffff05000000020001ff0101030102030101109c"
        "9d9e9fa0a1a2a3a4a5a6a7a8a9aaab10acadaeafb0b1b2b3b4b5b6b7b8b9"
        "babb10bcbdbebfc0c1c2c3c4c5c6c7c8c9cacb10cccdcecfd0d1d2d3d4d5"
        "d6d7d8d9dadb10dcdddedfe0e1e2e3e4e5e6e7e8e9eaeb10ecedeeeff0f1"
        "f2f3f4f5f6f7f8f9fafb10fcfdfeff000102030405060708090a0b100c0d"
        "0e0f101112131415161718191a1b101c1d1e1f202122232425262728292a"
        "2b102c2d2e2f303132333435363738393a3b103c3d3e3f40414243444546"
        "4748494a4b104c4d4e4f505152535455565758595a5b105c5d5e5f606162"
        "636465666768696a6b106c6d6e6f707172737475767778797a7b107c7d7e"
        "7f808182838485868788898a8b108c8d8e8f909192939495969798999a9b"
        "010110cecfd0d1d2d3d4d5d6d7d8d9dadbdcdd10dedfe0e1e2e3e4e5e6e7"
        "e8e9eaebeced10eeeff0f1f2f3f4f5f6f7f8f9fafbfcfd10feff00010203"
        "0405060708090a0b0c0d100e0f101112131415161718191a1b1c1d101e1f"
        "202122232425262728292a2b2c2d102e2f303132333435363738393a3b3c"
        "3d103e3f404142434445464748494a4b4c4d104e4f505152535455565758"
        "595a5b5c5d105e5f606162636465666768696a6b6c6d106e6f7071727374"
        "75767778797a7b7c7d107e7f808182838485868788898a8b8c8d108e8f90"
        "9192939495969798999a9b9c9d109e9fa0a1a2a3a4a5a6a7a8a9aaabacad"
        "10aeafb0b1b2b3b4b5b6b7b8b9babbbcbd10bebfc0c1c2c3c4c5c6c7c8c9"
        "cacbcccd00010000060002000300018877665544332211"
    )
    assert_equal(len(back.sub_chunk_entries), 2)
    assert_equal(
        back.sub_chunk_entries[0].height_map_data.value()[15, 15], -101
    )
    assert_equal(
        back.sub_chunk_entries[1].blob_hash.value(), 0x1122334455667788
    )


def test_sub_chunk_request() raises:
    var pk = SubChunkRequest()
    pk.offsets = [SubChunkOffset(0, 0, 0), SubChunkOffset(-1, 2, -3)]
    pk.position = SubChunkPos(10, 4, -10)
    var back = _check(pk, "af010002000000ff02fd0a00000004000000f6ffffff")
    _truncated[SubChunkRequest]("af010002000000ff02fd0a00000004000000f6ffffff")
    assert_true(back.offsets[1] == SubChunkOffset(-1, 2, -3))


def test_sub_client_login() raises:
    var pk = SubClientLogin()
    pk.connection_request = [9, 8, 7, 6]
    var back = _check(pk, "5e0409080706")
    _truncated[SubClientLogin]("5e0409080706")
    assert_equal(back.connection_request[3], 6)


def test_sync_actor_property() raises:
    var pk = SyncActorProperty()
    var t = Tree()
    _ = t.put_string(t.root(), "type", "minecraft:player")
    pk.property_data = to_nbt(t, NETWORK_LITTLE_ENDIAN)
    var back = _check(
        pk, "a5010a00080474797065106d696e6563726166743a706c6179657200"
    )
    _truncated[SyncActorProperty](
        "a5010a00080474797065106d696e6563726166743a706c6179657200"
    )
    var tree = from_nbt(back.property_data)
    assert_equal(tree.get_string(tree.root(), "type"), "minecraft:player")


def test_sync_world_clocks_sync_state() raises:
    var pk = SyncWorldClocks()
    pk.payload_type = CLOCK_PAYLOAD_TYPE_SYNC_STATE
    var s = SyncWorldClockStateData()
    s.clock_id = 1
    s.time = 1000
    s.paused = True
    pk.sync_states = [s^]
    var back = _check(pk, "d802000101d00f01")
    _truncated[SyncWorldClocks]("d802000101d00f01")
    assert_equal(back.sync_states[0].time, 1000)


def test_sync_world_clocks_initialize() raises:
    var pk = SyncWorldClocks()
    pk.payload_type = CLOCK_PAYLOAD_TYPE_INITIALIZE_REGISTRY
    var noon = TimeMarkerData()
    noon.id = 3
    noon.name = "noon"
    noon.time = 6000
    noon.period = Int32(24000)
    var once = TimeMarkerData()
    once.id = 4
    once.name = "once"
    once.time = 1
    var c = WorldClockData()
    c.id = 2
    c.name = "overworld"
    c.time = 6000
    c.time_markers = [noon^, once^]
    pk.clocks = [c^]
    var back = _check(
        pk,
        (
            "d802010102096f766572776f726c64e05d000203046e6f6f6ee05d01c05d"
            "000004046f6e63650200"
        ),
    )
    _truncated[SyncWorldClocks](
        "d802010102096f766572776f726c64e05d000203046e6f6f6ee05d01c05d"
        "000004046f6e63650200"
    )
    assert_equal(back.clocks[0].name, "overworld")
    assert_equal(back.clocks[0].time_markers[0].period.value(), 24000)
    assert_true(back.clocks[0].time_markers[1].period is None)


def test_sync_world_clocks_add_marker() raises:
    var pk = SyncWorldClocks()
    pk.payload_type = CLOCK_PAYLOAD_TYPE_ADD_TIME_MARKER
    pk.add_clock_id = 7
    var m = TimeMarkerData()
    m.id = 8
    m.name = "dusk"
    m.time = 12000
    pk.add_time_markers = [m^]
    var back = _check(pk, "d80202070108046475736bc0bb0100")
    _truncated[SyncWorldClocks]("d80202070108046475736bc0bb0100")
    assert_equal(back.add_clock_id, 7)
    assert_equal(back.add_time_markers[0].name, "dusk")


def test_sync_world_clocks_remove_marker() raises:
    var pk = SyncWorldClocks()
    pk.payload_type = CLOCK_PAYLOAD_TYPE_REMOVE_TIME_MARKER
    pk.remove_clock_id = 9
    pk.remove_time_marker_ids = [1, 300, 70000]
    var back = _check(pk, "d80203090301ac02f0a204")
    _truncated[SyncWorldClocks]("d80203090301ac02f0a204")
    assert_equal(back.remove_time_marker_ids[2], 70000)
    var bad = SyncWorldClocks()
    bad.payload_type = 4
    with assert_raises(contains="clock payload type"):
        _ = encode_packet(bad)
    with assert_raises(contains="clock payload type"):
        _ = PacketData.parse(Span(hex_decode("d80204"))).decode[
            SyncWorldClocks
        ]()


def test_take_item_actor() raises:
    var pk = TakeItemActor()
    pk.item_entity_runtime_id = 1000
    pk.taker_entity_runtime_id = 2
    var back = _check(pk, "11e80702")
    _truncated[TakeItemActor]("11e80702")
    assert_equal(back.item_entity_runtime_id, 1000)


def test_ticking_areas_load_status() raises:
    var pk = TickingAreasLoadStatus()
    pk.preload = True
    var back = _check(pk, "b30101")
    _truncated[TickingAreasLoadStatus]("b30101")
    assert_true(back.preload)


def test_toast_request() raises:
    var pk = ToastRequest()
    pk.title = "Title"
    pk.message = "Message"
    var back = _check(pk, "ba01055469746c65074d657373616765")
    _truncated[ToastRequest]("ba01055469746c65074d657373616765")
    assert_equal(back.message, "Message")


def test_transfer_some() raises:
    var pk = Transfer()
    pk.address = "play.example.com"
    pk.port = 19132
    pk.reload_world = True
    var g = GatheringJoinInfo()
    g.experience_id = UUID.parse("00112233-4455-6677-8899-aabbccddeeff")
    g.experience_name = "Exp"
    g.creator_id = "c"
    g.target_id = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    g.server_id = String("srv")
    pk.gathering_join_info = g^
    var back = _check(
        pk,
        (
            "5510706c61792e6578616d706c652e636f6dbc4a01017766554433221100"
            "ffeeddccbbaa9988034578700000016301efcdab8967452301efcdab8967"
            "452301000103737276"
        ),
    )
    _truncated[Transfer](
        "5510706c61792e6578616d706c652e636f6dbc4a01017766554433221100"
        "ffeeddccbbaa9988034578700000016301efcdab8967452301efcdab8967"
        "452301000103737276"
    )
    assert_equal(back.port, 19132)
    assert_equal(back.gathering_join_info.value().server_id.value(), "srv")


def test_transfer_none() raises:
    var pk = Transfer()
    pk.address = "1.2.3.4"
    pk.port = 1
    var back = _check(pk, "5507312e322e332e3401000000")
    _truncated[Transfer]("5507312e322e332e3401000000")
    assert_true(back.gathering_join_info is None)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
