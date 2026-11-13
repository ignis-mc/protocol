"""The `ServerBoundPackSettingChange` packet (gophertunnel `packet/server_bound_pack_setting_change.go`).
"""

from ..io import IO, uuid
from ..resource_pack import PackSetting, pack_setting
from ..uuid import UUID
from .id import ID_SERVER_BOUND_PACK_SETTING_CHANGE
from .packet import Packet


struct ServerBoundPackSettingChange(Packet):
    """Sent by the client when it changes a pack's setting in the pack UI."""

    comptime ID: UInt32 = ID_SERVER_BOUND_PACK_SETTING_CHANGE
    """The packet ID."""
    var pack_id: UUID
    """The UUID of the pack."""
    var pack_setting: PackSetting
    """The new setting value."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.pack_id = UUID()
        self.pack_setting = PackSetting()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        uuid(io, self.pack_id)
        pack_setting(io, self.pack_setting)
