"""The `PurchaseReceipt` packet (gophertunnel `packet/purchase_receipt.go`)."""

from ..io import IO, func_slice
from .id import ID_PURCHASE_RECEIPT
from .packet import Packet


struct PurchaseReceipt(Packet):
    """Sent by the client after buying a server's Marketplace offer.

    Only partnered servers use it.
    """

    comptime ID: UInt32 = ID_PURCHASE_RECEIPT
    """The packet ID."""
    var receipts: List[String]
    """Proofs of purchase for the offers bought."""

    def __init__(out self):
        """Creates the packet with no receipts."""
        self.receipts = List[String]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        func_slice[I.string](io, self.receipts)
