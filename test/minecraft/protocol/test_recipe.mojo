# Expected bytes come from gophertunnel v1.63.0.
from minecraft.protocol.io import Marshaler
from minecraft.protocol.item import ItemStack, ItemType
from minecraft.protocol.item_descriptor import (
    DefaultItemDescriptor,
    InvalidItemDescriptor,
    ItemDescriptorCount,
    ItemTagItemDescriptor,
    MoLangItemDescriptor,
)
from minecraft.protocol.reader import Reader
from minecraft.protocol.recipe import (
    RECIPE_UNLOCK_CONTEXT_ALWAYS_UNLOCKED,
    RECIPE_UNLOCK_CONTEXT_NONE,
    MultiRecipe,
    PotionContainerChangeRecipe,
    PotionRecipe,
    RecipeUnlockRequirement,
    ShapedChemistryRecipe,
    ShapedRecipe,
    ShapelessChemistryRecipe,
    ShapelessRecipe,
    SmithingTransformRecipe,
    SmithingTrimRecipe,
    UserDataShapelessRecipe,
)
from minecraft.protocol.uuid import UUID
from minecraft.protocol.writer import Writer
from nethernet.wire import hex_decode, hex_encode
from std.testing import TestSuite, assert_equal, assert_raises, assert_true

comptime INPUTS_HEX = (
    "0201046e616d65106d696e6563726166743a706c616e6b73feff030201086974656d5f74"
    "61670e6d696e6563726166743a6c6f6773feff0302"
)
comptime OUTPUT_HEX = "01b004040000000a00000000000000000000"
comptime UUID_HEX = "7766554433221100ffeeddccbbaa9988"
comptime UNLOCK_HEX = (
    "0100010101046e616d65106d696e6563726166743a706c616e6b73feff0302"
)


def _encode[T: Marshaler](mut x: T) raises -> String:
    var w = Writer()
    x.marshal(w)
    return hex_encode(Span(w.buf))


def _decode[T: Marshaler](hex: StringSpan) raises -> T:
    var data = hex_decode(hex)
    var r = Reader(Span(data))
    var x = T()
    x.marshal(r)
    assert_equal(r.remaining(), 0)
    assert_equal(_encode(x), String(hex))
    return x^


def _inputs() -> List[ItemDescriptorCount]:
    return [
        ItemDescriptorCount(
            DefaultItemDescriptor("minecraft:planks", 32767), 1
        ),
        ItemDescriptorCount(ItemTagItemDescriptor("minecraft:logs"), 1),
    ]


def _outputs() -> List[ItemStack]:
    return [ItemStack(ItemType(280, 0), 4)]


def _uuid() raises -> UUID:
    return UUID.parse("00112233-4455-6677-8899-aabbccddeeff")


def _unlock() -> RecipeUnlockRequirement:
    var u = RecipeUnlockRequirement()
    u.context = RECIPE_UNLOCK_CONTEXT_NONE
    u.ingredients = [
        ItemDescriptorCount(DefaultItemDescriptor("minecraft:planks", 32767), 1)
    ]
    return u^


def _shapeless() raises -> ShapelessRecipe:
    var s = ShapelessRecipe()
    s.recipe_id = "sticks"
    s.input = _inputs()
    s.output = _outputs()
    s.uuid = _uuid()
    s.block = "crafting_table"
    s.priority = 1
    s.unlock_requirement = _unlock()
    s.recipe_network_id = 11
    return s^


def test_shapeless_recipes() raises:
    var s = _shapeless()
    comptime want = (
        "06737469636b73"
        + INPUTS_HEX
        + OUTPUT_HEX
        + UUID_HEX
        + "0e6372616674696e675f7461626c6502"
        + UNLOCK_HEX
        + "0b"
    )
    assert_equal(_encode(s), want)
    var back = _decode[ShapelessRecipe](want)
    assert_true(back.uuid == _uuid())
    assert_equal(back.unlock_requirement.value().ingredients[0].count, 1)
    var ud: UserDataShapelessRecipe = _shapeless()
    var always = RecipeUnlockRequirement()
    always.context = RECIPE_UNLOCK_CONTEXT_ALWAYS_UNLOCKED
    ud.unlock_requirement = always^
    comptime want_ud = (
        "06737469636b73"
        + INPUTS_HEX
        + OUTPUT_HEX
        + UUID_HEX
        + "0e6372616674696e675f7461626c6502010200"
        + "0b"
    )
    assert_equal(_encode(ud), want_ud)
    _ = _decode[UserDataShapelessRecipe](want_ud)
    var chem = ShapelessChemistryRecipe()
    chem.recipe_id = "c"
    chem.block = "compound_creator"
    chem.recipe_network_id = 12
    comptime want_chem = (
        "016300000000000000000000000000000000000010636f6d706f756e645f63726561"
        "746f7200000c"
    )
    assert_equal(_encode(chem), want_chem)
    _ = _decode[ShapelessChemistryRecipe](want_chem)


