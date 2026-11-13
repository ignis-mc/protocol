"""Biome definitions (gophertunnel `protocol/biome.go`).

None of these types is recursive: expressions are referenced by their index
in the packet's string list, so no flattening is needed.
"""

from .entities_helpers import func_slice, optional_func
from .io import IO, Marshaler, optional_marshaler, slice

comptime BIOME_EXPRESSION_OP_UNKNOWN: Int32 = -1
"""Go `BiomeExpressionOpUnknown`."""
comptime BIOME_EXPRESSION_OP_LEFT_BRACE: Int32 = 0
"""Go `BiomeExpressionOpLeftBrace`."""
comptime BIOME_EXPRESSION_OP_RIGHT_BRACE: Int32 = 1
"""Go `BiomeExpressionOpRightBrace`."""
comptime BIOME_EXPRESSION_OP_LEFT_BRACKET: Int32 = 2
"""Go `BiomeExpressionOpLeftBracket`."""
comptime BIOME_EXPRESSION_OP_RIGHT_BRACKET: Int32 = 3
"""Go `BiomeExpressionOpRightBracket`."""
comptime BIOME_EXPRESSION_OP_LEFT_PARENTHESIS: Int32 = 4
"""Go `BiomeExpressionOpLeftParenthesis`."""
comptime BIOME_EXPRESSION_OP_RIGHT_PARENTHESIS: Int32 = 5
"""Go `BiomeExpressionOpRightParenthesis`."""
comptime BIOME_EXPRESSION_OP_NEGATE: Int32 = 6
"""Go `BiomeExpressionOpNegate`."""
comptime BIOME_EXPRESSION_OP_LOGICAL_NOT: Int32 = 7
"""Go `BiomeExpressionOpLogicalNot`."""
comptime BIOME_EXPRESSION_OP_ABS: Int32 = 8
"""Go `BiomeExpressionOpAbs`."""
comptime BIOME_EXPRESSION_OP_ADD: Int32 = 9
"""Go `BiomeExpressionOpAdd`."""
comptime BIOME_EXPRESSION_OP_ACOS: Int32 = 10
"""Go `BiomeExpressionOpAcos`."""
comptime BIOME_EXPRESSION_OP_ASIN: Int32 = 11
"""Go `BiomeExpressionOpAsin`."""
comptime BIOME_EXPRESSION_OP_ATAN: Int32 = 12
"""Go `BiomeExpressionOpAtan`."""
comptime BIOME_EXPRESSION_OP_ATAN2: Int32 = 13
"""Go `BiomeExpressionOpAtan2`."""
comptime BIOME_EXPRESSION_OP_CEIL: Int32 = 14
"""Go `BiomeExpressionOpCeil`."""
comptime BIOME_EXPRESSION_OP_CLAMP: Int32 = 15
"""Go `BiomeExpressionOpClamp`."""
comptime BIOME_EXPRESSION_OP_COPY_SIGN: Int32 = 16
"""Go `BiomeExpressionOpCopySign`."""
comptime BIOME_EXPRESSION_COS: Int32 = 17
"""Go `BiomeExpressionCos`."""
comptime BIOME_EXPRESSION_DIE_ROLL: Int32 = 18
"""Go `BiomeExpressionDieRoll`."""
comptime BIOME_EXPRESSION_DIE_ROLL_INT: Int32 = 19
"""Go `BiomeExpressionDieRollInt`."""
comptime BIOME_EXPRESSION_DIV: Int32 = 20
"""Go `BiomeExpressionDiv`."""
comptime BIOME_EXPRESSION_EXP: Int32 = 21
"""Go `BiomeExpressionExp`."""
comptime BIOME_EXPRESSION_FLOOR: Int32 = 22
"""Go `BiomeExpressionFloor`."""
comptime BIOME_EXPRESSION_HERMITE_BLEND: Int32 = 23
"""Go `BiomeExpressionHermiteBlend`."""
comptime BIOME_EXPRESSION_LERP: Int32 = 24
"""Go `BiomeExpressionLerp`."""
comptime BIOME_EXPRESSION_LERP_ROTATE: Int32 = 25
"""Go `BiomeExpressionLerpRotate`."""
comptime BIOME_EXPRESSION_LN: Int32 = 26
"""Go `BiomeExpressionLn`."""
comptime BIOME_EXPRESSION_MAX: Int32 = 27
"""Go `BiomeExpressionMax`."""
comptime BIOME_EXPRESSION_MIN: Int32 = 28
"""Go `BiomeExpressionMin`."""
comptime BIOME_EXPRESSION_MIN_ANGLE: Int32 = 29
"""Go `BiomeExpressionMinAngle`."""
comptime BIOME_EXPRESSION_MOD: Int32 = 30
"""Go `BiomeExpressionMod`."""
comptime BIOME_EXPRESSION_MUL: Int32 = 31
"""Go `BiomeExpressionMul`."""
comptime BIOME_EXPRESSION_POW: Int32 = 32
"""Go `BiomeExpressionPow`."""
comptime BIOME_EXPRESSION_RANDOM: Int32 = 33
"""Go `BiomeExpressionRandom`."""
comptime BIOME_EXPRESSION_RANDOM_INT: Int32 = 34
"""Go `BiomeExpressionRandomInt`."""
comptime BIOME_EXPRESSION_ROUND: Int32 = 35
"""Go `BiomeExpressionRound`."""
comptime BIOME_EXPRESSION_SIN: Int32 = 36
"""Go `BiomeExpressionSin`."""
comptime BIOME_EXPRESSION_SIGN: Int32 = 37
"""Go `BiomeExpressionSign`."""
comptime BIOME_EXPRESSION_SQRT: Int32 = 38
"""Go `BiomeExpressionSqrt`."""
comptime BIOME_EXPRESSION_TRUNC: Int32 = 39
"""Go `BiomeExpressionTrunc`."""
comptime BIOME_EXPRESSION_QUERY_FUNCTION: Int32 = 40
"""Go `BiomeExpressionQueryFunction`."""
comptime BIOME_EXPRESSION_ARRAY_VARIABLE: Int32 = 41
"""Go `BiomeExpressionArrayVariable`."""
comptime BIOME_EXPRESSION_CONTEXT_VARIABLE: Int32 = 42
"""Go `BiomeExpressionContextVariable`."""
comptime BIOME_EXPRESSION_ENTITY_VARIABLE: Int32 = 43
"""Go `BiomeExpressionEntityVariable`."""
comptime BIOME_EXPRESSION_TEMP_VARIABLE: Int32 = 44
"""Go `BiomeExpressionTempVariable`."""
comptime BIOME_EXPRESSION_MEMBER_ACCESSOR: Int32 = 45
"""Go `BiomeExpressionMemberAccessor`."""
comptime BIOME_EXPRESSION_HASHED_STRING_HASH: Int32 = 46
"""Go `BiomeExpressionHashedStringHash`."""
comptime BIOME_EXPRESSION_GEOMETRY_VARIABLE: Int32 = 47
"""Go `BiomeExpressionGeometryVariable`."""
comptime BIOME_EXPRESSION_MATERIAL_VARIABLE: Int32 = 48
"""Go `BiomeExpressionMaterialVariable`."""
comptime BIOME_EXPRESSION_TEXTURE_VARIABLE: Int32 = 49
"""Go `BiomeExpressionTextureVariable`."""
comptime BIOME_EXPRESSION_LESS_THAN: Int32 = 50
"""Go `BiomeExpressionLessThan`."""
comptime BIOME_EXPRESSION_LESS_EQUAL: Int32 = 51
"""Go `BiomeExpressionLessEqual`."""
comptime BIOME_EXPRESSION_GREATER_EQUAL: Int32 = 52
"""Go `BiomeExpressionGreaterEqual`."""
comptime BIOME_EXPRESSION_GREATER_THAN: Int32 = 53
"""Go `BiomeExpressionGreaterThan`."""
comptime BIOME_EXPRESSION_LOGICAL_EQUAL: Int32 = 54
"""Go `BiomeExpressionLogicalEqual`."""
comptime BIOME_EXPRESSION_LOGICAL_NOT_EQUAL: Int32 = 55
"""Go `BiomeExpressionLogicalNotEqual`."""
comptime BIOME_EXPRESSION_LOGICAL_OR: Int32 = 56
"""Go `BiomeExpressionLogicalOr`."""
comptime BIOME_EXPRESSION_LOGICAL_AND: Int32 = 57
"""Go `BiomeExpressionLogicalAnd`."""
comptime BIOME_EXPRESSION_NULL_COALESCING: Int32 = 58
"""Go `BiomeExpressionNullCoalescing`."""
comptime BIOME_EXPRESSION_CONDITIONAL: Int32 = 59
"""Go `BiomeExpressionConditional`."""
comptime BIOME_EXPRESSION_CONDITIONAL_ELSE: Int32 = 60
"""Go `BiomeExpressionConditionalElse`."""
comptime BIOME_EXPRESSION_FLOAT: Int32 = 61
"""Go `BiomeExpressionFloat`."""
comptime BIOME_EXPRESSION_PI: Int32 = 62
"""Go `BiomeExpressionPi`."""
comptime BIOME_EXPRESSION_ARRAY: Int32 = 63
"""Go `BiomeExpressionArray`."""
comptime BIOME_EXPRESSION_GEOMETRY: Int32 = 64
"""Go `BiomeExpressionGeometry`."""
comptime BIOME_EXPRESSION_MATERIAL: Int32 = 65
"""Go `BiomeExpressionMaterial`."""
comptime BIOME_EXPRESSION_TEXTURE: Int32 = 66
"""Go `BiomeExpressionTexture`."""
comptime BIOME_EXPRESSION_LOOP: Int32 = 67
"""Go `BiomeExpressionLoop`."""
comptime BIOME_EXPRESSION_FOR_EACH: Int32 = 68
"""Go `BiomeExpressionForEach`."""
comptime BIOME_EXPRESSION_BREAK: Int32 = 69
"""Go `BiomeExpressionBreak`."""
comptime BIOME_EXPRESSION_CONTINUE: Int32 = 70
"""Go `BiomeExpressionContinue`."""
comptime BIOME_EXPRESSION_ASSIGNMENT: Int32 = 71
"""Go `BiomeExpressionAssignment`."""
comptime BIOME_EXPRESSION_POINTER: Int32 = 72
"""Go `BiomeExpressionPointer`."""
comptime BIOME_EXPRESSION_SEMICOLON: Int32 = 73
"""Go `BiomeExpressionSemicolon`."""
comptime BIOME_EXPRESSION_RETURN: Int32 = 74
"""Go `BiomeExpressionReturn`."""
comptime BIOME_EXPRESSION_COMMA: Int32 = 75
"""Go `BiomeExpressionComma`."""
comptime BIOME_EXPRESSION_THIS: Int32 = 76
"""Go `BiomeExpressionThis`."""
comptime BIOME_EXPRESSION_NON_EVALUATED_ARRAY: Int32 = 77
"""Go `BiomeExpressionNonEvaluatedArray`."""
comptime BIOME_EXPRESSION_INVERSE_LERP: Int32 = 78
"""Go `BiomeExpressionInverseLerp`."""
comptime BIOME_EXPRESSION_EASE_IN_QUAD: Int32 = 79
"""Go `BiomeExpressionEaseInQuad`."""
comptime BIOME_EXPRESSION_EASE_OUT_QUAD: Int32 = 80
"""Go `BiomeExpressionEaseOutQuad`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_QUAD: Int32 = 81
"""Go `BiomeExpressionEaseInOutQuad`."""
comptime BIOME_EXPRESSION_EASE_IN_CUBIC: Int32 = 82
"""Go `BiomeExpressionEaseInCubic`."""
comptime BIOME_EXPRESSION_EASE_OUT_CUBIC: Int32 = 83
"""Go `BiomeExpressionEaseOutCubic`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_CUBIC: Int32 = 84
"""Go `BiomeExpressionEaseInOutCubic`."""
comptime BIOME_EXPRESSION_EASE_IN_QUART: Int32 = 85
"""Go `BiomeExpressionEaseInQuart`."""
comptime BIOME_EXPRESSION_EASE_OUT_QUART: Int32 = 86
"""Go `BiomeExpressionEaseOutQuart`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_QUART: Int32 = 87
"""Go `BiomeExpressionEaseInOutQuart`."""
comptime BIOME_EXPRESSION_EASE_IN_QUINT: Int32 = 88
"""Go `BiomeExpressionEaseInQuint`."""
comptime BIOME_EXPRESSION_EASE_OUT_QUINT: Int32 = 89
"""Go `BiomeExpressionEaseOutQuint`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_QUINT: Int32 = 90
"""Go `BiomeExpressionEaseInOutQuint`."""
comptime BIOME_EXPRESSION_EASE_IN_SINE: Int32 = 91
"""Go `BiomeExpressionEaseInSine`."""
comptime BIOME_EXPRESSION_EASE_OUT_SINE: Int32 = 92
"""Go `BiomeExpressionEaseOutSine`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_SINE: Int32 = 93
"""Go `BiomeExpressionEaseInOutSine`."""
comptime BIOME_EXPRESSION_EASE_IN_EXPO: Int32 = 94
"""Go `BiomeExpressionEaseInExpo`."""
comptime BIOME_EXPRESSION_EASE_OUT_EXPO: Int32 = 95
"""Go `BiomeExpressionEaseOutExpo`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_EXPO: Int32 = 96
"""Go `BiomeExpressionEaseInOutExpo`."""
comptime BIOME_EXPRESSION_EASE_IN_CIRC: Int32 = 97
"""Go `BiomeExpressionEaseInCirc`."""
comptime BIOME_EXPRESSION_EASE_OUT_CIRC: Int32 = 98
"""Go `BiomeExpressionEaseOutCirc`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_CIRC: Int32 = 99
"""Go `BiomeExpressionEaseInOutCirc`."""
comptime BIOME_EXPRESSION_EASE_IN_BOUNCE: Int32 = 100
"""Go `BiomeExpressionEaseInBounce`."""
comptime BIOME_EXPRESSION_EASE_OUT_BOUNCE: Int32 = 101
"""Go `BiomeExpressionEaseOutBounce`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_BOUNCE: Int32 = 102
"""Go `BiomeExpressionEaseInOutBounce`."""
comptime BIOME_EXPRESSION_EASE_IN_BACK: Int32 = 103
"""Go `BiomeExpressionEaseInBack`."""
comptime BIOME_EXPRESSION_EASE_OUT_BACK: Int32 = 104
"""Go `BiomeExpressionEaseOutBack`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_BACK: Int32 = 105
"""Go `BiomeExpressionEaseInOutBack`."""
comptime BIOME_EXPRESSION_EASE_IN_ELASTIC: Int32 = 106
"""Go `BiomeExpressionEaseInElastic`."""
comptime BIOME_EXPRESSION_EASE_OUT_ELASTIC: Int32 = 107
"""Go `BiomeExpressionEaseOutElastic`."""
comptime BIOME_EXPRESSION_EASE_IN_OUT_ELASTIC: Int32 = 108
"""Go `BiomeExpressionEaseInOutElastic`."""
comptime BIOME_EXPRESSION_COUNT: Int32 = 109
"""Go `BiomeExpressionCount`."""

comptime BIOME_COORDINATE_EVALUATION_ORDER_XYZ: Int32 = 0
"""Go `BiomeCoordinateEvaluationOrderXYZ`."""
comptime BIOME_COORDINATE_EVALUATION_ORDER_XZY: Int32 = 1
"""Go `BiomeCoordinateEvaluationOrderXZY`."""
comptime BIOME_COORDINATE_EVALUATION_ORDER_YXZ: Int32 = 2
"""Go `BiomeCoordinateEvaluationOrderYXZ`."""
comptime BIOME_COORDINATE_EVALUATION_ORDER_YZX: Int32 = 3
"""Go `BiomeCoordinateEvaluationOrderYZX`."""
comptime BIOME_COORDINATE_EVALUATION_ORDER_ZXY: Int32 = 4
"""Go `BiomeCoordinateEvaluationOrderZXY`."""
comptime BIOME_COORDINATE_EVALUATION_ORDER_ZYX: Int32 = 5
"""Go `BiomeCoordinateEvaluationOrderZYX`."""

comptime BIOME_RANDOM_DISTRIBUTION_TYPE_SINGLE_VALUED: Int32 = 0
"""Go `BiomeRandomDistributionTypeSingleValued`."""
comptime BIOME_RANDOM_DISTRIBUTION_TYPE_UNIFORM: Int32 = 1
"""Go `BiomeRandomDistributionTypeUniform`."""
comptime BIOME_RANDOM_DISTRIBUTION_TYPE_GAUSSIAN: Int32 = 2
"""Go `BiomeRandomDistributionTypeGaussian`."""
comptime BIOME_RANDOM_DISTRIBUTION_TYPE_INVERSE_GAUSSIAN: Int32 = 3
"""Go `BiomeRandomDistributionTypeInverseGaussian`."""
comptime BIOME_RANDOM_DISTRIBUTION_TYPE_FIXED_GRID: Int32 = 4
"""Go `BiomeRandomDistributionTypeFixedGrid`."""
comptime BIOME_RANDOM_DISTRIBUTION_TYPE_JITTERED_GRID: Int32 = 5
"""Go `BiomeRandomDistributionTypeJitteredGrid`."""
comptime BIOME_RANDOM_DISTRIBUTION_TYPE_TRIANGLE: Int32 = 6
"""Go `BiomeRandomDistributionTypeTriangle`."""


struct BiomeDefinition(Marshaler):
    """A biome definition in the game."""

    var name_index: Int16
    """Represents the index of the biome name in the string list."""
    var biome_id: Int16
    """The biome ID."""
    var temperature: Float32
    """The temperature of the biome, used for weather, biome behaviours and sky
    colour.
    """
    var downfall: Float32
    """The amount that precipitation affects colours and block changes."""
    var foliage_snow: Float32
    """The progression factor for foliage turning white due to snow."""
    var depth: Float32
    """The depth of the biome."""
    var scale: Float32
    """The scale of the biome."""
    var map_water_colour: Int32
    """An ARGB value for the water colour on maps in the biome."""
    var rain: Bool
    """True if the biome has rain, false if it is a dry biome."""
    var tags: Optional[List[UInt16]]
    """A list of indices of tags in the string list."""
    var chunk_generation: Optional[BiomeChunkGeneration]
    """Optional information to assist in client-side chunk generation."""

    def __init__(out self):
        """Creates the zero value."""
        self.name_index = 0
        self.biome_id = 0
        self.temperature = 0
        self.downfall = 0
        self.foliage_snow = 0
        self.depth = 0
        self.scale = 0
        self.map_water_colour = 0
        self.rain = False
        self.tags = None
        self.chunk_generation = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int16(self.name_index)
        io.int16(self.biome_id)
        io.float32(self.temperature)
        io.float32(self.downfall)
        io.float32(self.foliage_snow)
        io.float32(self.depth)
        io.float32(self.scale)
        io.int32(self.map_water_colour)
        io.bool(self.rain)
        optional_func[func_slice[I.uint16]](io, self.tags)
        optional_marshaler(io, self.chunk_generation)


struct BiomeChunkGeneration(Marshaler):
    """The information required for the client to generate chunks itself to
    create the illusion of a larger render distance.
    """

    var climate: Optional[BiomeClimate]
    """Optional information to specify the biome's climate."""
    var consolidated_features: Optional[List[BiomeConsolidatedFeature]]
    """A list of features that are consolidated into a single feature."""
    var mountain_parameters: Optional[BiomeMountainParameters]
    """Optional information to specify the biome's mountain parameters."""
    var surface_material_adjustments: Optional[List[BiomeElementData]]
    """A list of surface material adjustments."""
    var surface_materials: Optional[BiomeSurfaceMaterial]
    """A set of materials to use for the surface layers of the biome. Not sent:
    Go does not marshal this field.
    """
    var has_default_overworld_surface: Bool
    """True if the biome has a default overworld surface. Not sent: Go does not
    marshal this field.
    """
    var has_swamp_surface: Bool
    """True if the biome has a swamp surface. Not sent: Go does not marshal this
    field.
    """
    var has_frozen_ocean_surface: Bool
    """True if the biome has a frozen ocean surface. Not sent: Go does not
    marshal this field.
    """
    var has_end_surface: Bool
    """True if the biome has an end surface. Not sent: Go does not marshal this
    field.
    """
    var mesa_surface: Optional[BiomeMesaSurface]
    """Optional information to specify the biome's mesa surface. Not sent: Go
    does not marshal this field.
    """
    var capped_surface: Optional[BiomeCappedSurface]
    """Optional information to specify the biome's capped surface, i.e. in the
    Nether. Not sent: Go does not marshal this field.
    """
    var overworld_rules: Optional[BiomeOverworldRules]
    """Optional information to specify the biome's overworld rules, such as
    rivers and hills.
    """
    var multi_noise_rules: Optional[BiomeMultiNoiseRules]
    """Optional information to specify the biome's multi-noise rules."""
    var legacy_rules: Optional[List[BiomeConditionalTransformation]]
    """A list of legacy rules for the biomes using an older format, which is
    just a list of weighted biomes.
    """
    var replacements_data: Optional[List[BiomeReplacementData]]
    """A list of biome replacement data."""
    var village_type: Optional[UInt8]
    """The optional village type for the biome's chunk generation."""
    var surface_builder: Optional[BiomeSurfaceBuilder]
    """Optional information for the biome's surface builder."""
    var subsurface_builder: Optional[BiomeSurfaceBuilder]
    """Optional information for the biome's subsurface builder."""

    def __init__(out self):
        """Creates the zero value."""
        self.climate = None
        self.consolidated_features = None
        self.mountain_parameters = None
        self.surface_material_adjustments = None
        self.surface_materials = None
        self.has_default_overworld_surface = False
        self.has_swamp_surface = False
        self.has_frozen_ocean_surface = False
        self.has_end_surface = False
        self.mesa_surface = None
        self.capped_surface = None
        self.overworld_rules = None
        self.multi_noise_rules = None
        self.legacy_rules = None
        self.replacements_data = None
        self.village_type = None
        self.surface_builder = None
        self.subsurface_builder = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        optional_marshaler(io, self.climate)
        optional_func[slice[BiomeConsolidatedFeature, I]](
            io, self.consolidated_features
        )
        optional_marshaler(io, self.mountain_parameters)
        optional_func[slice[BiomeElementData, I]](
            io, self.surface_material_adjustments
        )
        optional_marshaler(io, self.overworld_rules)
        optional_marshaler(io, self.multi_noise_rules)
        optional_func[slice[BiomeConditionalTransformation, I]](
            io, self.legacy_rules
        )
        optional_func[slice[BiomeReplacementData, I]](
            io, self.replacements_data
        )
        optional_func[I.uint8](io, self.village_type)
        optional_marshaler(io, self.surface_builder)
        optional_marshaler(io, self.subsurface_builder)


