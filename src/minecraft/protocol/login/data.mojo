"""Identity and client data sent in the login request (gophertunnel
`login/data.go`): the types, their JSON encoding and decoding, and
`IdentityData.validate` / `ClientData.validate`.

The validators reproduce gophertunnel's checks, including that its name and
version patterns are unanchored (`[A-Za-z0-9 ]` only needs one matching
character), so a server agrees with Dragonfly on who may join. Where Go
consults the system the port cannot, it checks syntax instead and says so:

- `ServerAddress` host names are not resolved (Go calls
  `net.ResolveUDPAddr`); a syntactically valid name is accepted, and named
  ports (`host:http`) are rejected.
- `LanguageCode` is checked against BCP 47 syntax and the ISO 639-1
  two-letter codes; any three-letter language and any region or script code
  is accepted, where `golang.org/x/text/language` also rejects unknown ones.
- `\\p{L}` (any letter, for offline names) covers the Latin, Greek,
  Cyrillic, Armenian, Hebrew, Arabic, Indic, Thai, Georgian, Hangul, kana
  and CJK blocks rather than the full Unicode table.
"""

from jose.base64 import std_decode
from jose.json import (
    array_values,
    decode_object,
    is_null,
    lookup,
    opt_bool,
    opt_float,
    opt_int,
    opt_string,
    string_value,
    valid,
    bool_value,
)
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

    @staticmethod
    def decode(obj: Dict[String, String]) raises -> IdentityData:
        """Decodes the legacy chain's `extraData` object. The PlayFab fields
        are `json:"-"` in Go and stay empty.

        Args:
            obj: The object's members.

        Returns:
            The identity.

        Raises:
            Error: If a member has the wrong type.
        """
        var out = IdentityData()
        out.xuid = opt_string(obj, "XUID")
        out.identity = opt_string(obj, "identity")
        out.display_name = opt_string(obj, "displayName")
        out.title_id = opt_string(obj, "titleId")
        return out^

    def validate(self) raises:
        """Checks the identity like gophertunnel's `IdentityData.Validate`.

        Raises:
            Error: Naming the first invalid field.
        """
        if self.xuid.byte_length() != 0 and not _parse_int64(self.xuid):
            raise Error(
                t"XUID must be parseable as an int64, but got {self.xuid}"
            )
        if not _uuid_valid_not_nil(self.identity):
            raise Error(
                "UUID must be parseable as a valid UUID, but got "
                + self.identity
            )
        var limit = 15 if self.xuid.byte_length() != 0 else 16
        var name = self.display_name.as_bytes()
        if len(name) == 0 or len(name) > limit:
            raise Error(
                t"DisplayName must not be empty or longer than {limit}"
                t" characters, but got {len(name)} characters"
            )
        if name[0] == 0x20 or name[len(name) - 1] == 0x20:
            raise Error(
                "DisplayName may not have a space as first/last character,"
                " but got "
                + self.display_name
            )
        if name[0] >= 0x30 and name[0] <= 0x39:
            raise Error(
                "DisplayName may not have a number as first character, but got "
                + self.display_name
            )
        if self.xuid.byte_length() != 0:
            if not _any_online_name_char(self.display_name):
                raise Error(
                    "DisplayName for authorized client must only contain"
                    " numbers, Latin letters and spaces, but got "
                    + self.display_name
                )
        elif not _any_offline_name_char(self.display_name):
            raise Error(
                "DisplayName for unauthorized client must only contain"
                " numbers, letters and spaces, but got "
                + self.display_name
            )
        if self.display_name.find("  ") >= 0:
            raise Error(
                "DisplayName must only have single spaces, but got "
                + self.display_name
            )


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


