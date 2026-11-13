"""The `CodeBuilderSource` packet (gophertunnel `packet/code_builder_source.go`)."""

from ..io import IO
from .id import ID_CODE_BUILDER_SOURCE
from .packet import Packet

comptime CODE_BUILDER_OPERATION_NONE: UInt8 = 0
"""Go `CodeBuilderOperationNone`."""
comptime CODE_BUILDER_OPERATION_GET: UInt8 = 1
"""Go `CodeBuilderOperationGet`."""
comptime CODE_BUILDER_OPERATION_SET: UInt8 = 2
"""Go `CodeBuilderOperationSet`."""
comptime CODE_BUILDER_OPERATION_RESET: UInt8 = 3
"""Go `CodeBuilderOperationReset`."""
comptime CODE_BUILDER_CATEGORY_NONE: UInt8 = 0
"""Go `CodeBuilderCategoryNone`."""
comptime CODE_BUILDER_CATEGORY_STATUS: UInt8 = 1
"""Go `CodeBuilderCategoryStatus`."""
comptime CODE_BUILDER_CATEGORY_INSTANTIATION: UInt8 = 2
"""Go `CodeBuilderCategoryInstantiation`."""
comptime CODE_BUILDER_STATUS_NONE: UInt8 = 0
"""Go `CodeBuilderStatusNone`."""
comptime CODE_BUILDER_STATUS_NOT_STARTED: UInt8 = 1
"""Go `CodeBuilderStatusNotStarted`."""
comptime CODE_BUILDER_STATUS_IN_PROGRESS: UInt8 = 2
"""Go `CodeBuilderStatusInProgress`."""
comptime CODE_BUILDER_STATUS_PAUSED: UInt8 = 3
"""Go `CodeBuilderStatusPaused`."""
comptime CODE_BUILDER_STATUS_ERROR: UInt8 = 4
"""Go `CodeBuilderStatusError`."""
comptime CODE_BUILDER_STATUS_SUCCEEDED: UInt8 = 5
"""Go `CodeBuilderStatusSucceeded`."""


struct CodeBuilderSource(Packet):
    """Education Edition: the client runs an operation with a code builder."""

    comptime ID: UInt32 = ID_CODE_BUILDER_SOURCE
    """The packet ID."""
    var operation: UInt8
    """One of the `CODE_BUILDER_OPERATION_*` values."""
    var category: UInt8
    """One of the `CODE_BUILDER_CATEGORY_*` values."""
    var code_status: UInt8
    """One of the `CODE_BUILDER_STATUS_*` values."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.operation = 0
        self.category = 0
        self.code_status = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.operation)
        io.uint8(self.category)
        io.uint8(self.code_status)