struct BiomeClimate(Marshaler):
    """The climate of a biome, mainly for ambience but also defines certain
    behaviours.
    """

    var temperature: Float32
    """The temperature of the biome, used for weather, biome behaviours and sky
    colour.
    """
    var downfall: Float32
    """The amount that precipitation affects colours and block changes."""
    var snow_accumulation_min: Float32
    """The minimum amount of snow that can accumulate in the biome, every 0.125
    is another layer of snow.
    """
    var snow_accumulation_max: Float32
    """The maximum amount of snow that can accumulate in the biome, every 0.125
    is another layer of snow.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.temperature = 0
        self.downfall = 0
        self.snow_accumulation_min = 0
        self.snow_accumulation_max = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.temperature)
        io.float32(self.downfall)
        io.float32(self.snow_accumulation_min)
        io.float32(self.snow_accumulation_max)


struct BiomeConsolidatedFeature(Marshaler):
    """A feature that is consolidated into a single feature for the biome."""

    var scatter: BiomeScatterParameter
    """Defines how the feature is scattered in the biome."""
    var feature: Int16
    """The index of the feature's name in the string list."""
    var identifier: Int16
    """The index of the feature's identifier in the string list."""
    var pass_: Int16
    """The index of the feature's pass in the string list."""
    var can_use_internal: Bool
    """True if the feature can use internal features."""

    def __init__(out self):
        """Creates the zero value."""
        self.scatter = BiomeScatterParameter()
        self.feature = 0
        self.identifier = 0
        self.pass_ = 0
        self.can_use_internal = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        self.scatter.marshal(io)
        io.int16(self.feature)
        io.int16(self.identifier)
        io.int16(self.pass_)
        io.bool(self.can_use_internal)


