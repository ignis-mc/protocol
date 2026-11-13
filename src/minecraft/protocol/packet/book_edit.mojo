"""The `BookEdit` packet (gophertunnel `packet/book_edit.go`)."""

from ..io import IO, unknown_enum_option
from .id import ID_BOOK_EDIT
from .packet import Packet

comptime BOOK_ACTION_REPLACE_PAGE: UInt32 = 0
"""Go `BookActionReplacePage`."""
comptime BOOK_ACTION_ADD_PAGE: UInt32 = 1
"""Go `BookActionAddPage`."""
comptime BOOK_ACTION_DELETE_PAGE: UInt32 = 2
"""Go `BookActionDeletePage`."""
comptime BOOK_ACTION_SWAP_PAGES: UInt32 = 3
"""Go `BookActionSwapPages`."""
comptime BOOK_ACTION_SIGN: UInt32 = 4
"""Go `BookActionSign`."""


struct BookEdit(Packet):
    """Sent by the client when it edits a book."""

    comptime ID: UInt32 = ID_BOOK_EDIT
    """The packet ID."""
    var inventory_slot: Int32
    """The slot holding the edited book."""
    var action_type: UInt32
    """One of the `BOOK_ACTION_*` values."""
    var page_number: Int32
    """The page the action concerns, for all but signing."""
    var secondary_page_number: Int32
    """The other page, for `BOOK_ACTION_SWAP_PAGES`."""
    var text: String
    """The page text, for adding and replacing pages."""
    var photo_name: String
    """The page photo, for adding and replacing pages."""
    var title: String
    """The book title, for signing."""
    var author: String
    """The book author, for signing; freely chosen."""
    var xuid: String
    """The XUID of the editing player."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.inventory_slot = 0
        self.action_type = 0
        self.page_number = 0
        self.secondary_page_number = 0
        self.text = String()
        self.photo_name = String()
        self.title = String()
        self.author = String()
        self.xuid = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.inventory_slot)
        io.varuint32(self.action_type)
        if (
            self.action_type == BOOK_ACTION_REPLACE_PAGE
            or self.action_type == BOOK_ACTION_ADD_PAGE
        ):
            io.varint32(self.page_number)
            io.string(self.text)
            io.string(self.photo_name)
        elif self.action_type == BOOK_ACTION_DELETE_PAGE:
            io.varint32(self.page_number)
        elif self.action_type == BOOK_ACTION_SWAP_PAGES:
            io.varint32(self.page_number)
            io.varint32(self.secondary_page_number)
        elif self.action_type == BOOK_ACTION_SIGN:
            io.string(self.title)
            io.string(self.author)
            io.string(self.xuid)
        else:
            unknown_enum_option(Int(self.action_type), "book edit action type")
