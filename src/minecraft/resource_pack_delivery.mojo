"""How a listener sends resource pack data (gophertunnel
`resource_pack_delivery.go`)."""

comptime DEFAULT_RESOURCE_PACK_CHUNK_SIZE: UInt32 = 1024 * 128
"""The chunk size used when `ResourcePackDeliveryConfig.chunk_size` is 0."""
comptime DEFAULT_RESOURCE_PACK_CHUNK_SEND_DELAY_MS = 200
"""The pause after each chunk when `chunk_send_delay_ms` is 0."""


struct ResourcePackDeliveryConfig(Copyable, Defaultable):
    """Chunk size and pacing of resource pack downloads served to clients."""

    var chunk_size: UInt32
    """The bytes per `ResourcePackChunkData`; 0 uses the default."""
    var chunk_send_delay_ms: Int
    """The pause after each chunk before the next request is handled; 0
    uses the default and a negative value disables it."""

    def __init__(out self):
        """Creates a config that uses the defaults."""
        self.chunk_size = 0
        self.chunk_send_delay_ms = 0

    def normalized(self) -> ResourcePackDeliveryConfig:
        """Replaces zero values with the defaults."""
        var c = ResourcePackDeliveryConfig()
        c.chunk_size = self.chunk_size
        c.chunk_send_delay_ms = self.chunk_send_delay_ms
        if c.chunk_size == 0:
            c.chunk_size = DEFAULT_RESOURCE_PACK_CHUNK_SIZE
        if c.chunk_send_delay_ms == 0:
            c.chunk_send_delay_ms = DEFAULT_RESOURCE_PACK_CHUNK_SEND_DELAY_MS
        elif c.chunk_send_delay_ms < 0:
            c.chunk_send_delay_ms = 0
        return c^
