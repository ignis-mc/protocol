"""Optional join details (gophertunnel `server_join_information.go`)."""

from .io import IO, Marshaler, optional_marshaler, optional_string, uuid
from .io import optional_uuid
from .uuid import UUID


struct GatheringJoinInfo(Marshaler):
    """The gathering (experience) the player is joining."""

    var experience_id: UUID
    """The experience's UUID."""
    var experience_name: String
    """The experience's name."""
    var experience_world_id: Optional[UUID]
    """The experience world's UUID."""
    var experience_world_name: Optional[String]
    """The experience world's name."""
    var creator_id: String
    """The creator's ID."""
    var target_id: Optional[UUID]
    """The experience's session ID."""
    var scenario_id: Optional[String]
    """The experience's scenario ID."""
    var server_id: Optional[String]
    """The server identifier."""

    def __init__(out self):
        """Creates a zero value."""
        self.experience_id = UUID()
        self.experience_name = String()
        self.experience_world_id = None
        self.experience_world_name = None
        self.creator_id = String()
        self.target_id = None
        self.scenario_id = None
        self.server_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the information."""
        uuid(io, self.experience_id)
        io.string(self.experience_name)
        optional_uuid(io, self.experience_world_id)
        optional_string(io, self.experience_world_name)
        io.string(self.creator_id)
        optional_uuid(io, self.target_id)
        optional_string(io, self.scenario_id)
        optional_string(io, self.server_id)


struct StoreEntryPointInfo(Marshaler):
    """The store entry point."""

    var store_id: String
    """The store identifier."""
    var store_name: String
    """The store name."""

    def __init__(out self):
        """Creates a zero value."""
        self.store_id = String()
        self.store_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the information."""
        io.string(self.store_id)
        io.string(self.store_name)


struct PresenceInfo(Marshaler):
    """Presence information about the experience."""

    var rich_presence_id: Optional[String]
    """A rich presence ID overriding the client's own."""

    def __init__(out self):
        """Creates a zero value."""
        self.rich_presence_id = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the information."""
        optional_string(io, self.rich_presence_id)


struct ServerJoinInformation(Marshaler):
    """Optional information about the server being joined."""

    var gathering_join_info: Optional[GatheringJoinInfo]
    """The gathering being joined."""
    var store_entry_point_info: Optional[StoreEntryPointInfo]
    """The store entry point."""
    var presence_info: Optional[PresenceInfo]
    """Presence information."""

    def __init__(out self):
        """Creates a zero value."""
        self.gathering_join_info = None
        self.store_entry_point_info = None
        self.presence_info = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the information."""
        optional_marshaler(io, self.gathering_join_info)
        optional_marshaler(io, self.store_entry_point_info)
        optional_marshaler(io, self.presence_info)