struct BiomeScatterParameter(Marshaler):
    """Scatter parameters of a consolidated feature."""

    var coordinates: List[BiomeCoordinate]
    """A list of coordinate rules to scatter the feature within."""
    var evaluation_order: Int32
    """The order in which the coordinates are evaluated, and is one of the
    CoordinateEvaluationOrder constants above.
    """
    var chance_percent_type: Int32
    """The type of expression operation to use for the chance percent, and is
    one of the BiomeExpressionOp constants above.
    """
    var chance_percent: Int16
    """ChangePercent is the index of the chance expression in the string list.
    """
    var chance_numerator: Int32
    """The numerator of the chance expression."""
    var chance_denominator: Int32
    """The denominator of the chance expression."""
    var iterations_type: Int32
    """The type of expression operation to use for the iterations, and is one of
    the BiomeExpressionOp constants above.
    """
    var iterations: Int16
    """The index of the iterations expression in the string list."""

    def __init__(out self):
        """Creates the zero value."""
        self.coordinates = List[BiomeCoordinate]()
        self.evaluation_order = 0
        self.chance_percent_type = 0
        self.chance_percent = 0
        self.chance_numerator = 0
        self.chance_denominator = 0
        self.iterations_type = 0
        self.iterations = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.coordinates)
        io.varint32(self.evaluation_order)
        io.varint32(self.chance_percent_type)
        io.int16(self.chance_percent)
        io.int32(self.chance_numerator)
        io.int32(self.chance_denominator)
        io.varint32(self.iterations_type)
        io.int16(self.iterations)


