"""The `EducationSettings` packet (gophertunnel `packet/education_settings.go`)."""

from ..education import (
    EducationAgentCapabilities,
    EducationExternalLinkSettings,
)
from ..io import IO, optional_marshaler, optional_string
from .id import ID_EDUCATION_SETTINGS
from .packet import Packet


struct EducationSettings(Packet):
    """A packet sent by the server to update Minecraft: Education Edition
    related settings.
    """

    comptime ID: UInt32 = ID_EDUCATION_SETTINGS
    """The packet ID."""
    var code_builder_default_uri: String
    """The default URI that the code builder is ran on."""
    var code_builder_title: String
    """The title of the code builder shown when connected to the
    CodeBuilderDefaultURI.
    """
    var can_resize_code_builder: Bool
    """Whether clients may resize the code builder."""
    var disable_legacy_title_bar: Bool
    """Whether the legacy title bar is disabled."""
    var post_process_filter: String
    """The post-processing filter."""
    var screenshot_border_path: String
    """The path of the screenshot border."""
    var agent_capabilities: Optional[EducationAgentCapabilities]
    """The capabilities of the agent in the world."""
    var override_uri: Optional[String]
    """A URI that overrides the code builder URI."""
    var has_quiz: Bool
    """Whether the world has a quiz connected to it."""
    var external_link_settings: Optional[EducationExternalLinkSettings]
    """The settings for external links."""

    def __init__(out self):
        """Creates the packet with every field zero."""
        self.code_builder_default_uri = String()
        self.code_builder_title = String()
        self.can_resize_code_builder = False
        self.disable_legacy_title_bar = False
        self.post_process_filter = String()
        self.screenshot_border_path = String()
        self.agent_capabilities = None
        self.override_uri = None
        self.has_quiz = False
        self.external_link_settings = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the packet's fields.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.code_builder_default_uri)
        io.string(self.code_builder_title)
        io.bool(self.can_resize_code_builder)
        io.bool(self.disable_legacy_title_bar)
        io.string(self.post_process_filter)
        io.string(self.screenshot_border_path)
        optional_marshaler(io, self.agent_capabilities)
        optional_string(io, self.override_uri)
        io.bool(self.has_quiz)
        optional_marshaler(io, self.external_link_settings)
