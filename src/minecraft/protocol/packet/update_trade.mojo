"""The `UpdateTrade` packet (gophertunnel `packet/update_trade.go`)."""

from ...nbt.nbt import NBT
from ..io import IO, actor_unique_id
from .id import ID_UPDATE_TRADE
from .packet import Packet


struct UpdateTrade(Packet):
    """Sent by the server to update the trades of a villager."""

    comptime ID: UInt32 = ID_UPDATE_TRADE
    """The packet ID."""
    var window_id: UInt8
    """The ID of the trading window."""
    var window_type: UInt8
    """The type of the window."""
    var size: Int32
    """Unused; zero in vanilla."""
    var trade_tier: Int32
    """The tier of the villager, from 0."""
    var villager_unique_id: Int64
    """The unique ID of the villager."""
    var entity_unique_id: Int64
    """The unique ID of the trading player."""
    var display_name: String
    """The name shown above the trades."""
    var new_trade_ui: Bool
    """Whether the new trade UI is used."""
    var demand_based_prices: Bool
    """Whether prices follow demand."""
    var serialised_offers: List[UInt8]
    """The offers as network NBT, to the end of the packet."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.window_type = 0
        self.size = 0
        self.trade_tier = 0
        self.villager_unique_id = 0
        self.entity_unique_id = 0
        self.display_name = String()
        self.new_trade_ui = False
        self.demand_based_prices = False
        self.serialised_offers = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.window_id)
        io.uint8(self.window_type)
        io.varint32(self.size)
        io.varint32(self.trade_tier)
        actor_unique_id(io, self.villager_unique_id)
        actor_unique_id(io, self.entity_unique_id)
        io.string(self.display_name)
        io.bool(self.new_trade_ui)
        io.bool(self.demand_based_prices)
        io.bytes(self.serialised_offers)