struct BiomeCoordinate(Marshaler):
    """Coordinate rules for where features can be scattered in the biome."""

    var min_value_type: Int32
    """The type of expression operation to use for the minimum value, and is one
    of the BiomeExpressionOp constants above.
    """
    var min_value: Int16
    """The index of the minimum value expression in the string list."""
    var max_value_type: Int32
    """The type of expression operation to use for the maximum value, and is one
    of the.
    """
    var max_value: Int16
    """The index of the maximum value expression in the string list."""
    var grid_offset: UInt32
    """The offset of the grid, used for fixed grid and jittered grid
    distributions.
    """
    var grid_step_size: UInt32
    """The step size of the grid, used for fixed grid and jittered grid
    distributions.
    """
    var distribution: Int32
    """The type of distribution to use for the coordinate, and is one of the
    BiomeRandomDistributionType constants above.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.min_value_type = 0
        self.min_value = 0
        self.max_value_type = 0
        self.max_value = 0
        self.grid_offset = 0
        self.grid_step_size = 0
        self.distribution = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.min_value_type)
        io.int16(self.min_value)
        io.varint32(self.max_value_type)
        io.int16(self.max_value)
        io.uint32(self.grid_offset)
        io.uint32(self.grid_step_size)
        io.varint32(self.distribution)


struct BiomeMountainParameters(Marshaler):
    """The parameters for a mountain biome."""

    var steep_block: Int32
    """The runtime ID of the block to use for steep slopes."""
    var north_slopes: Bool
    """True if the biome has north slopes."""
    var south_slopes: Bool
    """True if the biome has south slopes."""
    var west_slopes: Bool
    """True if the biome has west slopes."""
    var east_slopes: Bool
    """True if the biome has east slopes."""
    var top_slide_enabled: Bool
    """True if the biome has top slide enabled."""

    def __init__(out self):
        """Creates the zero value."""
        self.steep_block = 0
        self.north_slopes = False
        self.south_slopes = False
        self.west_slopes = False
        self.east_slopes = False
        self.top_slide_enabled = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int32(self.steep_block)
        io.bool(self.north_slopes)
        io.bool(self.south_slopes)
        io.bool(self.west_slopes)
        io.bool(self.east_slopes)
        io.bool(self.top_slide_enabled)


struct BiomeElementData(Marshaler):
    """Set rules to adjust the surface materials of the biome."""

    var noise_frequency_scale: Float32
    """The frequency scale of the noise used to adjust the surface materials."""
    var noise_lower_bound: Float32
    """The minimum noise value required to be selected."""
    var noise_upper_bound: Float32
    """The maximum noise value required to be selected."""
    var height_min_type: Int32
    """The type of expression operation to use for the minimum height, and is
    one of the BiomeExpressionOp constants above.
    """
    var height_min: Int16
    """The index of the minimum height expression in the string list."""
    var height_max_type: Int32
    """The type of expression operation to use for the maximum height, and is
    one of the BiomeExpressionOp constants above.
    """
    var height_max: Int16
    """The index of the maximum height expression in the string list."""
    var adjusted_materials: BiomeSurfaceMaterial
    """The materials to use for the surface layers of the biome if selected."""

    def __init__(out self):
        """Creates the zero value."""
        self.noise_frequency_scale = 0
        self.noise_lower_bound = 0
        self.noise_upper_bound = 0
        self.height_min_type = 0
        self.height_min = 0
        self.height_max_type = 0
        self.height_max = 0
        self.adjusted_materials = BiomeSurfaceMaterial()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.noise_frequency_scale)
        io.float32(self.noise_lower_bound)
        io.float32(self.noise_upper_bound)
        io.varint32(self.height_min_type)
        io.int16(self.height_min)
        io.varint32(self.height_max_type)
        io.int16(self.height_max)
        self.adjusted_materials.marshal(io)


struct BiomeSurfaceMaterial(Marshaler):
    """The materials to use for the surface layers of the biome."""

    var top_block: Int32
    """The runtime ID of the block to use for the top layer."""
    var mid_block: Int32
    """The runtime ID to use for the middle layers."""
    var sea_floor_block: Int32
    """The runtime ID to use for the sea floor."""
    var foundation_block: Int32
    """The runtime ID to use for the foundation layers."""
    var sea_block: Int32
    """The runtime ID to use for the sea layers."""
    var sea_floor_depth: Int32
    """The depth of the sea floor, in blocks."""

    def __init__(out self):
        """Creates the zero value."""
        self.top_block = 0
        self.mid_block = 0
        self.sea_floor_block = 0
        self.foundation_block = 0
        self.sea_block = 0
        self.sea_floor_depth = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int32(self.top_block)
        io.int32(self.mid_block)
        io.int32(self.sea_floor_block)
        io.int32(self.foundation_block)
        io.int32(self.sea_block)
        io.int32(self.sea_floor_depth)


struct BiomeSurfaceBuilder(Marshaler):
    """The materials and special surface rules to use for a biome surface."""

    var surface_materials: Optional[BiomeSurfaceMaterial]
    """A set of materials to use for the surface layers of the biome."""
    var has_default_overworld_surface: Bool
    """True if the biome has a default overworld surface."""
    var has_swamp_surface: Bool
    """True if the biome has a swamp surface."""
    var has_frozen_ocean_surface: Bool
    """True if the biome has a frozen ocean surface."""
    var has_end_surface: Bool
    """True if the biome has an end surface."""
    var mesa_surface: Optional[BiomeMesaSurface]
    """Optional information to specify the biome's mesa surface."""
    var capped_surface: Optional[BiomeCappedSurface]
    """Optional information to specify the biome's capped surface, i.e. in the
    Nether.
    """
    var noise_gradient_surface: Optional[BiomeNoiseGradientSurface]
    """Optional information to specify noise-gradient surface data."""

    def __init__(out self):
        """Creates the zero value."""
        self.surface_materials = None
        self.has_default_overworld_surface = False
        self.has_swamp_surface = False
        self.has_frozen_ocean_surface = False
        self.has_end_surface = False
        self.mesa_surface = None
        self.capped_surface = None
        self.noise_gradient_surface = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        optional_marshaler(io, self.surface_materials)
        io.bool(self.has_default_overworld_surface)
        io.bool(self.has_swamp_surface)
        io.bool(self.has_frozen_ocean_surface)
        io.bool(self.has_end_surface)
        optional_marshaler(io, self.mesa_surface)
        optional_marshaler(io, self.capped_surface)
        optional_marshaler(io, self.noise_gradient_surface)


