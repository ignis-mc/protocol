"""Builds small resource pack archives for tests."""

from minecraft.internal.zip import METHOD_DEFLATE, METHOD_STORE, ZipWriter


def manifest_json(
    uuid: StringSpan, version: StringSpan, name: StringSpan
) -> String:
    """Returns a manifest with one `resources` module.

    Args:
        uuid: The header UUID.
        version: The version as a JSON value, e.g. `[1, 0, 0]`.
        name: The pack name.

    Returns:
        The manifest text.
    """
    return (
        String('{"format_version": 2, "header": {"name": "')
        + name
        + '", "description": "test pack", "uuid": "'
        + uuid
        + '", "version": '
        + version
        + ', "min_engine_version": [1, 20, 0]}, "modules": [{"type":'
        + ' "resources", "uuid": "11111111-2222-3333-4444-555555555555",'
        + ' "version": [1, 0, 0]}]}'
    )


def build_pack(
    uuid: StringSpan, version: StringSpan, name: StringSpan, filler: Int = 0
) raises -> List[UInt8]:
    """Builds a pack archive: a deflated manifest and a stored filler file.

    Args:
        uuid: The header UUID.
        version: The version as a JSON value.
        name: The pack name.
        filler: Bytes of pseudo-random data to add, to make the pack big.

    Returns:
        The zip archive.
    """
    var w = ZipWriter()
    var manifest = manifest_json(uuid, version, name)
    w.add("pack/manifest.json", manifest.as_bytes(), METHOD_DEFLATE)
    var data = List[UInt8](capacity=filler)
    var x = UInt32(0x12345678)
    for _ in range(filler):
        x ^= x << 13
        x ^= x >> 17
        x ^= x << 5
        data.append(UInt8(x & 0xFF))
    w.add("pack/textures/filler.bin", Span(data), METHOD_STORE)
    return w^.finish()
