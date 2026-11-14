"""Education Edition settings (gophertunnel `protocol/education.go`)."""

from .io import IO, Marshaler, optional_bool


struct EducationSharedResourceURI(Marshaler):
    """An Education Edition resource link: a button name and a URI."""

    var button_name: String
    """The button name."""
    var link_uri: String
    """The link URI."""

    def __init__(out self):
        """Creates a zero value."""
        self.button_name = String()
        self.link_uri = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value."""
        io.string(self.button_name)
        io.string(self.link_uri)


struct EducationAgentCapabilities(Marshaler):
    """The capabilities of the agent in an Education Edition world."""

    var can_modify_blocks: Optional[Bool]
    """Whether the agent can modify blocks."""

    def __init__(out self):
        """Creates a zero value."""
        self.can_modify_blocks = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value."""
        optional_bool(io, self.can_modify_blocks)


struct EducationExternalLinkSettings(Marshaler):
    """An external link shown in Education Edition."""

    var url: String
    """The link URL."""
    var display_name: String
    """The name shown in game."""

    def __init__(out self):
        """Creates a zero value."""
        self.url = String()
        self.display_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value."""
        io.string(self.url)
        io.string(self.display_name)
