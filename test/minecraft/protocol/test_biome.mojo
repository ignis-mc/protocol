from minecraft.protocol.biome import (
    BIOME_COORDINATE_EVALUATION_ORDER_ZYX,
    BIOME_EXPRESSION_FLOAT,
    BIOME_EXPRESSION_OP_ADD,
    BIOME_EXPRESSION_OP_UNKNOWN,
    BIOME_EXPRESSION_RANDOM,
    BIOME_RANDOM_DISTRIBUTION_TYPE_JITTERED_GRID,
    BiomeCappedSurface,
    BiomeChunkGeneration,
    BiomeClimate,
    BiomeConditionalTransformation,
    BiomeConsolidatedFeature,
    BiomeCoordinate,
    BiomeDefinition,
    BiomeElementData,
    BiomeMesaSurface,
    BiomeMountainParameters,
    BiomeMultiNoiseRules,
    BiomeNoiseGradientSurface,
    BiomeOverworldRules,
    BiomeReplacementData,
    BiomeSurfaceBuilder,
    BiomeSurfaceMaterial,
    BiomeTemperatureWeight,
    BiomeWeight,
    NoiseBlockSpecifier,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

# gophertunnel v1.63.0 encodings.
comptime _BIOME_FULL = (
    "03000700cdcc4c3fcdcccc3ecdcccc3d0000003ecdcc4c3df67e26ff01010301"
    + "0002002c010101cdcc4c3fcdcccc3e000000000000003e0101017a0400010500"
    + "06000000070000000a0a42080001000000030000001209000a000b000c000101"
    + "0d000000010001000101010000803f000080bf0000803f040e00060f00010000"
    + "0002000000030000000400000005000000060000000101100011000000000112"
    + "00130000000001011400150000001600170000000001031800000001cdcccc3d"
    + "cdcc4c3e9a99993ecdcccc3e0000003f0100010119000100021a00e5ff000000"
    + "3f000000401c0000000102010101000000020000000300000004000000050000"
    + "000600000001000100011d0000001e000000010001021f000000200000000121"
    + "000000012200000000012300000001012400000001026e7a0000003f000080bf"
    + "0000803f25000000056e6f697365fcffffff020000803f0000003f00"
)
comptime _BIOME_MIN = (
    "0100ffff000000000000000000000000000000000000000000000000000000"
)


def _weight(biome: Int16, weight: UInt32) -> BiomeWeight:
    var w = BiomeWeight()
    w.biome = biome
    w.weight = weight
    return w^


def _surface() -> BiomeSurfaceMaterial:
    var s = BiomeSurfaceMaterial()
    s.top_block = 1
    s.mid_block = 2
    s.sea_floor_block = 3
    s.foundation_block = 4
    s.sea_block = 5
    s.sea_floor_depth = 6
    return s^


def _full_biome() -> BiomeDefinition:
    var b = BiomeDefinition()
    b.name_index = 3
    b.biome_id = 7
    b.temperature = 0.8
    b.downfall = 0.4
    b.foliage_snow = 0.1
    b.depth = 0.125
    b.scale = 0.05
    b.map_water_colour = -14254346
    b.rain = True
    var tags: List[UInt16] = [1, 2, 300]
    b.tags = tags^

    var gen = BiomeChunkGeneration()
    var climate = BiomeClimate()
    climate.temperature = 0.8
    climate.downfall = 0.4
    climate.snow_accumulation_max = 0.125
    gen.climate = climate^

    var coord = BiomeCoordinate()
    coord.min_value_type = BIOME_EXPRESSION_FLOAT
    coord.min_value = 4
    coord.max_value_type = BIOME_EXPRESSION_OP_UNKNOWN
    coord.max_value = 5
    coord.grid_offset = 6
    coord.grid_step_size = 7
    coord.distribution = BIOME_RANDOM_DISTRIBUTION_TYPE_JITTERED_GRID
    var feature = BiomeConsolidatedFeature()
    feature.scatter.coordinates = [coord^]
    feature.scatter.evaluation_order = BIOME_COORDINATE_EVALUATION_ORDER_ZYX
    feature.scatter.chance_percent_type = BIOME_EXPRESSION_RANDOM
    feature.scatter.chance_percent = 8
    feature.scatter.chance_numerator = 1
    feature.scatter.chance_denominator = 3
    feature.scatter.iterations_type = BIOME_EXPRESSION_OP_ADD
    feature.scatter.iterations = 9
    feature.feature = 10
    feature.identifier = 11
    feature.pass_ = 12
    feature.can_use_internal = True
    var features: List[BiomeConsolidatedFeature] = [feature^]
    gen.consolidated_features = features^

    var mountain = BiomeMountainParameters()
    mountain.steep_block = 13
    mountain.north_slopes = True
    mountain.west_slopes = True
    mountain.top_slide_enabled = True
    gen.mountain_parameters = mountain^

    var element = BiomeElementData()
    element.noise_frequency_scale = 1
    element.noise_lower_bound = -1
    element.noise_upper_bound = 1
    element.height_min_type = 2
    element.height_min = 14
    element.height_max_type = 3
    element.height_max = 15
    element.adjusted_materials = _surface()
    var adjustments: List[BiomeElementData] = [element^]
    gen.surface_material_adjustments = adjustments^

    var rules = BiomeOverworldRules()
    rules.hills_transformations = [_weight(16, 17)]
    rules.river_transformations = [_weight(18, 19)]
    var edge = BiomeConditionalTransformation()
    edge.weighted_biomes = [_weight(20, 21)]
    edge.condition_json = 22
    edge.min_passing_neighbours = 23
    rules.pre_hills_edge_transformations = [edge^]
    var temperature = BiomeTemperatureWeight()
    temperature.temperature = -2
    temperature.weight = 24
    rules.climate_transformations = [temperature^]
    gen.overworld_rules = rules^

    var noise = BiomeMultiNoiseRules()
    noise.temperature = 0.1
    noise.humidity = 0.2
    noise.altitude = 0.3
    noise.weirdness = 0.4
    noise.weight = 0.5
    gen.multi_noise_rules = noise^
    gen.legacy_rules = List[BiomeConditionalTransformation]()

    var replacement = BiomeReplacementData()
    replacement.biome = 25
    replacement.dimension = 1
    replacement.target_biomes = [26, -27]
    replacement.amount = 0.5
    replacement.noise_frequency_scale = 2
    replacement.replacement_index = 28
    var replacements: List[BiomeReplacementData] = [replacement^]
    gen.replacements_data = replacements^
    gen.village_type = UInt8(2)

    var builder = BiomeSurfaceBuilder()
    builder.surface_materials = _surface()
    builder.has_default_overworld_surface = True
    builder.has_frozen_ocean_surface = True
    var mesa = BiomeMesaSurface()
    mesa.clay_material = 29
    mesa.hard_clay_material = 30
    mesa.bryce_pillars = True
    builder.mesa_surface = mesa^
    var capped = BiomeCappedSurface()
    capped.floor_blocks = [31, 32]
    capped.ceiling_blocks = [33]
    capped.sea_block = UInt32(34)
    capped.beach_block = UInt32(35)
    builder.capped_surface = capped^
    var gradient = BiomeNoiseGradientSurface()
    gradient.non_replaceable_blocks = [36]
    var spec = NoiseBlockSpecifier()
    spec.noise = "nz"
    spec.threshold = 0.5
    spec.range.min = -1
    spec.range.max = 1
    spec.block = 37
    gradient.gradient_blocks = [spec^]
    gradient.noise.name = "noise"
    gradient.noise.first_octave = -4
    gradient.noise.amplitudes = [1, 0.5]
    builder.noise_gradient_surface = gradient^
    gen.surface_builder = builder^

    b.chunk_generation = gen^
    return b^


def test_full_biome_matches_gophertunnel() raises:
    var b = _full_biome()
    var w = Writer()
    b.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _BIOME_FULL)

    var raw = hex_decode(_BIOME_FULL)
    var r = Reader(Span(raw))
    var back = BiomeDefinition()
    back.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(back.tags.value()[2], 300)
    ref gen = back.chunk_generation.value()
    assert_equal(gen.consolidated_features.value()[0].pass_, 12)
    assert_equal(
        gen.surface_builder.value()
        .noise_gradient_surface.value()
        .noise.first_octave,
        -4,
    )
    assert_equal(len(gen.legacy_rules.value()), 0)
    assert_true(gen.subsurface_builder is None)
    var w2 = Writer()
    back.marshal(w2)
    assert_equal(hex_encode(Span(w2.buf)), _BIOME_FULL)


def test_minimal_biome() raises:
    var b = BiomeDefinition()
    b.name_index = 1
    b.biome_id = -1
    var w = Writer()
    b.marshal(w)
    assert_equal(hex_encode(Span(w.buf)), _BIOME_MIN)


def test_truncated_biome_is_rejected() raises:
    var raw = hex_decode(_BIOME_FULL)
    for cut in [1, 10, 100]:
        var r = Reader(Span(raw)[0 : len(raw) - cut])
        var b = BiomeDefinition()
        with assert_raises():
            b.marshal(r)


def test_oversized_tag_list_is_rejected() raises:
    # A tag count past the payload is refused before allocating.
    # Fixed fields, rain, then a present tag list claiming 65535 entries.
    var raw = hex_decode("0100ffff" + "00" * 24 + "00" + "01" + "ffff03")
    var r = Reader(Span(raw))
    var b = BiomeDefinition()
    with assert_raises(contains="slice length"):
        b.marshal(r)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
