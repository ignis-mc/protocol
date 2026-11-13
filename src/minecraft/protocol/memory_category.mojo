"""Memory and timing diagnostics (gophertunnel `memory_category.go`)."""

from .io import IO, Marshaler, optional_string
from .math import Vec3
from .misc_helpers import optional_vec3

comptime MEMORY_CATEGORY_UNKNOWN: UInt8 = 0
"""The `Unknown` memory category."""
comptime MEMORY_CATEGORY_INVALID_SIZE_UNKNOWN: UInt8 = 1
"""The `Invalid Size Unknown` memory category."""
comptime MEMORY_CATEGORY_ACTOR: UInt8 = 2
"""The `Actor` memory category."""
comptime MEMORY_CATEGORY_ACTOR_ANIMATION: UInt8 = 3
"""The `Actor Animation` memory category."""
comptime MEMORY_CATEGORY_ACTOR_RENDERING: UInt8 = 4
"""The `Actor Rendering` memory category."""
comptime MEMORY_CATEGORY_BLOCK_TICKING_QUEUES: UInt8 = 5
"""The `Block Ticking Queues` memory category."""
comptime MEMORY_CATEGORY_BIOME_STORAGE: UInt8 = 6
"""The `Biome Storage` memory category."""
comptime MEMORY_CATEGORY_BLOBS: UInt8 = 7
"""The `Blobs` memory category."""
comptime MEMORY_CATEGORY_CEREAL: UInt8 = 8
"""The `Cereal` memory category."""
comptime MEMORY_CATEGORY_CIRCUIT_SYSTEM: UInt8 = 9
"""The `Circuit System` memory category."""
comptime MEMORY_CATEGORY_CLIENT: UInt8 = 10
"""The `Client` memory category."""
comptime MEMORY_CATEGORY_COMMANDS: UInt8 = 11
"""The `Commands` memory category."""
comptime MEMORY_CATEGORY_DB_STORAGE: UInt8 = 12
"""The `DB Storage` memory category."""
comptime MEMORY_CATEGORY_DEBUG: UInt8 = 13
"""The `Debug` memory category."""
comptime MEMORY_CATEGORY_DOCUMENTATION: UInt8 = 14
"""The `Documentation` memory category."""
comptime MEMORY_CATEGORY_ECS_SYSTEMS: UInt8 = 15
"""The `ECS Systems` memory category."""
comptime MEMORY_CATEGORY_FMOD: UInt8 = 16
"""The `FMOD` memory category."""
comptime MEMORY_CATEGORY_FONTS: UInt8 = 17
"""The `Fonts` memory category."""
comptime MEMORY_CATEGORY_IM_GUI: UInt8 = 18
"""The `Im GUI` memory category."""
comptime MEMORY_CATEGORY_INPUT: UInt8 = 19
"""The `Input` memory category."""
comptime MEMORY_CATEGORY_JSON_UI: UInt8 = 20
"""The `Json UI` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_FACTORY_JSON: UInt8 = 21
"""The `Json UI Control Factory Json` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE: UInt8 = 22
"""The `Json UI Control Tree` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_CONTROL_ELEMENT: UInt8 = 23
"""The `Json UI Control Tree Control Element` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_DATA_BINDING: UInt8 = 24
"""The `Json UI Control Tree Populate Data Binding` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_FOCUS: UInt8 = 25
"""The `Json UI Control Tree Populate Focus` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_LAYOUT: UInt8 = 26
"""The `Json UI Control Tree Populate Layout` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_OTHER: UInt8 = 27
"""The `Json UI Control Tree Populate Other` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_SPRITE: UInt8 = 28
"""The `Json UI Control Tree Populate Sprite` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_TEXT: UInt8 = 29
"""The `Json UI Control Tree Populate Text` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_POPULATE_TTS: UInt8 = 30
"""The `Json UI Control Tree Populate TTS` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CONTROL_TREE_VISIBILITY: UInt8 = 31
"""The `Json UI Control Tree Visibility` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_CREATE_UI: UInt8 = 32
"""The `Json UI Create UI` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_DEFS: UInt8 = 33
"""The `Json UI Defs` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_LAYOUT_MANAGER: UInt8 = 34
"""The `Json UI Layout Manager` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_LAYOUT_MANAGER_REMOVE_DEPENDENCIES: UInt8 = 35
"""The `Json UI Layout Manager Remove Dependencies` memory category."""
comptime MEMORY_CATEGORY_JSON_UI_LAYOUT_MANAGER_INIT_VARIABLE: UInt8 = 36
"""The `Json UI Layout Manager Init Variable` memory category."""
comptime MEMORY_CATEGORY_LANGUAGES: UInt8 = 37
"""The `Languages` memory category."""
comptime MEMORY_CATEGORY_LEVEL: UInt8 = 38
"""The `Level` memory category."""
comptime MEMORY_CATEGORY_LEVEL_STRUCTURES: UInt8 = 39
"""The `Level Structures` memory category."""
comptime MEMORY_CATEGORY_LEVEL_CHUNK: UInt8 = 40
"""The `Level Chunk` memory category."""
comptime MEMORY_CATEGORY_LEVEL_CHUNK_GEN: UInt8 = 41
"""The `Level Chunk Gen` memory category."""
comptime MEMORY_CATEGORY_LEVEL_CHUNK_GEN_THREAD_LOCAL: UInt8 = 42
"""The `Level Chunk Gen Thread Local` memory category."""
comptime MEMORY_CATEGORY_LIGHT_VOLUME_MANAGER: UInt8 = 43
"""The `Light Volume Manager` memory category."""
comptime MEMORY_CATEGORY_NETWORK: UInt8 = 44
"""The `Network` memory category."""
comptime MEMORY_CATEGORY_MARKETPLACE: UInt8 = 45
"""The `Marketplace` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_DRAGON_COMPILED_DEFINITION: UInt8 = 46
"""The `Material Dragon Compiled Definition` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_DRAGON_MATERIAL: UInt8 = 47
"""The `Material Dragon Material` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_DRAGON_RESOURCE: UInt8 = 48
"""The `Material Dragon Resource` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_DRAGON_UNIFORM_MAP: UInt8 = 49
"""The `Material Dragon Uniform Map` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_RENDER_MATERIAL: UInt8 = 50
"""The `Material Render Material` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_RENDER_MATERIAL_GROUP: UInt8 = 51
"""The `Material Render Material Group` memory category."""
comptime MEMORY_CATEGORY_MATERIAL_VARIATION_MANAGER: UInt8 = 52
"""The `Material Variation Manager` memory category."""
comptime MEMORY_CATEGORY_MOLANG: UInt8 = 53
"""The `Molang` memory category."""
comptime MEMORY_CATEGORY_ORE_UI: UInt8 = 54
"""The `Ore UI` memory category."""
comptime MEMORY_CATEGORY_ORE_UI_CLIENT: UInt8 = 55
"""The `Ore UI Client` memory category."""
comptime MEMORY_CATEGORY_PERSONA_PIECES: UInt8 = 56
"""The `Persona Pieces` memory category."""
comptime MEMORY_CATEGORY_PERSONA_ANIMATIONS: UInt8 = 57
"""The `Persona Animations` memory category."""
comptime MEMORY_CATEGORY_PERSONA_CHARACTERS: UInt8 = 58
"""The `Persona Characters` memory category."""
comptime MEMORY_CATEGORY_PERSONA_SKIN_PACKS: UInt8 = 59
"""The `Persona Skin Packs` memory category."""
comptime MEMORY_CATEGORY_PERSONA_REPO: UInt8 = 60
"""The `Persona Repo` memory category."""
comptime MEMORY_CATEGORY_PLAYER: UInt8 = 61
"""The `Player` memory category."""
comptime MEMORY_CATEGORY_RENDER_CHUNK: UInt8 = 62
"""The `Render Chunk` memory category."""
comptime MEMORY_CATEGORY_RENDER_CHUNK_INDEX_BUFFER: UInt8 = 63
"""The `Render Chunk Index Buffer` memory category."""
comptime MEMORY_CATEGORY_RENDER_CHUNK_VERTEX_BUFFER: UInt8 = 64
"""The `Render Chunk Vertex Buffer` memory category."""
comptime MEMORY_CATEGORY_RENDERING: UInt8 = 65
"""The `Rendering` memory category."""
comptime MEMORY_CATEGORY_RENDERING_BGFX_INIT: UInt8 = 66
"""The `Rendering BGFX Init` memory category."""
comptime MEMORY_CATEGORY_RENDERING_BGFX_START_FRAME: UInt8 = 67
"""The `Rendering BGFX Start Frame` memory category."""
comptime MEMORY_CATEGORY_RENDERING_BLOCK_TESSELLATOR: UInt8 = 68
"""The `Rendering Block Tessellator` memory category."""
comptime MEMORY_CATEGORY_RENDERING_END_FRAME: UInt8 = 69
"""The `Rendering End Frame` memory category."""
comptime MEMORY_CATEGORY_RENDERING_GRAPHICS_TASKS_INIT: UInt8 = 70
"""The `Rendering Graphics Tasks Init` memory category."""
comptime MEMORY_CATEGORY_RENDERING_LIBRARY: UInt8 = 71
"""The `Rendering Library` memory category."""
comptime MEMORY_CATEGORY_RENDERING_POLYGON_OPERATOR_POOL: UInt8 = 72
"""The `Rendering Polygon Operator Pool` memory category."""
comptime MEMORY_CATEGORY_RENDERING_PBR_TEXTURE_DATA: UInt8 = 73
"""The `Rendering PBR Texture Data` memory category."""
comptime MEMORY_CATEGORY_RENDERING_RENDER_REGISTRY: UInt8 = 74
"""The `Rendering Render Registry` memory category."""
comptime MEMORY_CATEGORY_RENDERING_SETUP: UInt8 = 75
"""The `Rendering Setup` memory category."""
comptime MEMORY_CATEGORY_RENDERING_VERTICES: UInt8 = 76
"""The `Rendering Vertices` memory category."""
comptime MEMORY_CATEGORY_REQUEST_LOG: UInt8 = 77
"""The `Request Log` memory category."""
comptime MEMORY_CATEGORY_RESOURCE_PACKS: UInt8 = 78
"""The `Resource Packs` memory category."""
comptime MEMORY_CATEGORY_SOUND: UInt8 = 79
"""The `Sound` memory category."""
comptime MEMORY_CATEGORY_SUB_CHUNK_BIOME_DATA: UInt8 = 80
"""The `Sub Chunk Biome Data` memory category."""
comptime MEMORY_CATEGORY_SUB_CHUNK_BLOCK_DATA: UInt8 = 81
"""The `Sub Chunk Block Data` memory category."""
comptime MEMORY_CATEGORY_SUB_CHUNK_LIGHT_DATA: UInt8 = 82
"""The `Sub Chunk Light Data` memory category."""
comptime MEMORY_CATEGORY_TEXTURES: UInt8 = 83
"""The `Textures` memory category."""
comptime MEMORY_CATEGORY_WEATHER_RENDERER: UInt8 = 84
"""The `Weather Renderer` memory category."""
comptime MEMORY_CATEGORY_WORLD_GENERATOR: UInt8 = 85
"""The `World Generator` memory category."""
comptime MEMORY_CATEGORY_TASKS: UInt8 = 86
"""The `Tasks` memory category."""
comptime MEMORY_CATEGORY_TEST: UInt8 = 87
"""The `Test` memory category."""
comptime MEMORY_CATEGORY_TEST_LOAD_TEST_TAGS: UInt8 = 88
"""The `Test Load Test Tags` memory category."""
comptime MEMORY_CATEGORY_SCRIPTING: UInt8 = 89
"""The `Scripting` memory category."""
comptime MEMORY_CATEGORY_SCRIPTING_RUNTIME: UInt8 = 90
"""The `Scripting Runtime` memory category."""
comptime MEMORY_CATEGORY_SCRIPTING_CONTEXT: UInt8 = 91
"""The `Scripting Context` memory category."""
comptime MEMORY_CATEGORY_SCRIPTING_CONTEXT_BINDINGS_MC: UInt8 = 92
"""The `Scripting Context Bindings MC` memory category."""
comptime MEMORY_CATEGORY_SCRIPTING_CONTEXT_BINDINGS_GT: UInt8 = 93
"""The `Scripting Context Bindings GT` memory category."""
comptime MEMORY_CATEGORY_SCRIPTING_CONTEXT_RUN: UInt8 = 94
"""The `Scripting Context Run` memory category."""
comptime MEMORY_CATEGORY_DATA_DRIVEN_UI: UInt8 = 95
"""The `Data Driven UI` memory category."""
comptime MEMORY_CATEGORY_DATA_DRIVEN_UI_DEFS: UInt8 = 96
"""The `Data Driven UI Defs` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE: UInt8 = 97
"""The `Gameface` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_SYSTEM: UInt8 = 98
"""The `Gameface System` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_DOM: UInt8 = 99
"""The `Gameface DOM` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_CSS: UInt8 = 100
"""The `Gameface CSS` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_DISPLAY: UInt8 = 101
"""The `Gameface Display` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_TEMP_ALLOCATOR: UInt8 = 102
"""The `Gameface Temp Allocator` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_POOL_ALLOCATOR: UInt8 = 103
"""The `Gameface Pool Allocator` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_DUMP: UInt8 = 104
"""The `Gameface Dump` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_MEDIA: UInt8 = 105
"""The `Gameface Media` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_JSON: UInt8 = 106
"""The `Gameface JSON` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_SCRIPT_ENGINE: UInt8 = 107
"""The `Gameface Script Engine` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_SCRIPT: UInt8 = 108
"""The `Gameface Script` memory category."""
comptime MEMORY_CATEGORY_GAMEFACE_LAYOUT: UInt8 = 109
"""The `Gameface Layout` memory category."""
comptime MEMORY_CATEGORY_EXECUTABLE: UInt8 = 110
"""The `Executable` memory category."""


struct MemoryCategoryCounter(Marshaler):
    """The memory used by one category."""

    var category: UInt8
    """One of the `MEMORY_CATEGORY_*` values."""
    var bytes: UInt64
    """The number of bytes used."""

    def __init__(out self):
        """Creates a zero value."""
        self.category = 0
        self.bytes = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.uint8(self.category)
        io.uint64(self.bytes)


struct EntityDiagnosticTimingInfo(Marshaler):
    """Timing diagnostics for one entity type."""

    var display_name: String
    """The name shown for this entry."""
    var entity: String
    """The identifier of the timed entity."""
    var duration_nanos: UInt64
    """How long the entry lasted, in nanoseconds."""
    var percent_of_total: UInt8
    """The share of the total time, in percent."""
    var position: Optional[Vec3]
    """The entity's position, if known."""
    var dimension: Optional[String]
    """The entity's dimension name, if known."""

    def __init__(out self):
        """Creates a zero value."""
        self.display_name = String()
        self.entity = String()
        self.duration_nanos = 0
        self.percent_of_total = 0
        self.position = None
        self.dimension = None

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.display_name)
        io.string(self.entity)
        io.uint64(self.duration_nanos)
        io.uint8(self.percent_of_total)
        optional_vec3(io, self.position)
        optional_string(io, self.dimension)


