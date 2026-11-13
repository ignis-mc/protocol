from minecraft.protocol.io import Marshaler
from minecraft.protocol.reader import Reader
from minecraft.protocol.scoreboard import (
    SCOREBOARD_IDENTITY_FAKE_PLAYER,
    SCOREBOARD_IDENTITY_PLAYER,
    SCOREBOARD_IDENTITY_REMOVE,
    ScoreboardEntry,
    ScoreboardIdentityEntry,
)
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


def test_scoreboard_entry_variants() raises:
    var rm = ScoreboardEntry()
    rm.entry_id = 3
    rm.identity_type = SCOREBOARD_IDENTITY_REMOVE
    rm.objective_name = "obj"
    assert_equal(_hex(rm), "000672656d6f76650601036f626a")
    assert_equal(
        _read[ScoreboardEntry]("000672656d6f76650601036f626a").objective_name,
        "obj",
    )
    var empty = ScoreboardEntry()
    assert_equal(_hex(empty), "000672656d6f76650000")

    var p = ScoreboardEntry()
    p.entry_id = -1
    p.identity_type = SCOREBOARD_IDENTITY_PLAYER
    p.objective_name = "o"
    p.score = 10
    p.entity_unique_id = 9
    assert_equal(_hex(p), "010c6368616e6765706c6179657201016f0a00000012")
    var p2 = _read[ScoreboardEntry](
        "010c6368616e6765706c6179657201016f0a00000012"
    )
    assert_equal(p2.entity_unique_id, 9)
    assert_equal(p2.score, 10)

    var f = ScoreboardEntry()
    f.entry_id = 1
    f.identity_type = SCOREBOARD_IDENTITY_FAKE_PLAYER
    f.objective_name = "o"
    f.score = -2
    f.display_name = "line"
    assert_equal(
        _hex(f), "03106368616e676566616b65706c6179657202016ffeffffff046c696e65"
    )
    assert_equal(
        _read[ScoreboardEntry](
            "03106368616e676566616b65706c6179657202016ffeffffff046c696e65"
        ).display_name,
        "line",
    )


def test_scoreboard_entry_rejects_unknown_variant() raises:
    with assert_raises(contains="scoreboard entry variant"):
        _ = _read[ScoreboardEntry]("04")
    var bad = ScoreboardEntry()
    bad.identity_type = 7
    with assert_raises(contains="scoreboard entry variant"):
        _ = _hex(bad)


def test_scoreboard_identity_entry() raises:
    var e = ScoreboardIdentityEntry()
    e.entry_id = 4
    e.entity_unique_id = Int64(6)
    assert_equal(_hex(e), "08010c")
    assert_equal(
        _read[ScoreboardIdentityEntry]("08010c").entity_unique_id.value(),
        6,
    )
    var none = _read[ScoreboardIdentityEntry]("0800")
    assert_true(none.entity_unique_id is None)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