struct BiomeNoiseGradientSurface(Marshaler):
    """Noise-gradient surface block data for a biome."""

    var non_replaceable_blocks: List[UInt32]
    """A list of block runtime IDs that may not be replaced."""
    var gradient_blocks: List[NoiseBlockSpecifier]
    """A list of noise block specifiers used by the gradient."""
    var noise: NoiseDescriptor
    """The noise descriptor used by the gradient."""

    def __init__(out self):
        """Creates the zero value."""
        self.non_replaceable_blocks = List[UInt32]()
        self.gradient_blocks = List[NoiseBlockSpecifier]()
        self.noise = NoiseDescriptor()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        func_slice[I.uint32](io, self.non_replaceable_blocks)
        slice(io, self.gradient_blocks)
        self.noise.marshal(io)


struct FloatRange(Marshaler):
    """An inclusive minimum/maximum pair of float32 values."""

    var min: Float32
    """The minimum value of the range."""
    var max: Float32
    """The maximum value of the range."""

    def __init__(out self):
        """Creates the zero value."""
        self.min = 0
        self.max = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.min)
        io.float32(self.max)


struct NoiseBlockSpecifier(Marshaler):
    """A block placed by the gradient noise based on a threshold and range."""

    var noise: String
    """The noise name."""
    var threshold: Float32
    """The noise threshold above which the block is placed."""
    var range: FloatRange
    """The noise range within which the block is placed."""
    var block: UInt32
    """The block runtime ID placed by this specifier."""

    def __init__(out self):
        """Creates the zero value."""
        self.noise = String()
        self.threshold = 0
        self.range = FloatRange()
        self.block = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.noise)
        io.float32(self.threshold)
        self.range.marshal(io)
        io.uint32(self.block)


