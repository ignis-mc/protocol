"""Scoreboard entries (gophertunnel `protocol/scoreboard.go`)."""

from .io import (
    IO,
    Marshaler,
    actor_unique_id,
    optional_string,
    unknown_enum_option,
)
from .misc_helpers import optional_actor_unique_id

comptime SCOREBOARD_IDENTITY_REMOVE: UInt8 = 0
"""Scoreboard identity: Remove."""
comptime SCOREBOARD_IDENTITY_PLAYER: UInt8 = 1
"""Scoreboard identity: Player."""
comptime SCOREBOARD_IDENTITY_ENTITY: UInt8 = 2
"""Scoreboard identity: Entity."""
comptime SCOREBOARD_IDENTITY_FAKE_PLAYER: UInt8 = 3
"""Scoreboard identity: Fake Player."""

comptime _SCOREBOARD_ENTRY_TYPE_NAMES: List[StaticString] = [
    "remove",
    "changeplayer",
    "changeentity",
    "changefakeplayer",
]


struct ScoreboardEntry(Marshaler):
    """One line on a scoreboard, as sent to modify it."""

    var entry_id: Int64
    """A unique identifier of the entry; the same line keeps its ID."""
    var objective_name: String
    """The objective set earlier with `SetDisplayObjective`."""
    var score: Int32
    """The score; entries are ordered by it."""
    var identity_type: UInt8
    """One of the `SCOREBOARD_IDENTITY_*` values."""
    var entity_unique_id: Int64
    """The player or entity shown, for the player and entity identities."""
    var display_name: String
    """The text shown, for the fake-player identity."""

    def __init__(out self):
        """Creates a removal entry with zero fields."""
        self.entry_id = 0
        self.objective_name = String()
        self.score = 0
        self.identity_type = SCOREBOARD_IDENTITY_REMOVE
        self.entity_unique_id = 0
        self.display_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        A varuint32 variant and its name precede the fields of that variant.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the variant is unknown.
        """
        var variant = UInt32(self.identity_type)
        io.varuint32(variant)
        self.identity_type = UInt8(variant & 0xFF)
        ref names = materialize[_SCOREBOARD_ENTRY_TYPE_NAMES]()
        if Int(variant) >= len(names):
            unknown_enum_option(Int(variant), "scoreboard entry variant")
        var type_name = String(names[Int(variant)])
        io.string(type_name)
        io.varint64(self.entry_id)
        if self.identity_type == SCOREBOARD_IDENTITY_REMOVE:
            var objective = Optional[String](None)
            if self.objective_name.byte_length() > 0:
                objective = self.objective_name.copy()
            optional_string(io, objective)
            self.objective_name = objective.or_else(String())
        elif (
            self.identity_type == SCOREBOARD_IDENTITY_ENTITY
            or self.identity_type == SCOREBOARD_IDENTITY_PLAYER
        ):
            io.string(self.objective_name)
            io.int32(self.score)
            actor_unique_id(io, self.entity_unique_id)
        elif self.identity_type == SCOREBOARD_IDENTITY_FAKE_PLAYER:
            io.string(self.objective_name)
            io.int32(self.score)
            io.string(self.display_name)


struct ScoreboardIdentityEntry(Marshaler):
    """Associates an entity with a scoreboard entry, or clears it."""

    var entry_id: Int64
    """The entry to associate or clear."""
    var entity_unique_id: Optional[Int64]
    """The entity to associate, if any."""

    def __init__(out self):
        """Creates an entry without an entity."""
        self.entry_id = 0
        self.entity_unique_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint64(self.entry_id)
        optional_actor_unique_id(io, self.entity_unique_id)
