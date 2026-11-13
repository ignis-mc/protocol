"""The `PlayerEnchantOptions` packet (gophertunnel `packet/player_enchant_options.go`).
"""

from ..enchant import EnchantmentOption
from ..io import IO, slice
from .id import ID_PLAYER_ENCHANT_OPTIONS
from .packet import Packet


struct PlayerEnchantOptions(Packet):
    """Sent by the server to set the options shown in an enchantment table.

    Vanilla sends an empty list when the table opens and the real options
    once an enchantable item is put in.
    """

    comptime ID: UInt32 = ID_PLAYER_ENCHANT_OPTIONS
    """The packet ID."""
    var options: List[EnchantmentOption]
    """The enchantment options for the item in the table."""

    def __init__(out self):
        """Creates the packet with no options."""
        self.options = List[EnchantmentOption]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.options)