struct NoiseDescriptor(Marshaler):
    """Describes the gradient noise used by a BiomeNoiseGradientSurface."""

    var name: String
    """The string used to initialise the noise."""
    var first_octave: Int32
    """The first octave used by the noise."""
    var amplitudes: List[Float32]
    """A list of amplitude values used by the noise."""

    def __init__(out self):
        """Creates the zero value."""
        self.name = String()
        self.first_octave = 0
        self.amplitudes = List[Float32]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.name)
        io.int32(self.first_octave)
        func_slice[I.float32](io, self.amplitudes)


struct BiomeMesaSurface(Marshaler):
    """The materials to use for the mesa biome."""

    var clay_material: UInt32
    """The runtime ID of the block to use for clay layers."""
    var hard_clay_material: UInt32
    """The runtime ID of the block to use for hard clay layers."""
    var bryce_pillars: Bool
    """True if the biome has bryce pillars, which are tall spire-like
    structures.
    """
    var has_forest: Bool
    """True if the biome has a forest."""

    def __init__(out self):
        """Creates the zero value."""
        self.clay_material = 0
        self.hard_clay_material = 0
        self.bryce_pillars = False
        self.has_forest = False

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint32(self.clay_material)
        io.uint32(self.hard_clay_material)
        io.bool(self.bryce_pillars)
        io.bool(self.has_forest)