struct SkinAnimation(Copyable, Defaultable):
    """An animation layered over the skin (gophertunnel `SkinAnimation`)."""

    var frames: Float64
    """The number of frames in `image`."""
    var image: String
    """Base64 RGBA pixels of all frames."""
    var image_height: Int
    """The image height."""
    var image_width: Int
    """The image width."""
    var type: Int
    """0 none, 1 face, 2 32x32 body, 3 128x128 body."""
    var animation_expression: Int
    """0 linear, 1 blinking."""

    def __init__(out self):
        """Creates an empty animation."""
        self.frames = 0.0
        self.image = String()
        self.image_height = 0
        self.image_width = 0
        self.type = 0
        self.animation_expression = 0

    @staticmethod
    def decode(raw: StringSpan) raises -> SkinAnimation:
        """Decodes one animation object.

        Args:
            raw: Its JSON text.

        Returns:
            The animation.

        Raises:
            Error: If it is not an object or a member has the wrong type.
        """
        var obj = decode_object(raw.as_bytes())
        var a = SkinAnimation()
        a.frames = opt_float(obj, "Frames")
        a.image = opt_string(obj, "Image")
        a.image_height = opt_int(obj, "ImageHeight")
        a.image_width = opt_int(obj, "ImageWidth")
        a.type = opt_int(obj, "Type")
        a.animation_expression = opt_int(obj, "AnimationExpression")
        return a^

    def to_json(self) -> String:
        """Encodes the animation in gophertunnel's field order.

        Returns:
            The JSON object text.
        """
        var o = String('{"Frames":')
        o += _go_float(self.frames)
        o += ","
        _field(o, "Image", self.image)
        _field_int(o, "ImageHeight", self.image_height)
        _field_int(o, "ImageWidth", self.image_width)
        _field_int(o, "Type", self.type)
        o += String(t'"AnimationExpression":{self.animation_expression}}}')
        return o^


struct PersonaPiece(Copyable, Defaultable):
    """One piece of a persona skin (gophertunnel `PersonaPiece`)."""

    var default: Bool
    """Whether this is a default (Steve/Alex) piece."""
    var pack_id: String
    """The pack's UUID."""
    var piece_id: String
    """The piece's UUID."""
    var piece_type: String
    """For example `persona_skeleton`."""
    var product_id: String
    """The marketplace product UUID, empty for defaults."""

    def __init__(out self):
        """Creates an empty piece."""
        self.default = False
        self.pack_id = String()
        self.piece_id = String()
        self.piece_type = String()
        self.product_id = String()

    @staticmethod
    def decode(raw: StringSpan) raises -> PersonaPiece:
        """Decodes one piece object.

        Args:
            raw: Its JSON text.

        Returns:
            The piece.

        Raises:
            Error: If it is not an object or a member has the wrong type.
        """
        var obj = decode_object(raw.as_bytes())
        var p = PersonaPiece()
        p.default = opt_bool(obj, "IsDefault")
        p.pack_id = opt_string(obj, "PackId")
        p.piece_id = opt_string(obj, "PieceId")
        p.piece_type = opt_string(obj, "PieceType")
        p.product_id = opt_string(obj, "ProductId")
        return p^

    def to_json(self) -> String:
        """Encodes the piece in gophertunnel's field order.

        Returns:
            The JSON object text.
        """
        var o = String("{")
        _field_bool(o, "IsDefault", self.default)
        _field(o, "PackId", self.pack_id)
        _field(o, "PieceId", self.piece_id)
        _field(o, "PieceType", self.piece_type)
        o += json_quote("ProductId")
        o += ":"
        o += json_quote(self.product_id)
        o += "}"
        return o^


struct PersonaPieceTintColour(Copyable, Defaultable):
    """Tint colours of one persona piece type (gophertunnel
    `PersonaPieceTintColour`)."""

    var colours: List[String]
    """Four ARGB hex colours."""
    var piece_type: String
    """The piece type they apply to."""

    def __init__(out self):
        """Creates four empty colours."""
        self.colours = [String(), String(), String(), String()]
        self.piece_type = String()

    @staticmethod
    def decode(raw: StringSpan) raises -> PersonaPieceTintColour:
        """Decodes one tint object; like a Go `[4]string`, extra colours are
        dropped and missing ones stay empty.

        Args:
            raw: Its JSON text.

        Returns:
            The tint.

        Raises:
            Error: If it is not an object or a member has the wrong type.
        """
        var obj = decode_object(raw.as_bytes())
        var t = PersonaPieceTintColour()
        if case .Some(colours) = lookup(obj, "Colors"):
            var items = array_values(colours)
            for i in range(min(len(items), 4)):
                if not is_null(items[i]):
                    t.colours[i] = string_value(items[i])
        t.piece_type = opt_string(obj, "PieceType")
        return t^

    def to_json(self) -> String:
        """Encodes the tint in gophertunnel's field order.

        Returns:
            The JSON object text.
        """
        var o = String('{"Colors":[')
        for i in range(4):
            if i > 0:
                o += ","
            o += json_quote(self.colours[i] if i < len(self.colours) else "")
        o += "],"
        o += json_quote("PieceType")
        o += ":"
        o += json_quote(self.piece_type)
        o += "}"
        return o^


