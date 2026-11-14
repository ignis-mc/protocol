"""The `GameRulesChanged` packet (gophertunnel `packet/game_rules_changed.go`)."""

from ..game_rule import GameRule, game_rule
from ..io import IO, func_slice
from .id import ID_GAME_RULES_CHANGED
from .packet import Packet


struct GameRulesChanged(Packet):
    """Sent by the server to the client to update client-side game rules, such
    as game rules like the 'showCoordinates' game rule.
    """

    comptime ID: UInt32 = ID_GAME_RULES_CHANGED
    """The packet ID."""
    var game_rules: List[GameRule]
    """The changed game rules with their new values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.game_rules = List[GameRule]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        func_slice[game_rule[I]](io, self.game_rules)