struct BiomeCappedSurface(Marshaler):
    """The materials to use for the capped surface of a biome, such as in the
    Nether.
    """

    var floor_blocks: List[Int32]
    """A list of runtime IDs to use for the floor blocks."""
    var ceiling_blocks: List[Int32]
    """A list of runtime IDs to use for the ceiling blocks."""
    var sea_block: Optional[UInt32]
    """An optional runtime ID to use for the sea block."""
    var foundation_block: Optional[UInt32]
    """An optional runtime ID to use for the foundation block."""
    var beach_block: Optional[UInt32]
    """An optional runtime ID to use for the beach block."""

    def __init__(out self):
        """Creates the zero value."""
        self.floor_blocks = List[Int32]()
        self.ceiling_blocks = List[Int32]()
        self.sea_block = None
        self.foundation_block = None
        self.beach_block = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        func_slice[I.int32](io, self.floor_blocks)
        func_slice[I.int32](io, self.ceiling_blocks)
        optional_func[I.uint32](io, self.sea_block)
        optional_func[I.uint32](io, self.foundation_block)
        optional_func[I.uint32](io, self.beach_block)


struct BiomeOverworldRules(Marshaler):
    """A list of transformation rules to apply to different parts of the
    overworld.
    """

    var hills_transformations: List[BiomeWeight]
    """A list of weighted biome transformations to apply to hills."""
    var mutate_transformations: List[BiomeWeight]
    """A list of weighted biome transformations to apply to mutated biomes."""
    var river_transformations: List[BiomeWeight]
    """A list of weighted biome transformations to apply to rivers."""
    var shore_transformations: List[BiomeWeight]
    """A list of weighted biome transformations to apply to shores."""
    var pre_hills_edge_transformations: List[BiomeConditionalTransformation]
    """A list of conditional transformations to apply to the edges of hills."""
    var post_shore_edge_transformations: List[BiomeConditionalTransformation]
    """A list of conditional transformations to apply to the edges of shores."""
    var climate_transformations: List[BiomeTemperatureWeight]
    """A list of weighted temperature transformations to apply to the biome's
    climate.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.hills_transformations = List[BiomeWeight]()
        self.mutate_transformations = List[BiomeWeight]()
        self.river_transformations = List[BiomeWeight]()
        self.shore_transformations = List[BiomeWeight]()
        self.pre_hills_edge_transformations = List[
            BiomeConditionalTransformation
        ]()
        self.post_shore_edge_transformations = List[
            BiomeConditionalTransformation
        ]()
        self.climate_transformations = List[BiomeTemperatureWeight]()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.hills_transformations)
        slice(io, self.mutate_transformations)
        slice(io, self.river_transformations)
        slice(io, self.shore_transformations)
        slice(io, self.pre_hills_edge_transformations)
        slice(io, self.post_shore_edge_transformations)
        slice(io, self.climate_transformations)


struct BiomeMultiNoiseRules(Marshaler):
    """The rules for multi-noise biomes, which are biomes that are defined by
    multiple noise parameters instead of just temperature and humidity.
    """

    var temperature: Float32
    """The temperature level of the biome."""
    var humidity: Float32
    """The humidity level of the biome."""
    var altitude: Float32
    """The altitude level of the biome."""
    var weirdness: Float32
    """The weirdness level of the biome."""
    var weight: Float32
    """The weight of the biome, with a higher weight being more likely to be
    selected.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.temperature = 0
        self.humidity = 0
        self.altitude = 0
        self.weirdness = 0
        self.weight = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.temperature)
        io.float32(self.humidity)
        io.float32(self.altitude)
        io.float32(self.weirdness)
        io.float32(self.weight)


