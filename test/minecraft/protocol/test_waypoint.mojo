from minecraft.protocol.math import Vec2, Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.uuid import UUID
from minecraft.protocol.waypoint import (
    WAYPOINT_ACTION_UPDATE,
    WAYPOINT_UPDATE_FLAG_POSITION,
    WAYPOINT_UPDATE_FLAG_VISIBLE,
    LocatorBarWaypoint,
    WaypointWorldPosition,
)
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_locator_bar_waypoint() raises:
    var l = LocatorBarWaypoint()
    l.group_handle = UUID.parse("01234567-89ab-cdef-0123-456789abcdef")
    l.action = WAYPOINT_ACTION_UPDATE
    l.waypoint.update_flag = (
        WAYPOINT_UPDATE_FLAG_VISIBLE | WAYPOINT_UPDATE_FLAG_POSITION
    )
    l.waypoint.visible = True
    var pos = WaypointWorldPosition()
    pos.position = Vec3(1, 2, 3)
    pos.dimension_id = 1
    l.waypoint.world_position = pos^
    l.waypoint.icon_size = Vec2(4, 5)
    l.waypoint.colour = Int32(0xFF00)
    l.waypoint.actor_unique_id = Int64(-3)
    var w = Writer()
    l.marshal(w)
    var expected = (
        "efcdab8967452301efcdab8967452301030000000101010000803f0000004000"
        "004040020001000080400000a0400100ff000000010503"
    )
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = LocatorBarWaypoint()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.action, WAYPOINT_ACTION_UPDATE)
    assert_true(back.waypoint.visible.value())
    assert_equal(back.waypoint.world_position.value().dimension_id, 1)
    assert_true(back.waypoint.texture_path is None)
    assert_equal(back.waypoint.icon_size.value().y, 5)
    assert_equal(back.waypoint.actor_unique_id.value(), -3)
    var truncated = Reader(Span(raw)[:30])
    var bad = LocatorBarWaypoint()
    with assert_raises():
        bad.marshal(truncated)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
