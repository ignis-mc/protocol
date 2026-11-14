"""The `ContainerSetData` packet (gophertunnel `packet/container_set_data.go`)."""

from ..io import IO
from .id import ID_CONTAINER_SET_DATA
from .packet import Packet

comptime CONTAINER_DATA_FURNACE_TICK_COUNT: Int32 = 0
"""The furnace tick count key."""
comptime CONTAINER_DATA_FURNACE_LIT_TIME: Int32 = 1
"""The furnace lit time key."""
comptime CONTAINER_DATA_FURNACE_LIT_DURATION: Int32 = 2
"""The furnace lit duration key."""
comptime CONTAINER_DATA_FURNACE_FUEL_AUX: Int32 = 4
"""The furnace fuel aux key."""

comptime CONTAINER_DATA_BREWING_STAND_BREW_TIME: Int32 = 0
"""The brewing stand brew time key."""
comptime CONTAINER_DATA_BREWING_STAND_FUEL_AMOUNT: Int32 = 1
"""The brewing stand fuel amount key."""
comptime CONTAINER_DATA_BREWING_STAND_FUEL_TOTAL: Int32 = 2
"""The brewing stand fuel total key."""


struct ContainerSetData(Packet):
    """Sent by the server to update specific data of a single container, meaning
    a block such as a furnace or a brewing stand.
    """

    comptime ID: UInt32 = ID_CONTAINER_SET_DATA
    """The packet ID."""
    var window_id: UInt8
    """The ID of the window that should have its data set."""
    var key: Int32
    """The key of the property."""
    var value: Int32
    """The value of the property."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.window_id = 0
        self.key = 0
        self.value = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        io.uint8(self.window_id)
        io.varint32(self.key)
        io.varint32(self.value)