struct BiomeConditionalTransformation(Marshaler):
    """The legacy method of transforming biomes."""

    var weighted_biomes: List[BiomeWeight]
    """A list of biomes and their weights."""
    var condition_json: Int16
    """An index of the condition JSON data in the string list."""
    var min_passing_neighbours: UInt32
    """The minimum number of neighbours that must pass the condition for the
    transformation to be applied.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.weighted_biomes = List[BiomeWeight]()
        self.condition_json = 0
        self.min_passing_neighbours = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        slice(io, self.weighted_biomes)
        io.int16(self.condition_json)
        io.uint32(self.min_passing_neighbours)


struct BiomeWeight(Marshaler):
    """The weight for a biome, used for weighted randomness."""

    var biome: Int16
    """The index of the biome name in the string list."""
    var weight: UInt32
    """The weight of the biome, with a higher weight being more likely to be
    selected.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.biome = 0
        self.weight = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int16(self.biome)
        io.uint32(self.weight)


struct BiomeTemperatureWeight(Marshaler):
    """The weight for a temperature, used for weighted randomness."""

    var temperature: Int32
    """The temperature that can be selected."""
    var weight: UInt32
    """The weight of the temperature, with a higher weight being more likely to
    be selected.
    """

    def __init__(out self):
        """Creates the zero value."""
        self.temperature = 0
        self.weight = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.varint32(self.temperature)
        io.uint32(self.weight)


struct BiomeReplacementData(Marshaler):
    """Data for biome replacements."""

    var biome: Int16
    """The biome ID to replace."""
    var dimension: Int16
    """The dimension ID where the replacement applies."""
    var target_biomes: List[Int16]
    """A list of target biome IDs for the replacement."""
    var amount: Float32
    """The amount of replacement to apply."""
    var noise_frequency_scale: Float32
    """The NoiseFrequencyScale."""
    var replacement_index: UInt32
    """The index of the replacement."""

    def __init__(out self):
        """Creates the zero value."""
        self.biome = 0
        self.dimension = 0
        self.target_biomes = List[Int16]()
        self.amount = 0
        self.noise_frequency_scale = 0
        self.replacement_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes every field.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.int16(self.biome)
        io.int16(self.dimension)
        func_slice[I.int16](io, self.target_biomes)
        io.float32(self.amount)
        io.float32(self.noise_frequency_scale)
        io.uint32(self.replacement_index)
