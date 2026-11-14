"""Game rules (gophertunnel `protocol/game_rule.go`).

The Go `Value any` holds a `bool`, a `uint32`, a `float32` or `nil`. Here it
is `Optional[GameRuleValue]`, with `None` for the null variant. `game_rule`
ports the Go `IO.GameRule` method; `GameRule.marshal` calls it so lists of
game rules work with `slice`.
"""

from std.utils import Variant

from .io import IO, Marshaler, unknown_enum_option

comptime GameRuleValue = Variant[Bool, UInt32, Float32]
"""The value of a game rule: a `Bool`, a `UInt32` or a `Float32`."""

comptime _GAME_RULE_TYPE_NULL: UInt32 = 0
comptime _GAME_RULE_TYPE_BOOL: UInt32 = 1
comptime _GAME_RULE_TYPE_INT: UInt32 = 2
comptime _GAME_RULE_TYPE_FLOAT: UInt32 = 3


struct GameRule(Marshaler):
    """A game rule and its value."""

    var name: String
    """The name of the game rule."""
    var can_be_modified_by_player: Bool
    """Whether the player can change the rule in the in-game UI."""
    var value: Optional[GameRuleValue]
    """The value, or `None` for the null variant."""

    def __init__(out self):
        """Creates a nameless rule with a null value."""
        self.name = String()
        self.can_be_modified_by_player = False
        self.value = None

    def __init__(
        out self,
        name: String,
        can_be_modified_by_player: Bool,
        var value: Optional[GameRuleValue],
    ):
        """Creates a game rule."""
        self.name = name
        self.can_be_modified_by_player = can_be_modified_by_player
        self.value = value^

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the rule (see `game_rule`)."""
        game_rule(io, self)


def game_rule[I: IO](mut io: I, mut x: GameRule) raises:
    """Marshals a name, a flag, a varuint32 type and the value of that type.

    This is gophertunnel `IO.GameRule`.
    """
    io.string(x.name)
    io.bool(x.can_be_modified_by_player)
    var t = _GAME_RULE_TYPE_NULL
    var b = False
    var u = UInt32(0)
    var f = Float32(0)
    if case .Some(ref v) = x.value:
        if v.isa[Bool]():
            t = _GAME_RULE_TYPE_BOOL
            b = v[Bool]
        elif v.isa[UInt32]():
            t = _GAME_RULE_TYPE_INT
            u = v[UInt32]
        else:
            t = _GAME_RULE_TYPE_FLOAT
            f = v[Float32]
    io.varuint32(t)
    if t == _GAME_RULE_TYPE_NULL:
        if io.reads():
            x.value = None
    elif t == _GAME_RULE_TYPE_BOOL:
        io.bool(b)
        if io.reads():
            x.value = GameRuleValue(b)
    elif t == _GAME_RULE_TYPE_INT:
        io.uint32(u)
        if io.reads():
            x.value = GameRuleValue(u)
    elif t == _GAME_RULE_TYPE_FLOAT:
        io.float32(f)
        if io.reads():
            x.value = GameRuleValue(f)
    else:
        unknown_enum_option(Int(t), "game rule type")
