"""Graphics parameter overrides (gophertunnel `protocol/graphics.go`)."""

from .io import IO, Marshaler, vec3
from .math import Vec3

comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SKY_ZENITH_COLOR: UInt8 = 0
"""Overrides the `Sky Zenith Color` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SKY_HORIZON_COLOR: UInt8 = 1
"""Overrides the `Sky Horizon Color` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HORIZON_BLEND_MIN: UInt8 = 2
"""Overrides the `Horizon Blend Min` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HORIZON_BLEND_MAX: UInt8 = 3
"""Overrides the `Horizon Blend Max` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HORIZON_BLEND_START: UInt8 = 4
"""Overrides the `Horizon Blend Start` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HORIZON_BLEND_MIE_START: UInt8 = 5
"""Overrides the `Horizon Blend Mie Start` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_RAYLEIGH_STRENGTH: UInt8 = 6
"""Overrides the `Rayleigh Strength` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SUN_MIE_STRENGTH: UInt8 = 7
"""Overrides the `Sun Mie Strength` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MOON_MIE_STRENGTH: UInt8 = 8
"""Overrides the `Moon Mie Strength` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SUN_GLARE_SHAPE: UInt8 = 9
"""Overrides the `Sun Glare Shape` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_CHLOROPHYLL: UInt8 = 10
"""Overrides the `Chlorophyll` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_CDOM: UInt8 = 11
"""Overrides the `CDOM` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SUSPENDED_SEDIMENT: UInt8 = 12
"""Overrides the `Suspended Sediment` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_DEPTH: UInt8 = 13
"""Overrides the `Waves Depth` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_FREQUENCY: UInt8 = 14
"""Overrides the `Waves Frequency` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_FREQUENCY_SCALING: UInt8 = 15
"""Overrides the `Waves Frequency Scaling` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_SPEED: UInt8 = 16
"""Overrides the `Waves Speed` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_SPEED_SCALING: UInt8 = 17
"""Overrides the `Waves Speed Scaling` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_SHAPE: UInt8 = 18
"""Overrides the `Waves Shape` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_OCTAVES: UInt8 = 19
"""Overrides the `Waves Octaves` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_MIX: UInt8 = 20
"""Overrides the `Waves Mix` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_PULL: UInt8 = 21
"""Overrides the `Waves Pull` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_WAVES_DIRECTION_INCREMENT: UInt8 = 22
"""Overrides the `Waves Direction Increment` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MIDTONES_CONTRAST: UInt8 = 23
"""Overrides the `Midtones Contrast` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HIGHLIGHTS_CONTRAST: UInt8 = 24
"""Overrides the `Highlights Contrast` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SHADOWS_CONTRAST: UInt8 = 25
"""Overrides the `Shadows Contrast` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HIGHLIGHTS_GAIN: UInt8 = 26
"""Overrides the `Highlights Gain` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HIGHLIGHTS_GAMMA: UInt8 = 27
"""Overrides the `Highlights Gamma` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HIGHLIGHTS_OFFSET: UInt8 = 28
"""Overrides the `Highlights Offset` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HIGHLIGHTS_SATURATION: UInt8 = 29
"""Overrides the `Highlights Saturation` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MIDTONES_GAIN: UInt8 = 30
"""Overrides the `Midtones Gain` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MIDTONES_GAMMA: UInt8 = 31
"""Overrides the `Midtones Gamma` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MIDTONES_OFFSET: UInt8 = 32
"""Overrides the `Midtones Offset` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MIDTONES_SATURATION: UInt8 = 33
"""Overrides the `Midtones Saturation` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SHADOWS_GAIN: UInt8 = 34
"""Overrides the `Shadows Gain` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SHADOWS_GAMMA: UInt8 = 35
"""Overrides the `Shadows Gamma` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SHADOWS_OFFSET: UInt8 = 36
"""Overrides the `Shadows Offset` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SHADOWS_SATURATION: UInt8 = 37
"""Overrides the `Shadows Saturation` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_HIGHLIGHTS_MIN: UInt8 = 38
"""Overrides the `Highlights Min` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SHADOWS_MAX: UInt8 = 39
"""Overrides the `Shadows Max` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_TEMPERATURE: UInt8 = 40
"""Overrides the `Temperature` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SUN_COLOR: UInt8 = 41
"""Overrides the `Sun Color` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SUN_ILLUMINANCE: UInt8 = 42
"""Overrides the `Sun Illuminance` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MOON_COLOR: UInt8 = 43
"""Overrides the `Moon Color` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_MOON_ILLUMINANCE: UInt8 = 44
"""Overrides the `Moon Illuminance` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_FLASH_COLOR: UInt8 = 45
"""Overrides the `Flash Color` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_FLASH_ILLUMINANCE: UInt8 = 46
"""Overrides the `Flash Illuminance` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_AMBIENT_COLOR: UInt8 = 47
"""Overrides the `Ambient Color` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_AMBIENT_ILLUMINANCE: UInt8 = 48
"""Overrides the `Ambient Illuminance` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_EMISSIVE_DESATURATION: UInt8 = 49
"""Overrides the `Emissive Desaturation` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_SKY_INTENSITY: UInt8 = 50
"""Overrides the `Sky Intensity` graphics parameter."""
comptime GRAPHICS_OVERRIDE_PARAMETER_TYPE_ORBITAL_OFFSET_DEGREES: UInt8 = 51
"""Overrides the `Orbital Offset Degrees` graphics parameter."""


struct ParameterKeyframeValue(Marshaler):
    """A keyframe of a graphics parameter."""

    var time: Float32
    """The time of the keyframe."""
    var value: Vec3
    """The value at the keyframe."""

    def __init__(out self):
        """Creates a zero value."""
        self.time = 0
        self.value = Vec3()

    def marshal[I: IO](mut self, mut io: I) raises:
        """Reads or writes the value.

        Parameters:
            I: The reader or writer type.

        Args:
            io: The reader or writer.

        Raises:
            If the input is malformed or a value is invalid.
        """
        io.float32(self.time)
        vec3(io, self.value)
