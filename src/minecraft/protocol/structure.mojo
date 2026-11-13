"""Structure block settings (gophertunnel `protocol/structure.go`)."""

from .block_pos import BlockPos
from .io import IO, Marshaler, actor_unique_id, block_pos, vec3
from .math import Vec3

comptime STRUCTURE_MIRROR_NONE: UInt8 = 0
"""Mirror the structure: None."""
comptime STRUCTURE_MIRROR_X_AXIS: UInt8 = 1
"""Mirror the structure: X Axis."""
comptime STRUCTURE_MIRROR_Z_AXIS: UInt8 = 2
"""Mirror the structure: Z Axis."""
comptime STRUCTURE_MIRROR_BOTH_AXES: UInt8 = 3
"""Mirror the structure: Both Axes."""


comptime STRUCTURE_ROTATION_NONE: UInt8 = 0
"""Rotate the structure: None."""
comptime STRUCTURE_ROTATION_ROTATE90: UInt8 = 1
"""Rotate the structure: Rotate90."""
comptime STRUCTURE_ROTATION_ROTATE180: UInt8 = 2
"""Rotate the structure: Rotate180."""
comptime STRUCTURE_ROTATION_ROTATE270: UInt8 = 3
"""Rotate the structure: Rotate270."""


comptime ANIMATION_MODE_NONE: UInt8 = 0
"""Structure animation mode: None."""
comptime ANIMATION_MODE_LAYERS: UInt8 = 1
"""Structure animation mode: Layers."""
comptime ANIMATION_MODE_BLOCKS: UInt8 = 2
"""Structure animation mode: Blocks."""


struct StructureSettings(Marshaler):
    """The settings of a structure block, editable in its UI."""

    var palette_name: String
    """The palette used; currently always `default`."""
    var ignore_entities: Bool
    """Whether entities are left out of the structure."""
    var ignore_blocks: Bool
    """Whether blocks are left out of the structure."""
    var allow_non_ticking_chunks: Bool
    """Whether non-ticking chunks are allowed."""
    var size: BlockPos
    """The size of the exported area."""
    var offset: BlockPos
    """The offset of the exported area from the block."""
    var last_editing_player_unique_id: Int64
    """The player that last edited the block."""
    var rotation: UInt8
    """One of the `STRUCTURE_ROTATION_*` values."""
    var mirror: UInt8
    """One of the `STRUCTURE_MIRROR_*` values."""
    var animation_mode: UInt8
    """One of the `ANIMATION_MODE_*` values."""
    var animation_duration: Float32
    """The duration of the animation."""
    var integrity: Float32
    """1, or less to omit blocks randomly using `seed`."""
    var seed: UInt32
    """The seed for omitting blocks; 0 picks a random one."""
    var pivot: Vec3
    """The pivot the structure rotates around."""

    def __init__(out self):
        """Creates zero settings."""
        self.palette_name = String()
        self.ignore_entities = False
        self.ignore_blocks = False
        self.allow_non_ticking_chunks = False
        self.size = BlockPos()
        self.offset = BlockPos()
        self.last_editing_player_unique_id = 0
        self.rotation = 0
        self.mirror = 0
        self.animation_mode = 0
        self.animation_duration = 0
        self.integrity = 0
        self.seed = 0
        self.pivot = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the settings.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.string(self.palette_name)
        io.bool(self.ignore_entities)
        io.bool(self.ignore_blocks)
        io.bool(self.allow_non_ticking_chunks)
        block_pos(io, self.size)
        block_pos(io, self.offset)
        actor_unique_id(io, self.last_editing_player_unique_id)
        io.uint8(self.rotation)
        io.uint8(self.mirror)
        io.uint8(self.animation_mode)
        io.float32(self.animation_duration)
        io.float32(self.integrity)
        io.uint32(self.seed)
        vec3(io, self.pivot)
