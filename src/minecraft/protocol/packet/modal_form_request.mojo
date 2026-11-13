"""The `ModalFormRequest` packet (gophertunnel `packet/modal_form_request.go`).
"""

from ..io import IO
from .id import ID_MODAL_FORM_REQUEST
from .packet import Packet


struct ModalFormRequest(Packet):
    """Sent by the server to make the client open a modal, menu or custom form.
    """

    comptime ID: UInt32 = ID_MODAL_FORM_REQUEST
    """The packet ID."""
    var form_id: UInt32
    """The ID the client sends back with its response."""
    var form_data: List[UInt8]
    """The JSON encoded form."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.form_id = 0
        self.form_data = List[UInt8]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varuint32(self.form_id)
        io.byte_slice(self.form_data)
