"""Colours (gophertunnel uses `image/color.RGBA`)."""


@fieldwise_init
struct RGBA(Defaultable, Equatable, ImplicitlyCopyable):
    """An 8-bit-per-channel colour."""

    var r: UInt8
    """Red."""
    var g: UInt8
    """Green."""
    var b: UInt8
    """Blue."""
    var a: UInt8
    """Alpha."""

    def __init__(out self):
        """Creates transparent black."""
        self.r = 0
        self.g = 0
        self.b = 0
        self.a = 0
