"""Resource packs and pack settings (gophertunnel `resource_pack.go`)."""

from std.utils import Variant

from .io import IO, Marshaler, string_slice, unknown_enum_option, uuid
from .uuid import UUID

comptime PACK_SETTING_TYPE_FLOAT: UInt32 = 0
"""A Float pack setting value."""
comptime PACK_SETTING_TYPE_BOOL: UInt32 = 1
"""A Bool pack setting value."""
comptime PACK_SETTING_TYPE_STRING: UInt32 = 2
"""A String pack setting value."""
comptime PACK_SETTING_TYPE_STRING_LIST: UInt32 = 3
"""A String List pack setting value."""


struct TexturePackInfo(Marshaler):
    """A texture pack offered by the server."""

    var uuid: UUID
    """The pack's UUID; every downloaded pack needs a different one."""
    var version: String
    """The pack version; a new version forces a re-download."""
    var size: UInt64
    """The size of the pack's zip archive in bytes."""
    var content_key: String
    """The key to decrypt an encrypted (marketplace) pack."""
    var sub_pack_name: String
    """The name of the sub-pack."""
    var content_identity: String
    """Another UUID for the pack, needed to validate encrypted packs."""
    var has_scripts: Bool
    """Whether the pack contains scripts."""
    var addon_pack: Bool
    """Whether the pack is from an addon."""
    var rtx_enabled: Bool
    """Whether the pack uses ray tracing."""
    var download_url: String
    """A URL to download the pack from instead of the server sending it."""

    def __init__(out self):
        """Creates an empty description."""
        self.uuid = UUID()
        self.version = String()
        self.size = 0
        self.content_key = String()
        self.sub_pack_name = String()
        self.content_identity = String()
        self.has_scripts = False
        self.addon_pack = False
        self.rtx_enabled = False
        self.download_url = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the description.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        uuid(io, self.uuid)
        io.string(self.version)
        io.uint64(self.size)
        io.string(self.content_key)
        io.string(self.sub_pack_name)
        io.string(self.content_identity)
        io.bool(self.has_scripts)
        io.bool(self.addon_pack)
        io.bool(self.rtx_enabled)
        io.string(self.download_url)


struct StackResourcePack(Marshaler):
    """A resource pack on the client's pack stack."""

    var uuid: String
    """The pack's UUID."""
    var version: String
    """The pack version."""
    var sub_pack_name: String
    """The name of the sub-pack."""

    def __init__(out self):
        """Creates an empty entry."""
        self.uuid = String()
        self.version = String()
        self.sub_pack_name = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.uuid)
        io.string(self.version)
        io.string(self.sub_pack_name)


struct PackURL(Marshaler):
    """A resource pack served over HTTP."""

    var uuid_version: String
    """The pack as `UUID_Version`."""
    var url: String
    """The URL of a zip with the manifest inside a folder."""

    def __init__(out self):
        """Creates an empty entry."""
        self.uuid_version = String()
        self.url = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the entry.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.uuid_version)
        io.string(self.url)


comptime PackSettingValue = Variant[Float32, Bool, String, List[String]]
"""The value of a pack setting (gophertunnel `any`): one of the four types."""


struct PackSetting(Marshaler):
    """A setting changed in the pack settings UI.

    `marshal` is gophertunnel's `IO.PackSetting`: a varuint32 type ID
    selects the arm of `value`.
    """

    var name: String
    """The setting's name."""
    var value: PackSettingValue
    """The new value."""

    def __init__(out self):
        """Creates an unnamed setting with the value `0.0`."""
        self.name = String()
        self.value = PackSettingValue(Float32(0))

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the setting.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or the type ID is unknown.
        """
        pack_setting(io, self)


def pack_setting[I: IO](mut io: I, mut x: PackSetting) raises:
    """Marshals a pack setting (gophertunnel `IO.PackSetting`).

    Parameters:
        I: The reader or writer type.

    Args:
        io: The reader or writer.
        x: The setting.

    Raises:
        If the input is malformed or the type ID is unknown.
    """
    io.string(x.name)
    var id = UInt32(0)
    if not io.reads():
        if x.value.isa[Float32]():
            id = PACK_SETTING_TYPE_FLOAT
        elif x.value.isa[Bool]():
            id = PACK_SETTING_TYPE_BOOL
        elif x.value.isa[String]():
            id = PACK_SETTING_TYPE_STRING
        else:
            id = PACK_SETTING_TYPE_STRING_LIST
    io.varuint32(id)
    if id == PACK_SETTING_TYPE_FLOAT:
        var v = x.value[Float32] if x.value.isa[Float32]() else Float32(0)
        io.float32(v)
        x.value = PackSettingValue(v)
    elif id == PACK_SETTING_TYPE_BOOL:
        var v = x.value[Bool] if x.value.isa[Bool]() else False
        io.bool(v)
        x.value = PackSettingValue(v)
    elif id == PACK_SETTING_TYPE_STRING:
        var v = x.value[String].copy() if x.value.isa[String]() else String()
        io.string(v)
        x.value = PackSettingValue(v^)
    elif id == PACK_SETTING_TYPE_STRING_LIST:
        var v = x.value[List[String]].copy() if x.value.isa[
            List[String]
        ]() else List[String]()
        string_slice(io, v)
        x.value = PackSettingValue(v^)
    else:
        unknown_enum_option(Int(id), "pack setting")
