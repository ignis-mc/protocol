from minecraft.protocol.block_pos import BlockPos
from minecraft.protocol.entity_link import (
    ENTITY_LINK_PASSENGER,
    PASSENGER_OF_BLOCK_EMOTE_LAYING,
    EntityLink,
    PassengerOfBlockData,
)
from minecraft.protocol.math import Vec3
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def test_entity_link_matches_gophertunnel() raises:
    var l = EntityLink()
    l.ridden_entity_unique_id = 5
    l.rider_entity_unique_id = -6
    l.type = ENTITY_LINK_PASSENGER
    l.immediate = True
    l.vehicle_angular_velocity = 0.5
    var w = Writer()
    l.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), "0a0b0201000000003f")
    var raw = hex_decode("0a0b0201000000003f")
    var r = Reader(Span(raw))
    var back = EntityLink()
    back.marshal(r)
    assert_equal(back.rider_entity_unique_id, -6)
    assert_true(back.immediate)


def test_passenger_of_block_matches_gophertunnel() raises:
    comptime expected = "028001050000003f00000000000000bf0000b4420000344302"
    var p = PassengerOfBlockData()
    p.block_position = BlockPos(1, 64, -3)
    p.offset = Vec3(0.5, 0, -0.5)
    p.rotation = 90
    p.rotation_limit = 180
    p.emote_type = PASSENGER_OF_BLOCK_EMOTE_LAYING
    var w = Writer()
    p.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = PassengerOfBlockData()
    back.marshal(r)
    assert_true(back.block_position == BlockPos(1, 64, -3))
    var short = hex_decode("0a0b02")
    var r2 = Reader(Span(short))
    var l = EntityLink()
    with assert_raises():
        l.marshal(r2)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
