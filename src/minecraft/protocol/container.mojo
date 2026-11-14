"""Container IDs, types and names (gophertunnel `protocol/container.go`)."""

from .io import IO, Marshaler, optional_uint32

comptime CONTAINER_ANVIL_INPUT: UInt8 = 0
"""The anvil input container ID."""
comptime CONTAINER_ANVIL_MATERIAL: UInt8 = 1
"""The anvil material container ID."""
comptime CONTAINER_ANVIL_RESULT_PREVIEW: UInt8 = 2
"""The anvil result preview container ID."""
comptime CONTAINER_SMITHING_TABLE_INPUT: UInt8 = 3
"""The smithing table input container ID."""
comptime CONTAINER_SMITHING_TABLE_MATERIAL: UInt8 = 4
"""The smithing table material container ID."""
comptime CONTAINER_SMITHING_TABLE_RESULT_PREVIEW: UInt8 = 5
"""The smithing table result preview container ID."""
comptime CONTAINER_ARMOR: UInt8 = 6
"""The armor container ID."""
comptime CONTAINER_LEVEL_ENTITY: UInt8 = 7
"""The level entity container ID."""
comptime CONTAINER_BEACON_PAYMENT: UInt8 = 8
"""The beacon payment container ID."""
comptime CONTAINER_BREWING_STAND_INPUT: UInt8 = 9
"""The brewing stand input container ID."""
comptime CONTAINER_BREWING_STAND_RESULT: UInt8 = 10
"""The brewing stand result container ID."""
comptime CONTAINER_BREWING_STAND_FUEL: UInt8 = 11
"""The brewing stand fuel container ID."""
comptime CONTAINER_COMBINED_HOT_BAR_AND_INVENTORY: UInt8 = 12
"""The combined hot bar and inventory container ID."""
comptime CONTAINER_CRAFTING_INPUT: UInt8 = 13
"""The crafting input container ID."""
comptime CONTAINER_CRAFTING_OUTPUT_PREVIEW: UInt8 = 14
"""The crafting output preview container ID."""
comptime CONTAINER_RECIPE_CONSTRUCTION: UInt8 = 15
"""The recipe construction container ID."""
comptime CONTAINER_RECIPE_NATURE: UInt8 = 16
"""The recipe nature container ID."""
comptime CONTAINER_RECIPE_ITEMS: UInt8 = 17
"""The recipe items container ID."""
comptime CONTAINER_RECIPE_SEARCH: UInt8 = 18
"""The recipe search container ID."""
comptime CONTAINER_RECIPE_SEARCH_BAR: UInt8 = 19
"""The recipe search bar container ID."""
comptime CONTAINER_RECIPE_EQUIPMENT: UInt8 = 20
"""The recipe equipment container ID."""
comptime CONTAINER_RECIPE_BOOK: UInt8 = 21
"""The recipe book container ID."""
comptime CONTAINER_ENCHANTING_INPUT: UInt8 = 22
"""The enchanting input container ID."""
comptime CONTAINER_ENCHANTING_MATERIAL: UInt8 = 23
"""The enchanting material container ID."""
comptime CONTAINER_FURNACE_FUEL: UInt8 = 24
"""The furnace fuel container ID."""
comptime CONTAINER_FURNACE_INGREDIENT: UInt8 = 25
"""The furnace ingredient container ID."""
comptime CONTAINER_FURNACE_RESULT: UInt8 = 26
"""The furnace result container ID."""
comptime CONTAINER_HORSE_EQUIP: UInt8 = 27
"""The horse equip container ID."""
comptime CONTAINER_HOT_BAR: UInt8 = 28
"""The hot bar container ID."""
comptime CONTAINER_INVENTORY: UInt8 = 29
"""The inventory container ID."""
comptime CONTAINER_SHULKER_BOX: UInt8 = 30
"""The shulker box container ID."""
comptime CONTAINER_TRADE_INGREDIENT_ONE: UInt8 = 31
"""The trade ingredient one container ID."""
comptime CONTAINER_TRADE_INGREDIENT_TWO: UInt8 = 32
"""The trade ingredient two container ID."""
comptime CONTAINER_TRADE_RESULT_PREVIEW: UInt8 = 33
"""The trade result preview container ID."""
comptime CONTAINER_OFFHAND: UInt8 = 34
"""The offhand container ID."""
comptime CONTAINER_COMPOUND_CREATOR_INPUT: UInt8 = 35
"""The compound creator input container ID."""
comptime CONTAINER_COMPOUND_CREATOR_OUTPUT_PREVIEW: UInt8 = 36
"""The compound creator output preview container ID."""
comptime CONTAINER_ELEMENT_CONSTRUCTOR_OUTPUT_PREVIEW: UInt8 = 37
"""The element constructor output preview container ID."""
comptime CONTAINER_MATERIAL_REDUCER_INPUT: UInt8 = 38
"""The material reducer input container ID."""
comptime CONTAINER_MATERIAL_REDUCER_OUTPUT: UInt8 = 39
"""The material reducer output container ID."""
comptime CONTAINER_LAB_TABLE_INPUT: UInt8 = 40
"""The lab table input container ID."""
comptime CONTAINER_LOOM_INPUT: UInt8 = 41
"""The loom input container ID."""
comptime CONTAINER_LOOM_DYE: UInt8 = 42
"""The loom dye container ID."""
comptime CONTAINER_LOOM_MATERIAL: UInt8 = 43
"""The loom material container ID."""
comptime CONTAINER_LOOM_RESULT_PREVIEW: UInt8 = 44
"""The loom result preview container ID."""
comptime CONTAINER_BLAST_FURNACE_INGREDIENT: UInt8 = 45
"""The blast furnace ingredient container ID."""
comptime CONTAINER_SMOKER_INGREDIENT: UInt8 = 46
"""The smoker ingredient container ID."""
comptime CONTAINER_TRADE_TWO_INGREDIENT_ONE: UInt8 = 47
"""The trade two ingredient one container ID."""
comptime CONTAINER_TRADE_TWO_INGREDIENT_TWO: UInt8 = 48
"""The trade two ingredient two container ID."""
comptime CONTAINER_TRADE_TWO_RESULT_PREVIEW: UInt8 = 49
"""The trade two result preview container ID."""
comptime CONTAINER_GRINDSTONE_INPUT: UInt8 = 50
"""The grindstone input container ID."""
comptime CONTAINER_GRINDSTONE_ADDITIONAL: UInt8 = 51
"""The grindstone additional container ID."""
comptime CONTAINER_GRINDSTONE_RESULT_PREVIEW: UInt8 = 52
"""The grindstone result preview container ID."""
comptime CONTAINER_STONECUTTER_INPUT: UInt8 = 53
"""The stonecutter input container ID."""
comptime CONTAINER_STONECUTTER_RESULT_PREVIEW: UInt8 = 54
"""The stonecutter result preview container ID."""
comptime CONTAINER_CARTOGRAPHY_INPUT: UInt8 = 55
"""The cartography input container ID."""
comptime CONTAINER_CARTOGRAPHY_ADDITIONAL: UInt8 = 56
"""The cartography additional container ID."""
comptime CONTAINER_CARTOGRAPHY_RESULT_PREVIEW: UInt8 = 57
"""The cartography result preview container ID."""
comptime CONTAINER_BARREL: UInt8 = 58
"""The barrel container ID."""
comptime CONTAINER_CURSOR: UInt8 = 59
"""The cursor container ID."""
comptime CONTAINER_CREATED_OUTPUT: UInt8 = 60
"""The created output container ID."""
comptime CONTAINER_SMITHING_TABLE_TEMPLATE: UInt8 = 61
"""The smithing table template container ID."""
comptime CONTAINER_CRAFTER_LEVEL_ENTITY: UInt8 = 62
"""The crafter level entity container ID."""
comptime CONTAINER_DYNAMIC: UInt8 = 63
"""The dynamic container ID."""
comptime CONTAINER_RECIPE_FOOD: UInt8 = 64
"""The recipe food container ID."""
comptime CONTAINER_RECIPE_BLOCKS: UInt8 = 65
"""The recipe blocks container ID."""
comptime CONTAINER_RECIPE_FURNACE_ITEMS: UInt8 = 66
"""The recipe furnace items container ID."""
comptime CONTAINER_RESERVED_A: UInt8 = 67
"""The reserved a container ID."""
comptime CONTAINER_RESERVED_B: UInt8 = 68
"""The reserved b container ID."""
comptime CONTAINER_RESERVED_C: UInt8 = 69
"""The reserved c container ID."""
comptime CONTAINER_RESERVED_D: UInt8 = 70
"""The reserved d container ID."""