struct SystemDiagnosticTimingInfo(Marshaler):
    """Timing diagnostics for one system index."""

    var display_name: String
    """The name shown for this entry."""
    var system_index: UInt64
    """The index of the timed system."""
    var duration_nanos: UInt64
    """How long the entry lasted, in nanoseconds."""
    var percent_of_total: UInt8
    """The share of the total time, in percent."""

    def __init__(out self):
        """Creates a zero value."""
        self.display_name = String()
        self.system_index = 0
        self.duration_nanos = 0
        self.percent_of_total = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.display_name)
        io.uint64(self.system_index)
        io.uint64(self.duration_nanos)
        io.uint8(self.percent_of_total)


struct SystemCategory(Marshaler):
    """Maps a diagnostics category name to a system index."""

    var category_name: String
    """The category name."""
    var system_index: UInt64
    """The system index."""

    def __init__(out self):
        """Creates a zero value."""
        self.category_name = String()
        self.system_index = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.category_name)
        io.uint64(self.system_index)


struct WhiskerScopeDataSummary(Marshaler):
    """A summary of one whisker profiler scope."""

    var label: String
    """The scope's label."""
    var indentation: String
    """The scope's indentation in the profiler hierarchy."""
    var total_high_cost_ns: UInt64
    """Nanoseconds spent in the high-cost part."""
    var total_mid_cost_ns: UInt64
    """Nanoseconds spent in the mid-cost part."""
    var total_low_cost_ns: UInt64
    """Nanoseconds spent in the low-cost part."""

    def __init__(out self):
        """Creates a zero value."""
        self.label = String()
        self.indentation = String()
        self.total_high_cost_ns = 0
        self.total_mid_cost_ns = 0
        self.total_low_cost_ns = 0

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.label)
        io.string(self.indentation)
        io.uint64(self.total_high_cost_ns)
        io.uint64(self.total_mid_cost_ns)
        io.uint64(self.total_low_cost_ns)
