"""Identity and client data sent in the login request (gophertunnel
`login/data.go`).

Only what a client needs to send is modelled here; servers that verify
logins need the parser too (TODO: port `login.Parse`).
"""

from nethernet.json import json_quote

comptime DEVICE_ANDROID: Int = 1
"""`protocol.DeviceAndroid`."""
comptime INPUT_MODE_MOUSE: Int = 1
"""Keyboard and mouse."""
comptime INPUT_MODE_TOUCH: Int = 2
"""Touch screen."""


struct IdentityData(Copyable, Defaultable):
    """The player's identity, for offline logins (gophertunnel `IdentityData`).

    Online logins take it from the Xbox Live chain instead.
    """

    var xuid: String
    """The Xbox user ID; empty offline."""
    var identity: String
    """The player's UUID in canonical text form."""
    var display_name: String
    """The player's name."""
    var title_id: String
    """The title ID of the game edition."""
    var playfab_id: String
    """The PlayFab ID; may be empty offline."""
    var playfab_title_id: String
    """The PlayFab title ID; may be empty offline."""

    def __init__(out self):
        """Creates empty identity data."""
        self.xuid = String()
        self.identity = String()
        self.display_name = String()
        self.title_id = String()
        self.playfab_id = String()
        self.playfab_title_id = String()


def _field(mut out: String, name: StringSpan, value: StringSpan):
    out += json_quote(name)
    out += ":"
    out += json_quote(value)
    out += ","


def _field_int(mut out: String, name: StringSpan, value: Int):
    out += json_quote(name)
    out += ":"
    out += String(value)
    out += ","


def _field_bool(mut out: String, name: StringSpan, value: Bool):
    out += json_quote(name)
    out += ":true," if value else ":false,"


