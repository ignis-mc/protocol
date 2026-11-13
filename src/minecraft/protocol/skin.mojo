"""Player skins and persona pieces (gophertunnel `protocol/skin.go`)."""

from .color import RGBA
from .io import IO, Marshaler, be_argb, invalid_value, slice, uuid
from .uuid import UUID

comptime ARM_SIZE_SLIM: UInt8 = 0
"""The Slim arm size."""
comptime ARM_SIZE_WIDE: UInt8 = 1
"""The Wide arm size."""

comptime SKIN_ANIMATION_HEAD: UInt32 = 1
"""An animation of the head and hat."""
comptime SKIN_ANIMATION_BODY_32X32: UInt32 = 2
"""An animation of the body (32x32)."""
comptime SKIN_ANIMATION_BODY_128X128: UInt32 = 3
"""An animation of the body (128x128)."""

comptime EXPRESSION_TYPE_LINEAR: UInt32 = 0
"""A Linear expression."""
comptime EXPRESSION_TYPE_BLINKING: UInt32 = 1
"""A Blinking expression."""

comptime PIECE_TYPE_UNKNOWN: UInt32 = 0
"""The Unknown persona piece type."""
comptime PIECE_TYPE_SKELETON: UInt32 = 1
"""The Skeleton persona piece type."""
comptime PIECE_TYPE_BODY: UInt32 = 2
"""The Body persona piece type."""
comptime PIECE_TYPE_SKIN: UInt32 = 3
"""The Skin persona piece type."""
comptime PIECE_TYPE_BOTTOM: UInt32 = 4
"""The Bottom persona piece type."""
comptime PIECE_TYPE_FEET: UInt32 = 5
"""The Feet persona piece type."""
comptime PIECE_TYPE_DRESS: UInt32 = 6
"""The Dress persona piece type."""
comptime PIECE_TYPE_TOP: UInt32 = 7
"""The Top persona piece type."""
comptime PIECE_TYPE_HIGH_PANTS: UInt32 = 8
"""The High Pants persona piece type."""
comptime PIECE_TYPE_HANDS: UInt32 = 9
"""The Hands persona piece type."""
comptime PIECE_TYPE_OUTERWEAR: UInt32 = 10
"""The Outerwear persona piece type."""
comptime PIECE_TYPE_FACIAL_HAIR: UInt32 = 11
"""The Facial Hair persona piece type."""
comptime PIECE_TYPE_MOUTH: UInt32 = 12
"""The Mouth persona piece type."""
comptime PIECE_TYPE_EYES: UInt32 = 13
"""The Eyes persona piece type."""
comptime PIECE_TYPE_HAIR: UInt32 = 14
"""The Hair persona piece type."""
comptime PIECE_TYPE_HOOD: UInt32 = 15
"""The Hood persona piece type."""
comptime PIECE_TYPE_BACK: UInt32 = 16
"""The Back persona piece type."""
comptime PIECE_TYPE_FACE_ACCESSORY: UInt32 = 17
"""The Face Accessory persona piece type."""
comptime PIECE_TYPE_HEAD: UInt32 = 18
"""The Head persona piece type."""
comptime PIECE_TYPE_LEGS: UInt32 = 19
"""The Legs persona piece type."""
comptime PIECE_TYPE_LEFT_LEG: UInt32 = 20
"""The Left Leg persona piece type."""
comptime PIECE_TYPE_RIGHT_LEG: UInt32 = 21
"""The Right Leg persona piece type."""
comptime PIECE_TYPE_ARMS: UInt32 = 22
"""The Arms persona piece type."""
comptime PIECE_TYPE_LEFT_ARM: UInt32 = 23
"""The Left Arm persona piece type."""
comptime PIECE_TYPE_RIGHT_ARM: UInt32 = 24
"""The Right Arm persona piece type."""
comptime PIECE_TYPE_CAPES: UInt32 = 25
"""The Capes persona piece type."""
comptime PIECE_TYPE_CLASSIC_SKIN: UInt32 = 26
"""The Classic Skin persona piece type."""
comptime PIECE_TYPE_EMOTE: UInt32 = 27
"""The Emote persona piece type."""
comptime PIECE_TYPE_UNSUPPORTED: UInt32 = 28
"""The Unsupported persona piece type."""


