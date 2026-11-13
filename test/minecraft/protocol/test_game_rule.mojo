from minecraft.protocol.game_rule import GameRule, GameRuleValue, game_rule
from minecraft.protocol.io import slice
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true


def _check(var rule: GameRule, expected: String) raises -> GameRule:
    var w = Writer()
    game_rule(w, rule)
    assert_equal(hex_encode(Span(w.buf)), expected)
    var raw = hex_decode(expected)
    var r = Reader(Span(raw))
    var back = GameRule()
    game_rule(r, back)
    assert_equal(r.remaining(), 0)
    assert_equal(back.name, rule.name)
    assert_equal(back.can_be_modified_by_player, rule.can_be_modified_by_player)
    return back^


def test_null_rule() raises:
    var back = _check(GameRule("null", False, None), "046e756c6c0000")
    assert_true(back.value is None)


def test_bool_rule() raises:
    var back = _check(
        GameRule("doDaylightCycle", True, GameRuleValue(True)),
        "0f646f4461796c696768744379636c65010101",
    )
    assert_true(back.value.value()[Bool])


def test_uint32_rule() raises:
    var back = _check(
        GameRule("randomTickSpeed", True, GameRuleValue(UInt32(3))),
        "0f72616e646f6d5469636b5370656564010203000000",
    )
    assert_equal(back.value.value()[UInt32], 3)


def test_float32_rule() raises:
    var back = _check(
        GameRule("f", False, GameRuleValue(Float32(0.5))), "016600030000003f"
    )
    assert_equal(back.value.value()[Float32], 0.5)


def test_rule_list_uses_marshal() raises:
    var rules: List[GameRule] = [
        GameRule("null", False, None),
        GameRule("f", False, GameRuleValue(Float32(0.5))),
    ]
    var w = Writer()
    slice(w, rules)
    assert_equal(
        hex_encode(Span(w.buf)), "02" + "046e756c6c0000" + "016600030000003f"
    )


def test_unknown_rule_type_is_rejected() raises:
    # Go: unknown value '0x4' for enum type 'game rule type'.
    var raw = hex_decode("0161" + "00" + "04")
    var r = Reader(Span(raw))
    var x = GameRule()
    with assert_raises(contains="game rule type"):
        game_rule(r, x)


def test_truncated_rule_is_rejected() raises:
    var raw = hex_decode("0161" + "00" + "02" + "0300")
    var r = Reader(Span(raw))
    var x = GameRule()
    with assert_raises():
        game_rule(r, x)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
