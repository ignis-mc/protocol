"""Device operating systems (gophertunnel `protocol/os.go`)."""


comptime DeviceOS = Int
"""A device or build platform, one of the `DEVICE_*` values."""

comptime DEVICE_UNKNOWN: DeviceOS = -1
"""The fallback platform, when it is none of the known values."""


comptime DEVICE_ANDROID: DeviceOS = 1
"""The Android platform."""
comptime DEVICE_IOS: DeviceOS = 2
"""The IOS platform."""
comptime DEVICE_OSX: DeviceOS = 3
"""The OSX platform."""
comptime DEVICE_FIRE_OS: DeviceOS = 4
"""The Fire OS platform."""
comptime DEVICE_GEAR_VR: DeviceOS = 5
"""The Gear VR platform (deprecated as of 1.21.50)."""
comptime DEVICE_HOLOLENS: DeviceOS = 6
"""The Hololens platform."""
comptime DEVICE_WIN10: DeviceOS = 7
"""The Win10 platform."""
comptime DEVICE_WIN32: DeviceOS = 8
"""The Win32 platform."""
comptime DEVICE_DEDICATED: DeviceOS = 9
"""The Dedicated platform."""
comptime DEVICE_TVOS: DeviceOS = 10
"""The TVOS platform (deprecated as of 1.20.10)."""
comptime DEVICE_ORBIS: DeviceOS = 11
"""The Orbis platform (PlayStation)."""
comptime DEVICE_NX: DeviceOS = 12
"""The NX platform."""
comptime DEVICE_XBOX: DeviceOS = 13
"""The XBOX platform."""
comptime DEVICE_WP: DeviceOS = 14
"""The Windows Phone platform (deprecated as of 1.20.10)."""
comptime DEVICE_LINUX: DeviceOS = 15
"""The Linux platform."""
