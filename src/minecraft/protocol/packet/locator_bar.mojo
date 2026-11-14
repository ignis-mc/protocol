"""The `LocatorBar` packet (gophertunnel `packet/locator_bar.go`)."""

from ..io import IO, slice
from ..waypoint import LocatorBarWaypoint
from .id import ID_LOCATOR_BAR
from .packet import Packet


struct LocatorBar(Packet):
    """Sent by the server to add, remove or update waypoints on the client's
    locator bar.
    """

    comptime ID: UInt32 = ID_LOCATOR_BAR
    """The packet ID."""
    var waypoints: List[LocatorBarWaypoint]
    """A slice of waypoints to add, remove or update."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.waypoints = List[LocatorBarWaypoint]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields."""
        slice(io, self.waypoints)