struct ClientData(Copyable, Defaultable):
    """Client settings and skin, signed into the login request
    (gophertunnel `ClientData`).

    Skin animations, persona pieces and tint colours are always sent empty.
    """

    var cape_data: String
    """Base64 RGBA cape image; empty for none."""
    var cape_id: String
    """The cape's ID."""
    var cape_image_height: Int
    """The cape image height."""
    var cape_image_width: Int
    """The cape image width."""
    var cape_on_classic_skin: Bool
    """Whether the cape is worn on a classic skin."""
    var client_random_id: Int64
    """A random ID chosen per launch."""
    var current_input_mode: Int
    """The active input mode, one of the `INPUT_MODE_*` values."""
    var default_input_mode: Int
    """The device's default input mode."""
    var device_model: String
    """The device model name."""
    var device_os: Int
    """The platform, `protocol.DeviceOS` (1 = Android)."""
    var device_id: String
    """A device ID in the format the platform uses."""
    var game_version: String
    """The game version, for example `1.26.60`."""
    var gui_scale: Int
    """The GUI scale setting."""
    var filter_profanity: Bool
    """Whether the profanity filter is on."""
    var client_editor_connection_intent: Int
    """Editor mode connection intent."""
    var client_is_editor_capable: Bool
    """Whether the client can run Editor mode."""
    var language_code: String
    """The language, for example `en_GB`."""
    var persona_skin: Bool
    """Whether the skin is a persona skin."""
    var platform_offline_id: String
    """A UUID or empty."""
    var platform_online_id: String
    """A decimal ID or empty."""
    var platform_user_id: String
    """Omitted from the JSON when empty."""
    var premium_skin: Bool
    """Whether the skin is from a paid pack."""
    var self_signed_id: String
    """A UUID chosen per install."""
    var server_address: String
    """The address the client connected to."""
    var skin_animation_data: String
    """Skin animation JSON."""
    var skin_data: String
    """Base64 RGBA skin image."""
    var skin_geometry: String
    """Base64 skin geometry JSON."""
    var skin_geometry_version: String
    """Base64 geometry engine version."""
    var skin_id: String
    """The skin's ID; must not be empty."""
    var playfab_id: String
    """Lower-case hex PlayFab ID."""
    var skin_image_height: Int
    """The skin image height."""
    var skin_image_width: Int
    """The skin image width."""
    var skin_resource_patch: String
    """Base64 resource patch JSON."""
    var skin_colour: String
    """The skin colour as `#rrggbb` or empty."""
    var arm_size: String
    """`wide` or `slim`, or empty."""
    var third_party_name: String
    """The player's name as shown on third-party platforms."""
    var ui_profile: Int
    """0 classic, 1 pocket, 2 unset."""
    var trusted_skin: Bool
    """Whether the skin is trusted."""
    var override_skin: Bool
    """Whether the skin overrides the persona."""
    var compatible_with_client_side_chunk_gen: Bool
    """Whether the client can generate chunks itself."""
    var max_view_distance: Int
    """The largest view distance the client supports."""
    var memory_tier: Int
    """The device memory class."""
    var platform_type: Int
    """The platform type."""
    var graphics_mode: Int
    """The graphics mode."""
    var party_id: String
    """The party ID, if in a party."""
    var party_leader: Bool
    """Whether the player leads its party."""
    var profile_hash: String
    """The profile hash."""

    def __init__(out self):
        """Creates client data with every field empty."""
        self.cape_data = String()
        self.cape_id = String()
        self.cape_image_height = 0
        self.cape_image_width = 0
        self.cape_on_classic_skin = False
        self.client_random_id = 0
        self.current_input_mode = 0
        self.default_input_mode = 0
        self.device_model = String()
        self.device_os = 0
        self.device_id = String()
        self.game_version = String()
        self.gui_scale = 0
        self.filter_profanity = False
        self.client_editor_connection_intent = 0
        self.client_is_editor_capable = False
        self.language_code = String()
        self.persona_skin = False
        self.platform_offline_id = String()
        self.platform_online_id = String()
        self.platform_user_id = String()
        self.premium_skin = False
        self.self_signed_id = String()
        self.server_address = String()
        self.skin_animation_data = String()
        self.skin_data = String()
        self.skin_geometry = String()
        self.skin_geometry_version = String()
        self.skin_id = String()
        self.playfab_id = String()
        self.skin_image_height = 0
        self.skin_image_width = 0
        self.skin_resource_patch = String()
        self.skin_colour = String()
        self.arm_size = String()
        self.third_party_name = String()
        self.ui_profile = 0
        self.trusted_skin = False
        self.override_skin = False
        self.compatible_with_client_side_chunk_gen = False
        self.max_view_distance = 0
        self.memory_tier = 0
        self.platform_type = 0
        self.graphics_mode = 0
        self.party_id = String()
        self.party_leader = False
        self.profile_hash = String()

    def to_json(self) -> String:
        """Encodes the data as the JWT claims object, in gophertunnel's field
        order and with its JSON names.

        Returns:
            The JSON object text.
        """
        var o = String("{")
        o += '"AnimatedImageData":[],'
        _field(o, "CapeData", self.cape_data)
        _field(o, "CapeId", self.cape_id)
        _field_int(o, "CapeImageHeight", self.cape_image_height)
        _field_int(o, "CapeImageWidth", self.cape_image_width)
        _field_bool(o, "CapeOnClassicSkin", self.cape_on_classic_skin)
        _field_int(o, "ClientRandomId", Int(self.client_random_id))
        _field_int(o, "CurrentInputMode", self.current_input_mode)
        _field_int(o, "DefaultInputMode", self.default_input_mode)
        _field(o, "DeviceModel", self.device_model)
        _field_int(o, "DeviceOS", self.device_os)
        _field(o, "DeviceId", self.device_id)
        _field(o, "GameVersion", self.game_version)
        _field_int(o, "GuiScale", self.gui_scale)
        _field_bool(o, "FilterProfanity", self.filter_profanity)
        _field_int(
            o,
            "ClientEditorConnectionIntent",
            self.client_editor_connection_intent,
        )
        _field_bool(o, "ClientIsEditorCapable", self.client_is_editor_capable)
        _field(o, "LanguageCode", self.language_code)
        _field_bool(o, "PersonaSkin", self.persona_skin)
        _field(o, "PlatformOfflineId", self.platform_offline_id)
        _field(o, "PlatformOnlineId", self.platform_online_id)
        if self.platform_user_id.byte_length() > 0:
            _field(o, "PlatformUserId", self.platform_user_id)
        _field_bool(o, "PremiumSkin", self.premium_skin)
        _field(o, "SelfSignedId", self.self_signed_id)
        _field(o, "ServerAddress", self.server_address)
        _field(o, "SkinAnimationData", self.skin_animation_data)
        _field(o, "SkinData", self.skin_data)
        _field(o, "SkinGeometryData", self.skin_geometry)
        _field(o, "SkinGeometryDataEngineVersion", self.skin_geometry_version)
        _field(o, "SkinId", self.skin_id)
        _field(o, "PlayFabId", self.playfab_id)
        _field_int(o, "SkinImageHeight", self.skin_image_height)
        _field_int(o, "SkinImageWidth", self.skin_image_width)
        _field(o, "SkinResourcePatch", self.skin_resource_patch)
        _field(o, "SkinColor", self.skin_colour)
        _field(o, "ArmSize", self.arm_size)
        o += '"PersonaPieces":[],"PieceTintColors":[],'
        _field(o, "ThirdPartyName", self.third_party_name)
        _field_int(o, "UIProfile", self.ui_profile)
        _field_bool(o, "TrustedSkin", self.trusted_skin)
        _field_bool(o, "OverrideSkin", self.override_skin)
        _field_bool(
            o,
            "CompatibleWithClientSideChunkGen",
            self.compatible_with_client_side_chunk_gen,
        )
        _field_int(o, "MaxViewDistance", self.max_view_distance)
        _field_int(o, "MemoryTier", self.memory_tier)
        _field_int(o, "PlatformType", self.platform_type)
        _field_int(o, "GraphicsMode", self.graphics_mode)
        _field(o, "PartyId", self.party_id)
        _field_bool(o, "IsPartyLeader", self.party_leader)
        o += json_quote("ProfileHash")
        o += ":"
        o += json_quote(self.profile_hash)
        o += "}"
        return o^
