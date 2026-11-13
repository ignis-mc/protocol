"""The `ModalFormResponse` packet (gophertunnel `packet/modal_form_response.go`).
"""

from ..io import IO, optional_func
from .id import ID_MODAL_FORM_RESPONSE
from .packet import Packet

comptime MODAL_FORM_CANCEL_REASON_USER_CLOSED: UInt8 = 0
"""The player closed the form."""
comptime MODAL_FORM_CANCEL_REASON_USER_BUSY: UInt8 = 1
"""The player was busy, for example in another screen."""


struct ModalFormResponse(Packet):
    """Sent by the client after the player submitted or closed a form."""

    comptime ID: UInt32 = ID_MODAL_FORM_RESPONSE
    """The packet ID."""
    var form_id: UInt32
    """The ID from the `ModalFormRequest`."""
    var response_data: Optional[List[UInt8]]
    """The JSON encoded response, if the form was submitted."""
    var cancel_reason: Optional[UInt8]
    """One of the `MODAL_FORM_CANCEL_REASON_*` values, if cancelled."""

    def __init__(out self):
        """Creates the packet with every field empty."""
        self.form_id = 0
        self.response_data = None
        self.cancel_reason = None

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
        optional_func[I.byte_slice](io, self.response_data)
        optional_func[I.uint8](io, self.cancel_reason)