struct ClientData(Copyable, Defaultable):
    """Client settings and skin, signed into the login request
    (gophertunnel `ClientData`)."""

    var animated_image_data: List[SkinAnimation]
    """Animations layered over the skin."""
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
    var persona_pieces: List[PersonaPiece]
    """The persona skin's pieces."""
    var piece_tint_colours: List[PersonaPieceTintColour]
    """Tints of some persona pieces."""
    var third_party_name: String
    """The player's name as shown on third-party platforms."""
    var third_party_name_only: Optional[Bool]
    """Omitted from the JSON when `None`; never trust it."""
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
    var nonce: String
    """The host-assigned nonce for peer-to-peer joins; omitted when empty."""

    def __init__(out self):
        """Creates client data with every field empty."""
        self.animated_image_data = List[SkinAnimation]()
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
        self.persona_pieces = List[PersonaPiece]()
        self.piece_tint_colours = List[PersonaPieceTintColour]()
        self.third_party_name = String()
        self.third_party_name_only = None
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
        self.nonce = String()

    def to_json(self) -> String:
        """Encodes the data as the JWT claims object, in gophertunnel's field
        order and with its JSON names.

        Returns:
            The JSON object text.
        """
        var o = String('{"AnimatedImageData":[')
        for i in range(len(self.animated_image_data)):
            if i > 0:
                o += ","
            o += self.animated_image_data[i].to_json()
        o += "],"
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
        o += '"PersonaPieces":['
        for i in range(len(self.persona_pieces)):
            if i > 0:
                o += ","
            o += self.persona_pieces[i].to_json()
        o += '],"PieceTintColors":['
        for i in range(len(self.piece_tint_colours)):
            if i > 0:
                o += ","
            o += self.piece_tint_colours[i].to_json()
        o += "],"
        _field(o, "ThirdPartyName", self.third_party_name)
        if case .Some(only) = self.third_party_name_only:
            _field_bool(o, "ThirdPartyNameOnly", only)
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
        if self.nonce.byte_length() > 0:
            o += ',"Nonce":'
            o += json_quote(self.nonce)
        o += "}"
        return o^

    @staticmethod
    def decode(payload: Span[UInt8, _]) raises -> ClientData:
        """Decodes the client data claims as Go's `json.Unmarshal` would.

        Args:
            payload: The verified JWT payload.

        Returns:
            The client data.

        Raises:
            Error: If the payload is not a JSON object or a member has the
                wrong type.
        """
        var obj = decode_object(payload)
        var d = ClientData()
        if case .Some(raw) = lookup(obj, "AnimatedImageData"):
            for item in array_values(raw):
                d.animated_image_data.append(SkinAnimation.decode(item))
        d.cape_data = opt_string(obj, "CapeData")
        d.cape_id = opt_string(obj, "CapeId")
        d.cape_image_height = opt_int(obj, "CapeImageHeight")
        d.cape_image_width = opt_int(obj, "CapeImageWidth")
        d.cape_on_classic_skin = opt_bool(obj, "CapeOnClassicSkin")
        d.client_random_id = Int64(opt_int(obj, "ClientRandomId"))
        d.current_input_mode = opt_int(obj, "CurrentInputMode")
        d.default_input_mode = opt_int(obj, "DefaultInputMode")
        d.device_model = opt_string(obj, "DeviceModel")
        d.device_os = opt_int(obj, "DeviceOS")
        d.device_id = opt_string(obj, "DeviceId")
        d.game_version = opt_string(obj, "GameVersion")
        d.gui_scale = opt_int(obj, "GuiScale")
        d.filter_profanity = opt_bool(obj, "FilterProfanity")
        d.client_editor_connection_intent = opt_int(
            obj, "ClientEditorConnectionIntent"
        )
        d.client_is_editor_capable = opt_bool(obj, "ClientIsEditorCapable")
        d.language_code = opt_string(obj, "LanguageCode")
        d.persona_skin = opt_bool(obj, "PersonaSkin")
        d.platform_offline_id = opt_string(obj, "PlatformOfflineId")
        d.platform_online_id = opt_string(obj, "PlatformOnlineId")
        d.platform_user_id = opt_string(obj, "PlatformUserId")
        d.premium_skin = opt_bool(obj, "PremiumSkin")
        d.self_signed_id = opt_string(obj, "SelfSignedId")
        d.server_address = opt_string(obj, "ServerAddress")
        d.skin_animation_data = opt_string(obj, "SkinAnimationData")
        d.skin_data = opt_string(obj, "SkinData")
        d.skin_geometry = opt_string(obj, "SkinGeometryData")
        d.skin_geometry_version = opt_string(
            obj, "SkinGeometryDataEngineVersion"
        )
        d.skin_id = opt_string(obj, "SkinId")
        d.playfab_id = opt_string(obj, "PlayFabId")
        d.skin_image_height = opt_int(obj, "SkinImageHeight")
        d.skin_image_width = opt_int(obj, "SkinImageWidth")
        d.skin_resource_patch = opt_string(obj, "SkinResourcePatch")
        d.skin_colour = opt_string(obj, "SkinColor")
        d.arm_size = opt_string(obj, "ArmSize")
        if case .Some(raw) = lookup(obj, "PersonaPieces"):
            for item in array_values(raw):
                d.persona_pieces.append(PersonaPiece.decode(item))
        if case .Some(raw) = lookup(obj, "PieceTintColors"):
            for item in array_values(raw):
                d.piece_tint_colours.append(PersonaPieceTintColour.decode(item))
        d.third_party_name = opt_string(obj, "ThirdPartyName")
        if case .Some(raw) = lookup(obj, "ThirdPartyNameOnly"):
            d.third_party_name_only = bool_value(raw)
        d.ui_profile = opt_int(obj, "UIProfile")
        d.trusted_skin = opt_bool(obj, "TrustedSkin")
        d.override_skin = opt_bool(obj, "OverrideSkin")
        d.compatible_with_client_side_chunk_gen = opt_bool(
            obj, "CompatibleWithClientSideChunkGen"
        )
        d.max_view_distance = opt_int(obj, "MaxViewDistance")
        d.memory_tier = opt_int(obj, "MemoryTier")
        d.platform_type = opt_int(obj, "PlatformType")
        d.graphics_mode = opt_int(obj, "GraphicsMode")
        d.party_id = opt_string(obj, "PartyId")
        d.party_leader = opt_bool(obj, "IsPartyLeader")
        d.profile_hash = opt_string(obj, "ProfileHash")
        d.nonce = opt_string(obj, "Nonce")
        return d^

    def validate(self) raises:
        """Checks the data like gophertunnel's `ClientData.Validate`.

        Raises:
            Error: Naming the first invalid field.
        """
        if self.device_os <= 0 or self.device_os > 15:
            raise Error(
                t"DeviceOS must carry a value between 1 and 15, but got"
                t" {self.device_os}"
            )
        if not _any_version_char(self.game_version):
            raise Error(
                "GameVersion must only contain dots and numbers, but got "
                + self.game_version
            )
        if not _language_valid(self.language_code):
            raise Error(
                "LanguageCode must be a valid BCP-47 ISO language code, but"
                " got "
                + self.language_code
            )
        if self.platform_offline_id.byte_length() != 0 and not _uuid_parse(
            self.platform_offline_id
        ):
            raise Error(
                "PlatformOfflineID must be parseable as a valid UUID or empty,"
                " but got "
                + self.platform_offline_id
            )
        if self.platform_online_id.byte_length() != 0 and not _parse_uint64(
            self.platform_online_id
        ):
            raise Error(
                "PlatformOnlineID must be parseable as an int64 or empty, but"
                " got "
                + self.platform_online_id
            )
        if self.self_signed_id.byte_length() != 0 and not _uuid_parse(
            self.self_signed_id
        ):
            raise Error(
                "SelfSignedID must be parseable as a valid UUID, but got "
                + self.self_signed_id
            )
        if self.server_address.find("://") >= 0:
            if not _nethernet_address_valid(self.server_address):
                raise Error("ServerAddress is invalid: " + self.server_address)
        elif not _udp_address_valid(self.server_address):
            raise Error(
                "ServerAddress must be resolveable as a UDP address, but got "
                + self.server_address
            )
        try:
            _base64_length(
                self.skin_data,
                self.skin_image_height * self.skin_image_width * 4,
            )
        except e:
            raise Error(t"SkinData is invalid: {e}")
        try:
            _base64_length(
                self.cape_data,
                self.cape_image_height * self.cape_image_width * 4,
            )
        except e:
            raise Error(t"CapeData is invalid: {e}")
        for cp in self.playfab_id.codepoints():
            var c = Int(cp)
            if (c < 0x30 or c > 0x39) and (c < 0x61 or c > 0x66):
                raise Error(
                    "PlayFabID must consist of hex characters, got "
                    + self.playfab_id
                )
        for anim in self.animated_image_data:
            try:
                _base64_length(
                    anim.image, anim.image_height * anim.image_width * 4
                )
            except e:
                raise Error(t"invalid animated image data: {e}")
            if anim.type < 0 or anim.type > 3:
                raise Error(t"invalid animation type: {anim.type}")
        var geometry: List[UInt8]
        try:
            geometry = std_decode(self.skin_geometry)
        except e:
            raise Error(t"SkinGeometry was not a valid base64 string: {e}")
        if len(geometry) != 0 and not _json_map(Span(geometry)):
            raise Error(
                "SkinGeometry base64 decoded was not a valid JSON string"
            )
        var patch: List[UInt8]
        try:
            patch = std_decode(self.skin_resource_patch)
        except e:
            raise Error(t"SkinResourcePatch was not a valid base64 string: {e}")
        if not _json_map(Span(patch)):
            raise Error(
                "SkinResourcePatch base64 decoded was not a valid JSON string"
            )
        if self.skin_id.byte_length() == 0:
            raise Error("SkinID must not be an empty string")
        if self.ui_profile < 0 or self.ui_profile > 2:
            raise Error(
                t"UIProfile must be between 0-2, but got {self.ui_profile}"
            )


