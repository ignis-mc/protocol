from minecraft.protocol.server_join_information import (
    GatheringJoinInfo,
    PresenceInfo,
    ServerJoinInformation,
    StoreEntryPointInfo,
)
from minecraft.protocol.uuid import UUID
from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _hex[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _read[T: Marshaler](text: String) raises -> T:
    var raw = hex_decode(text)
    var r = Reader(Span(raw))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    return x^


def test_server_join_information() raises:
    var id = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    var g = GatheringJoinInfo()
    g.experience_id = id
    g.experience_name = "exp"
    g.target_id = id
    g.server_id = String("srv")
    var p = PresenceInfo()
    p.rich_presence_id = String("rp")
    var s = ServerJoinInformation()
    s.gathering_join_info = g^
    s.presence_info = p^
    assert_equal(
        _hex(s),
        (
            "01efcdab8967452301efcdab89674523010365787000000001efcdab89674523"
            "01efcdab8967452301000103737276000101027270"
        ),
    )
    var back = _read[ServerJoinInformation](
        "01efcdab8967452301efcdab89674523010365787000000001efcdab89674523"
        "01efcdab8967452301000103737276000101027270"
    )
    ref gathering = back.gathering_join_info.value()
    assert_equal(gathering.experience_name, "exp")
    assert_true(gathering.experience_world_id is None)
    assert_true(gathering.target_id.value() == id)
    assert_equal(gathering.server_id.value(), "srv")
    assert_true(back.store_entry_point_info is None)
    assert_equal(back.presence_info.value().rich_presence_id.value(), "rp")
    assert_equal(
        _hex(back),
        (
            "01efcdab8967452301efcdab89674523010365787000000001efcdab89674523"
            "01efcdab8967452301000103737276000101027270"
        ),
    )


def test_store_entry_point_and_truncation() raises:
    var e = StoreEntryPointInfo()
    e.store_id = "a"
    e.store_name = "b"
    assert_equal(_hex(e), "01610162")
    var empty = ServerJoinInformation()
    assert_equal(_hex(empty), "000000")
    with assert_raises():
        _ = _read[ServerJoinInformation]("01efcdab")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