comptime CONTAINER_TYPE_INVENTORY: UInt8 = 255
"""The inventory container type."""
comptime CONTAINER_TYPE_CONTAINER: UInt8 = 0
"""The container container type."""
comptime CONTAINER_TYPE_WORKBENCH: UInt8 = 1
"""The workbench container type."""
comptime CONTAINER_TYPE_FURNACE: UInt8 = 2
"""The furnace container type."""
comptime CONTAINER_TYPE_ENCHANTMENT: UInt8 = 3
"""The enchantment container type."""
comptime CONTAINER_TYPE_BREWING_STAND: UInt8 = 4
"""The brewing stand container type."""
comptime CONTAINER_TYPE_ANVIL: UInt8 = 5
"""The anvil container type."""
comptime CONTAINER_TYPE_DISPENSER: UInt8 = 6
"""The dispenser container type."""
comptime CONTAINER_TYPE_DROPPER: UInt8 = 7
"""The dropper container type."""
comptime CONTAINER_TYPE_HOPPER: UInt8 = 8
"""The hopper container type."""
comptime CONTAINER_TYPE_CAULDRON: UInt8 = 9
"""The cauldron container type."""
comptime CONTAINER_TYPE_CART_CHEST: UInt8 = 10
"""The cart chest container type."""
comptime CONTAINER_TYPE_CART_HOPPER: UInt8 = 11
"""The cart hopper container type."""
comptime CONTAINER_TYPE_HORSE: UInt8 = 12
"""The horse container type."""
comptime CONTAINER_TYPE_BEACON: UInt8 = 13
"""The beacon container type."""
comptime CONTAINER_TYPE_STRUCTURE_EDITOR: UInt8 = 14
"""The structure editor container type."""
comptime CONTAINER_TYPE_TRADE: UInt8 = 15
"""The trade container type."""
comptime CONTAINER_TYPE_COMMAND_BLOCK: UInt8 = 16
"""The command block container type."""
comptime CONTAINER_TYPE_JUKEBOX: UInt8 = 17
"""The jukebox container type."""
comptime CONTAINER_TYPE_ARMOUR: UInt8 = 18
"""The armour container type."""
comptime CONTAINER_TYPE_HAND: UInt8 = 19
"""The hand container type."""
comptime CONTAINER_TYPE_COMPOUND_CREATOR: UInt8 = 20
"""The compound creator container type."""
comptime CONTAINER_TYPE_ELEMENT_CONSTRUCTOR: UInt8 = 21
"""The element constructor container type."""
comptime CONTAINER_TYPE_MATERIAL_REDUCER: UInt8 = 22
"""The material reducer container type."""
comptime CONTAINER_TYPE_LAB_TABLE: UInt8 = 23
"""The lab table container type."""
comptime CONTAINER_TYPE_LOOM: UInt8 = 24
"""The loom container type."""
comptime CONTAINER_TYPE_LECTERN: UInt8 = 25
"""The lectern container type."""
comptime CONTAINER_TYPE_GRINDSTONE: UInt8 = 26
"""The grindstone container type."""
comptime CONTAINER_TYPE_BLAST_FURNACE: UInt8 = 27
"""The blast furnace container type."""
comptime CONTAINER_TYPE_SMOKER: UInt8 = 28
"""The smoker container type."""
comptime CONTAINER_TYPE_STONECUTTER: UInt8 = 29
"""The stonecutter container type."""
comptime CONTAINER_TYPE_CARTOGRAPHY: UInt8 = 30
"""The cartography container type."""
comptime CONTAINER_TYPE_HUD: UInt8 = 31
"""The hud container type."""
comptime CONTAINER_TYPE_JIGSAW_EDITOR: UInt8 = 32
"""The jigsaw editor container type."""
comptime CONTAINER_TYPE_SMITHING_TABLE: UInt8 = 33
"""The smithing table container type."""
comptime CONTAINER_TYPE_CHEST_BOAT: UInt8 = 34
"""The chest boat container type."""
comptime CONTAINER_TYPE_DECORATED_POT: UInt8 = 35
"""The decorated pot container type."""
comptime CONTAINER_TYPE_CRAFTER: UInt8 = 36
"""The crafter container type."""


struct FullContainerName(Marshaler):
    """Identifies a container in a `StackRequestSlotInfo`."""

    var container_id: UInt8
    """The ID of the container, one of the `CONTAINER_*` constants."""
    var dynamic_container_id: Optional[UInt32]
    """The ID of a dynamic container; absent for other containers."""

    def __init__(out self):
        """Creates the anvil input container with no dynamic ID."""
        self.container_id = 0
        self.dynamic_container_id = None

    def __init__(
        out self, container_id: UInt8, dynamic_container_id: Optional[UInt32]
    ):
        """Creates a container name."""
        self.container_id = container_id
        self.dynamic_container_id = dynamic_container_id

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the container name."""
        io.uint8(self.container_id)
        optional_uint32(io, self.dynamic_container_id)