def _go_float(f: Float64) -> String:
    # encoding/json prints integral floats without a fraction.
    if f == Float64(Int(f)) and abs(f) < 1e15:
        return String(Int(f))
    return String(f)


def _digits_only(b: Span[UInt8, _]) -> Bool:
    if len(b) == 0:
        return False
    for c in b:
        if c < 0x30 or c > 0x39:
            return False
    return True


def _decimal(b: Span[UInt8, _]) -> Int:
    # The value of a short run of ASCII digits.
    var v = 0
    for c in b:
        v = v * 10 + Int(c) - 0x30
    return v


def _parse_int64(s: StringSpan) -> Bool:
    """`strconv.ParseInt(s, 10, 64)` succeeds."""
    var b = s.as_bytes()
    var neg = False
    if len(b) > 0 and (b[0] == 0x2B or b[0] == 0x2D):
        neg = b[0] == 0x2D
        b = b[1:]
    if not _digits_only(b):
        return False
    var limit = String("9223372036854775808" if neg else "9223372036854775807")
    return _fits(b, limit.as_bytes())


def _parse_uint64(s: StringSpan) -> Bool:
    """`strconv.ParseUint(s, 10, 64)` succeeds."""
    var b = s.as_bytes()
    if not _digits_only(b):
        return False
    return _fits(b, "18446744073709551615".as_bytes())