def test_shaped_recipes() raises:
    var s = ShapedRecipe()
    s.recipe_id = "door"
    s.width = 1
    s.height = 2
    s.input = _inputs()
    s.output = _outputs()
    s.uuid = _uuid()
    s.block = "crafting_table"
    s.priority = -1
    s.assume_symmetry = True
    s.unlock_requirement = _unlock()
    s.recipe_network_id = 13
    comptime want = (
        "04646f6f720204"
        + INPUTS_HEX
        + OUTPUT_HEX
        + UUID_HEX
        + "0e6372616674696e675f7461626c650101"
        + UNLOCK_HEX
        + "0d"
    )
    assert_equal(_encode(s), want)
    assert_equal(_decode[ShapedRecipe](want).height, 2)
    var chem = ShapedChemistryRecipe()
    chem.recipe_id = "e"
    chem.block = "lab_table"
    chem.recipe_network_id = 14
    comptime want_chem = (
        "01650000000000000000000000000000000000000000096c61625f7461626c650000"
        "000e"
    )
    assert_equal(_encode(chem), want_chem)
    _ = _decode[ShapedChemistryRecipe](want_chem)


def test_shaped_ingredient_count_must_match_shape() raises:
    var s = ShapedRecipe()
    s.width = 2
    s.height = 2
    s.input = _inputs()
    with assert_raises(contains="width multiplied by height"):
        _ = _encode(s)
    # Width 1, height 1, two ingredients.
    with assert_raises(contains="width multiplied by height"):
        _ = _decode[ShapedRecipe]("000202" + INPUTS_HEX)


def test_multi_recipe() raises:
    var m = MultiRecipe()
    m.uuid = _uuid()
    m.recipe_network_id = 15
    assert_equal(_encode(m), UUID_HEX + "0f")
    assert_equal(_decode[MultiRecipe](UUID_HEX + "0f").recipe_network_id, 15)


def test_smithing_recipes() raises:
    var t = SmithingTransformRecipe()
    t.recipe_network_id = 16
    t.recipe_id = "st"
    t.template = ItemDescriptorCount(
        DefaultItemDescriptor(
            "minecraft:netherite_upgrade_smithing_template", 0
        ),
        1,
    )
    t.base = ItemDescriptorCount(
        DefaultItemDescriptor("minecraft:diamond_sword", 0), 1
    )
    t.addition = ItemDescriptorCount(
        ItemTagItemDescriptor("minecraft:netherite"), 1
    )
    t.result = ItemStack(ItemType(700, 0), 1)
    t.block = "smithing_table"
    comptime want = (
        "02737401046e616d652d6d696e6563726166743a6e65746865726974655f75706772"
        "6164655f736d697468696e675f74656d706c617465000201046e616d65176d696e65"
        "63726166743a6469616d6f6e645f73776f7264000201086974656d5f746167136d69"
        "6e6563726166743a6e6574686572697465feff0302f80a010000000a000000000000"
        "000000000e736d697468696e675f7461626c6510"
    )
    assert_equal(_encode(t), want)
    assert_equal(
        _decode[SmithingTransformRecipe](want).result.item_type.network_id, 700
    )
    var trim = SmithingTrimRecipe()
    trim.recipe_network_id = 17
    trim.recipe_id = "trim"
    trim.template = ItemDescriptorCount(
        ItemTagItemDescriptor("minecraft:trim_templates"), 1
    )
    trim.base = ItemDescriptorCount(MoLangItemDescriptor("q.is_armor", 1), 1)
    trim.addition = ItemDescriptorCount(InvalidItemDescriptor(), 0)
    trim.block = "smithing_table"
    comptime want_trim = (
        "047472696d01086974656d5f746167186d696e6563726166743a7472696d5f74656d"
        "706c61746573feff030201066d6f6c616e670a712e69735f61726d6f720100020"
        "0feff03000e736d697468696e675f7461626c6511"
    )
    assert_equal(_encode(trim), want_trim)
    _ = _decode[SmithingTrimRecipe](want_trim)


def test_potion_recipes() raises:
    var p = PotionRecipe(1, 2, 3, 4, 5, -6)
    assert_equal(_encode(p), "020406080a0b")
    assert_equal(
        _decode[PotionRecipe]("020406080a0b").output_potion_metadata, -6
    )
    var c = PotionContainerChangeRecipe(100, 200, 300)
    assert_equal(_encode(c), "c8019003d804")
    _ = _decode[PotionContainerChangeRecipe]("c8019003d804")


def test_malformed_recipes_are_rejected() raises:
    # Truncated inside the UUID.
    with assert_raises():
        _ = _decode[MultiRecipe]("77665544")
    # An ingredient count larger than the payload.
    with assert_raises(contains="exceeds remaining"):
        _ = _decode[ShapelessRecipe]("0073")
    # An ingredient count over the slice limit.
    with assert_raises(contains="too long"):
        _ = _decode[RecipeUnlockRequirement]("0001ffff03")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
