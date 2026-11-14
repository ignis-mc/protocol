"""The `LessonProgress` packet (gophertunnel `packet/lesson_progress.go`)."""

from ..io import IO
from .id import ID_LESSON_PROGRESS
from .packet import Packet

comptime LESSON_ACTION_START: Int32 = 0
"""The lesson start action."""
comptime LESSON_ACTION_COMPLETE: Int32 = 1
"""The lesson complete action."""
comptime LESSON_ACTION_RESTART: Int32 = 2
"""The lesson restart action."""


struct LessonProgress(Packet):
    """A packet sent by the server to the client to inform the client of updated
    progress on a lesson.
    """

    comptime ID: UInt32 = ID_LESSON_PROGRESS
    """The packet ID."""
    var identifier: String
    """The identifier of the lesson that is being progressed."""
    var action: Int32
    """The action the client should perform to show progress."""
    var score: Int32
    """The score the client should use when displaying the progress."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.identifier = String()
        self.action = 0
        self.score = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.varint32(self.action)
        io.varint32(self.score)
        io.string(self.identifier)