def _fits(digits: Span[UInt8, _], limit: Span[UInt8, _]) -> Bool:
    # Compares decimal magnitudes, ignoring leading zeros.
    var i = 0
    while i < len(digits) - 1 and digits[i] == 0x30:
        i += 1
    var n = len(digits) - i
    if n != len(limit):
        return n < len(limit)
    for k in range(n):
        if digits[i + k] != limit[k]:
            return digits[i + k] < limit[k]
    return True


def _hex_value(c: UInt8) -> Int:
    if c >= 0x30 and c <= 0x39:
        return Int(c) - 0x30
    if c >= 0x61 and c <= 0x66:
        return Int(c) - 0x61 + 10
    if c >= 0x41 and c <= 0x46:
        return Int(c) - 0x41 + 10
    return -1


def _uuid_bytes(s: StringSpan) -> Optional[List[UInt8]]:
    """google/uuid `Parse`: canonical, `urn:uuid:`, braced (the braces are
    not checked, as in Go) and 32-digit forms."""
    var b = s.as_bytes()
    var out = List[UInt8]()
    if len(b) == 32:
        for i in range(16):
            var hi = _hex_value(b[2 * i])
            var lo = _hex_value(b[2 * i + 1])
            if hi < 0 or lo < 0:
                return None
            out.append(UInt8(hi * 16 + lo))
        return out^
    var start = 0
    if len(b) == 36 + 9:
        if String(s[byte=0:9]).lower() != "urn:uuid:":
            return None
        start = 9
    elif len(b) == 36 + 2:
        start = 1
    elif len(b) != 36:
        return None
    var u = b[start : start + 36]
    if u[8] != 0x2D or u[13] != 0x2D or u[18] != 0x2D or u[23] != 0x2D:
        return None
    comptime offsets: Array[Int, 16] = [
        0,
        2,
        4,
        6,
        9,
        11,
        14,
        16,
        19,
        21,
        24,
        26,
        28,
        30,
        32,
        34,
    ]
    var offs = materialize[offsets]()
    for i in range(16):
        var hi = _hex_value(u[offs[i]])
        var lo = _hex_value(u[offs[i] + 1])
        if hi < 0 or lo < 0:
            return None
        out.append(UInt8(hi * 16 + lo))
    return out^