struct Skin(Marshaler):
    """A player skin as sent over the network: texture, model, animations."""

    var skin_id: String
    """A unique ID for the skin, such as `<uuid>_Alex`."""
    var skin_resource_patch: List[UInt8]
    """JSON naming the geometry of the skin and its animations."""
    var skin_image_width: UInt32
    """The skin image width in pixels."""
    var skin_image_height: UInt32
    """The skin image height in pixels."""
    var skin_data: List[UInt8]
    """RGBA pixels, `width * height * 4` bytes."""
    var animations: List[SkinAnimation]
    """The skin's animations."""
    var cape_image_width: UInt32
    """The cape image width in pixels."""
    var cape_image_height: UInt32
    """The cape image height in pixels."""
    var cape_data: List[UInt8]
    """RGBA cape pixels, `width * height * 4` bytes."""
    var skin_geometry: List[UInt8]
    """JSON geometry data (bones, UVs, pivots)."""
    var animation_data: List[UInt8]
    """Animation data; its meaning is unknown."""
    var geometry_data_engine_version: List[UInt8]
    """The engine version of the geometry data."""
    var premium_skin: Bool
    """Whether the skin was bought from the marketplace."""
    var persona_skin: Bool
    """Whether the skin was made in the in-game skin creator."""
    var persona_cape_on_classic_skin: Bool
    """Whether a persona cape is worn on a classic skin."""
    var primary_user: Bool
    """Whether this is the primary user's skin."""
    var cape_id: String
    """A unique identifier of the cape, usually a UUID."""
    var full_id: String
    """An ID representing the whole skin; the client sends none."""
    var skin_colour: RGBA
    """The skin colour."""
    var arm_size: UInt8
    """One of the `ARM_SIZE_*` values."""
    var persona_pieces: List[PersonaPiece]
    """The persona pieces the skin is made of."""
    var piece_tint_colours: List[PersonaPieceTintColour]
    """Tint colours for some of the persona pieces."""
    var trusted: Bool
    """Whether the skin is trusted; any proxy can change this."""
    var override_appearance: Bool
    """Whether the skin overrides the one equipped client-side."""
    var profile_hash: String
    """A hash of the player's profile."""

    def __init__(out self):
        """Creates an empty skin."""
        self.skin_id = String()
        self.skin_resource_patch = List[UInt8]()
        self.skin_image_width = 0
        self.skin_image_height = 0
        self.skin_data = List[UInt8]()
        self.animations = List[SkinAnimation]()
        self.cape_image_width = 0
        self.cape_image_height = 0
        self.cape_data = List[UInt8]()
        self.skin_geometry = List[UInt8]()
        self.animation_data = List[UInt8]()
        self.geometry_data_engine_version = List[UInt8]()
        self.premium_skin = False
        self.persona_skin = False
        self.persona_cape_on_classic_skin = False
        self.primary_user = False
        self.cape_id = String()
        self.full_id = String()
        self.skin_colour = RGBA()
        self.arm_size = 0
        self.persona_pieces = List[PersonaPiece]()
        self.piece_tint_colours = List[PersonaPieceTintColour]()
        self.trusted = False
        self.override_appearance = False
        self.profile_hash = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the skin.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or an image size does not match its
            dimensions.
        """
        io.string(self.skin_id)
        io.byte_slice(self.skin_resource_patch)
        io.uint32(self.skin_image_width)
        io.uint32(self.skin_image_height)
        io.byte_slice(self.skin_data)
        slice(io, self.animations)
        io.uint32(self.cape_image_width)
        io.uint32(self.cape_image_height)
        io.byte_slice(self.cape_data)
        io.byte_slice(self.skin_geometry)
        io.byte_slice(self.geometry_data_engine_version)
        io.byte_slice(self.animation_data)
        io.string(self.cape_id)
        io.string(self.full_id)
        io.uint8(self.arm_size)
        be_argb(io, self.skin_colour)
        slice(io, self.persona_pieces)
        slice(io, self.piece_tint_colours)
        var err = self.validate()
        if case .Some(ref reason) = err:
            invalid_value(
                String(t"Skin {self.skin_id}"), "serialised skin", reason
            )
        io.bool(self.premium_skin)
        io.bool(self.persona_skin)
        io.bool(self.persona_cape_on_classic_skin)
        io.bool(self.primary_user)
        io.bool(self.override_appearance)
        var trusted = String("true") if self.trusted else String("false")
        io.string(trusted)
        self.trusted = trusted.lower() == "true"
        io.string(self.profile_hash)

    def validate(self) -> Optional[String]:
        """Checks that the skin, cape and animation images match their sizes.

        Returns:
            A description of the first mismatch, or `None` if all match.
        """
        var skin_size = self.skin_image_height * self.skin_image_width * 4
        if skin_size != UInt32(len(self.skin_data)):
            return String(
                t"expected size of skin is {self.skin_image_width}x"
                t"{self.skin_image_height} ({skin_size} bytes total), but got"
                t" {len(self.skin_data)} bytes"
            )
        var cape_size = self.cape_image_height * self.cape_image_width * 4
        if cape_size != UInt32(len(self.cape_data)):
            return String(
                t"expected size of cape is {self.cape_image_width}x"
                t"{self.cape_image_height} ({cape_size} bytes total), but got"
                t" {len(self.cape_data)} bytes"
            )
        for i in range(len(self.animations)):
            ref a = self.animations[i]
            var size = a.image_height * a.image_width * 4
            if size != UInt32(len(a.image_data)):
                return String(
                    t"expected size of animation {i} is {a.image_width}x"
                    t"{a.image_height} ({size} bytes total), but got"
                    t" {len(a.image_data)} bytes"
                )
        return None


struct SkinAnimation(Marshaler):
    """An animation played client-side on a skin."""

    var image_width: UInt32
    """The animation image width in pixels."""
    var image_height: UInt32
    """The animation image height in pixels."""
    var image_data: List[UInt8]
    """RGBA pixels holding `frame_count` frames."""
    var animation_type: UInt32
    """One of the `SKIN_ANIMATION_*` values."""
    var frame_count: Float32
    """The number of frames in `image_data`."""
    var expression_type: UInt32
    """One of the `EXPRESSION_TYPE_*` values."""

    def __init__(out self):
        """Creates an empty animation."""
        self.image_width = 0
        self.image_height = 0
        self.image_data = List[UInt8]()
        self.animation_type = 0
        self.frame_count = 0
        self.expression_type = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the animation.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.image_width)
        io.uint32(self.image_height)
        io.byte_slice(self.image_data)
        io.varuint32(self.animation_type)
        io.float32(self.frame_count)
        io.varuint32(self.expression_type)


struct PersonaPiece(Marshaler):
    """One piece of a persona skin."""

    var piece_id: String
    """A UUID unique to the piece."""
    var piece_type: UInt32
    """One of the `PIECE_TYPE_*` values."""
    var pack_id: UUID
    """The pack the piece belongs to."""
    var default: Bool
    """Whether the piece is one of the Steve or Alex default pieces."""
    var product_id: String
    """The purchase UUID; empty for default pieces."""

    def __init__(out self):
        """Creates an empty piece."""
        self.piece_id = String()
        self.piece_type = 0
        self.pack_id = UUID()
        self.default = False
        self.product_id = String()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the piece.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.piece_id)
        io.uint32(self.piece_type)
        uuid(io, self.pack_id)
        io.bool(self.default)
        io.string(self.product_id)


struct PersonaPieceTintColour(Marshaler):
    """The tint colours of one persona piece type."""

    var piece_type: String
    """The piece type, in login-data form (`persona_hair`, `persona_hand`)."""
    var colours: Array[RGBA, 4]
    """The four ARGB tint colours."""

    def __init__(out self):
        """Creates an entry with no type and transparent colours."""
        self.piece_type = String()
        self.colours = Array[RGBA, 4](fill=RGBA())

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the tint colours.

        The wire uses the short v2168 names (`hair`, `hands`); reading maps
        them back to the login-data names.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        var wire_type = _persona_piece_tint_wire_type(self.piece_type)
        io.string(wire_type)
        if wire_type != _persona_piece_tint_wire_type(self.piece_type):
            self.piece_type = _persona_piece_tint_login_type(wire_type)
        for i in range(4):
            be_argb(io, self.colours[i])


def _persona_piece_tint_wire_type(piece_type: String) -> String:
    # Login data uses the singular `persona_hand`; the wire uses `hands`.
    if piece_type == "persona_hand":
        return "hands"
    if piece_type.startswith("persona_"):
        return String(piece_type[byte=8:])
    return piece_type.copy()


def _persona_piece_tint_login_type(piece_type: String) -> String:
    if piece_type == "hands":
        return "persona_hand"
    if piece_type == "unsupported":
        return piece_type.copy()
    return "persona_" + piece_type