def _uuid_parse(s: StringSpan) -> Bool:
    return Bool(_uuid_bytes(s))


def _uuid_valid_not_nil(s: StringSpan) -> Bool:
    if case .Some(b) = _uuid_bytes(s):
        for x in b:
            if x != 0:
                return True
    return False


def _any_online_name_char(name: StringSpan) -> Bool:
    """`regexp.MustCompile("[A-Za-z0-9 ]").MatchString`."""
    for c in name.as_bytes():
        if (
            (c >= 0x41 and c <= 0x5A)
            or (c >= 0x61 and c <= 0x7A)
            or (c >= 0x30 and c <= 0x39)
            or c == 0x20
        ):
            return True
    return False


def _is_letter(cp: Int) -> Bool:
    # An approximation of \p{L}; see the module docstring.
    if (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A):
        return True
    if cp < 0xAA:
        return False
    if cp == 0xAA or cp == 0xB5 or cp == 0xBA:
        return True
    if cp >= 0xC0 and cp <= 0x2C1:
        return cp != 0xD7 and cp != 0xF7
    if cp >= 0x370 and cp <= 0x3FF:
        return not (
            cp == 0x375
            or cp == 0x37E
            or cp == 0x384
            or cp == 0x385
            or cp == 0x387
            or cp == 0x3F6
        )
    comptime ranges: Array[Int, 52] = [
        0x400,
        0x481,
        0x48A,
        0x52F,
        0x531,
        0x556,
        0x560,
        0x588,
        0x5D0,
        0x5EA,
        0x620,
        0x64A,
        0x671,
        0x6D3,
        0x904,
        0x939,
        0x985,
        0x9B9,
        0xA05,
        0xA39,
        0xA85,
        0xAB9,
        0xB05,
        0xB39,
        0xB85,
        0xBB9,
        0xC05,
        0xC39,
        0xC85,
        0xCB9,
        0xD05,
        0xD3A,
        0xE01,
        0xE30,
        0x10A0,
        0x10FF,
        0x1100,
        0x11FF,
        0x1E00,
        0x1FBC,
        0x3041,
        0x3096,
        0x30A1,
        0x30FA,
        0x3105,
        0x312F,
        0x3400,
        0x4DBF,
        0x4E00,
        0x9FFF,
        0xAC00,
        0xD7A3,
    ]
    var table = materialize[ranges]()
    for i in range(0, 52, 2):
        if cp >= table[i] and cp <= table[i + 1]:
            return True
    if cp >= 0xF900 and cp <= 0xFAFF:
        return True
    if (cp >= 0xFF21 and cp <= 0xFF3A) or (cp >= 0xFF41 and cp <= 0xFF5A):
        return True
    if cp >= 0xFF66 and cp <= 0xFF9D:
        return True
    return cp >= 0x20000 and cp <= 0x2FA1F


def _any_offline_name_char(name: StringSpan) -> Bool:
    """`regexp.MustCompile(`[ \\p{L}]`).MatchString`."""
    for cp in name.codepoints():
        var c = Int(cp)
        if c == 0x20 or _is_letter(c):
            return True
    return False


def _any_version_char(version: StringSpan) -> Bool:
    """`regexp.MustCompile("[0-9.]").MatchString`."""
    for c in version.as_bytes():
        if (c >= 0x30 and c <= 0x39) or c == 0x2E:
            return True
    return False


comptime _ISO_639_1 = (
    "aa ab ae af ak am an ar as av ay az ba be bg bh bi bm bn bo br bs ca ce"
    " ch co cr cs cu cv cy da de dv dz ee el en eo es et eu fa ff fi fj fo fr"
    " fy ga gd gl gn gu gv ha he hi ho hr ht hu hy hz ia id ie ig ii ik in io"
    " is it iu iw ja ji jv jw ka kg ki kj kk kl km kn ko kr ks ku kv kw ky la"
    " lb lg li ln lo lt lu lv mg mh mi mk ml mn mo mr ms mt my na nb nd ne ng"
    " nl nn no nr nv ny oc oj om or os pa pi pl ps pt qu rm rn ro ru rw sa sc"
    " sd se sg sh si sk sl sm sn so sq sr ss st su sv sw ta te tg th ti tk tl"
    " tn to tr ts tt tw ty ug uk ur uz ve vi vo wa wo xh yi yo za zh zu"
)

comptime _GRANDFATHERED = (
    " en-gb-oed i-ami i-bnn i-default i-enochian i-hak i-klingon i-lux"
    " i-mingo i-navajo i-pwn i-tao i-tay i-tsu sgn-be-fr sgn-be-nl sgn-ch-de"
    " art-lojban cel-gaulish no-bok no-nyn zh-guoyu zh-hakka zh-min"
    " zh-min-nan zh-xiang "
)


def _all(b: Span[UInt8, _], alpha: Bool, digit: Bool) -> Bool:
    for c in b:
        var is_alpha = c >= 0x61 and c <= 0x7A
        var is_digit = c >= 0x30 and c <= 0x39
        if not ((alpha and is_alpha) or (digit and is_digit)):
            return False
    return True


def _language_valid(code: StringSpan) -> Bool:
    """BCP 47 syntax as `language.Parse` reads it, `_` or `-` separated and
    case-insensitive; see the module docstring for what is not checked."""
    var norm = String(code).lower().replace("_", "-")
    if norm.byte_length() == 0:
        return False
    if String(_GRANDFATHERED).find(String(" ", norm, " ")) >= 0:
        return True
    var parts = List[String]()
    for piece in norm.split("-"):
        parts.append(String(piece))
    for p in parts:
        var n = p.byte_length()
        if n == 0 or n > 8 or not _all(p.as_bytes(), True, True):
            return False
    var i = 0
    if parts[0] != "x":
        var lang = parts[0].as_bytes()
        if not _all(lang, True, False):
            return False
        if len(lang) == 2:
            if String(_ISO_639_1).find(String(parts[0])) < 0:
                return False
        elif len(lang) != 3:
            return False
        i = 1
        if (
            i < len(parts)
            and parts[i].byte_length() == 4
            and _all(parts[i].as_bytes(), True, False)
        ):
            i += 1
        if i < len(parts):
            var r = parts[i].as_bytes()
            if (len(r) == 2 and _all(r, True, False)) or (
                len(r) == 3 and (_all(r, False, True) or _all(r, True, False))
            ):
                i += 1
        while i < len(parts):
            var v = parts[i].as_bytes()
            if len(v) >= 5 or (len(v) == 4 and v[0] >= 0x30 and v[0] <= 0x39):
                i += 1
            else:
                break
        while (
            i < len(parts) and parts[i].byte_length() == 1 and parts[i] != "x"
        ):
            i += 1
            var count = 0
            while i < len(parts) and parts[i].byte_length() >= 2:
                i += 1
                count += 1
            if count == 0:
                return False
    if i < len(parts):
        if parts[i] != "x" or i + 1 >= len(parts):
            return False
        return True
    return True


def _ipv4_valid(s: StringSpan) -> Bool:
    var parts = s.split(".")
    if len(parts) != 4:
        return False
    for p in parts:
        var b = p.as_bytes()
        if not _digits_only(b) or len(b) > 3:
            return False
        if len(b) > 1 and b[0] == 0x30:
            return False
        if _decimal(b) > 255:
            return False
    return True


def _ipv6_valid(text: StringSpan) -> Bool:
    var s = String(text)
    var zone = s.find("%")
    if zone >= 0:
        if zone == s.byte_length() - 1:
            return False
        var bare = String(s[byte=0:zone])
        s = bare^
    var b = s.as_bytes()
    var groups = 0
    var double = False
    var i = 0
    if len(b) >= 2 and b[0] == 0x3A and b[1] == 0x3A:
        double = True
        i = 2
        if len(b) == 2:
            return True
    elif len(b) > 0 and b[0] == 0x3A:
        return False
    while i < len(b):
        var j = i
        while j < len(b) and _hex_value(b[j]) >= 0:
            j += 1
        if j < len(b) and b[j] == 0x2E:
            if not _ipv4_valid(StringSpan(unsafe_from_utf8=b[i : len(b)])):
                return False
            groups += 2
            break
        if j == i or j - i > 4:
            return False
        groups += 1
        i = j
        if i == len(b):
            break
        if b[i] != 0x3A:
            return False
        i += 1
        if i < len(b) and b[i] == 0x3A:
            if double:
                return False
            double = True
            i += 1
            if i == len(b):
                break
        elif i == len(b):
            return False
    return groups == 8 if not double else groups < 8


def _hostname_valid(host: StringSpan) -> Bool:
    var b = host.as_bytes()
    if len(b) > 253:
        return False
    var labels = host.split(".")
    var all_numeric = True
    for i in range(len(labels)):
        var l = labels[i].as_bytes()
        if len(l) == 0:
            # A trailing dot is a fully qualified name.
            if i == len(labels) - 1 and i > 0:
                continue
            return False
        if len(l) > 63:
            return False
        for c in l:
            var ok = (
                (c >= 0x61 and c <= 0x7A)
                or (c >= 0x41 and c <= 0x5A)
                or (c >= 0x30 and c <= 0x39)
                or c == 0x2D
                or c == 0x5F
            )
            if not ok:
                return False
        if not _digits_only(l):
            all_numeric = False
    return not all_numeric


def _udp_address_valid(addr: StringSpan) -> Bool:
    """`net.ResolveUDPAddr("udp", addr)` without the DNS lookup."""
    var s = String(addr)
    if s.byte_length() == 0:
        return True
    var b = s.as_bytes()
    var host: String
    var port: String
    if b[0] == 0x5B:
        var end = s.find("]")
        if end < 0 or end + 1 >= len(b) or b[end + 1] != 0x3A:
            return False
        host = String(s[byte=1:end])
        port = String(s[byte = end + 2 : len(b)])
        if host.find("[") >= 0 or port.find("]") >= 0 or port.find("[") >= 0:
            return False
        if not _ipv6_valid(host):
            return False
    else:
        var colon = s.rfind(":")
        if colon < 0:
            return False
        host = String(s[byte=0:colon])
        port = String(s[byte = colon + 1 : len(b)])
        if host.find(":") >= 0 or host.find("[") >= 0 or host.find("]") >= 0:
            return False
        if port.find("[") >= 0 or port.find("]") >= 0:
            return False
        if (
            host.byte_length() != 0
            and not _ipv4_valid(host)
            and not _hostname_valid(host)
        ):
            return False
    if port.byte_length() != 0:
        var pb = port.as_bytes()
        if not _digits_only(pb) or len(pb) > 5 or _decimal(pb) > 65535:
            return False
    return True


def _nethernet_address_valid(addr: StringSpan) -> Bool:
    """gophertunnel's check for `scheme://host:port:port` addresses: the
    URL before the last colon must parse with a host and a port equal to
    the part after it, and use http or https."""
    var s = String(addr)
    var last = s.rfind(":")
    var url = String(s[byte=0:last])
    var tail = String(s[byte = last + 1 : s.byte_length()])
    var sep = url.find("://")
    if sep <= 0:
        return False
    var scheme = String(url[byte=0:sep]).lower()
    if scheme != "http" and scheme != "https":
        return False
    var rest = String(url[byte = sep + 3 : url.byte_length()])
    var end = rest.byte_length()
    for marker in ["/", "?", "#"]:
        var k = rest.find(marker)
        if k >= 0 and k < end:
            end = k
    var authority = String(rest[byte=0:end])
    var at = authority.rfind("@")
    if at >= 0:
        var host_port = String(
            authority[byte = at + 1 : authority.byte_length()]
        )
        authority = host_port^
    if authority.byte_length() == 0:
        return False
    var colon = authority.rfind(":")
    var bracket = authority.rfind("]")
    if colon < 0 or colon < bracket:
        return False
    var port = String(authority[byte = colon + 1 : authority.byte_length()])
    if not _digits_only(port.as_bytes()):
        return False
    return port == tail


def _base64_length(data: StringSpan, length: Int) raises:
    """gophertunnel `base64DecLength` with one valid length."""
    var n: Int
    try:
        n = len(std_decode(data))
    except e:
        raise Error(t"decode base64 data: {e}")
    if n != length:
        raise Error(t"invalid size: got {n}, expected one of [{length}]")


def _json_map(data: Span[UInt8, _]) -> Bool:
    """`json.Unmarshal(data, &map[string]any{})` succeeds: valid JSON whose
    value is an object or `null`."""
    if not valid(data):
        return False
    for c in data:
        if c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D:
            continue
        return c == 0x7B or c == 0x6E
    return False
