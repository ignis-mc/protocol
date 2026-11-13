# Agent guide for `protocol`

`protocol` is a pure-Mojo port of
[gophertunnel](https://github.com/Sandertv/gophertunnel) v1.63.0 (protocol
2225, Minecraft 1.26.60): the packet codec, login encoding, NBT, batch
compression and a client `Dialer`. The transport is NetherNet, from the
`nethernet` submodule in `third_party/nethernet`. **There is no RakNet and
there never will be.** Do not port `go-raknet` or anything that frames packets
with a `0xfe` prefix or encrypts batches.

This file is the single source of truth for coding agents. `CLAUDE.md` only
points here.

## Toolchain

- Mojo is pinned to **1.2.x** (`pixi.toml`). Run everything through
  `pixi run <task>`, or put a Mojo 1.2 `mojo` on `PATH`.
- Every compile needs both include roots:
  `mojo run -I src -I third_party/nethernet/src -D ASSERT=all test/minecraft/protocol/test_io.mojo`.
  The test binary accepts `--only <names…>`, `--skip <names…>`.
- Tasks: `pixi run test`, `format`, `format-check`, `lint-docs`, `build`,
  `check`, and `pixi run -e interop interop` (Dragonfly join, needs Go 1.26).
- After every edit, compile and run the affected test file. Do not report a
  change as working without that output.
- Go reference source is in the module cache:
  `~/go/pkg/mod/github.com/sandertv/gophertunnel@v1.63.0/minecraft/`.

## Mojo rules

Follow the "Mojo 1.2 rules" and "Idioms" sections of
`third_party/nethernet/AGENTS.md`; they apply here unchanged (`def` only,
`comptime`, `std.` imports, `.copy()` / `^`, no globals, no async, network
bytes never in `String(unsafe_from_utf8=)`, keep moved structs small). Load
the `mojo-syntax` skill before writing Mojo; the compiler wins where they
disagree. Things specific to this repo:

- Struct fields cannot have default values: every type writes an explicit
  `def __init__(out self)` that zeroes all fields (this is the Go zero value).
- A struct cannot contain `List[Self]` or `Optional[Self]`. Recursive Go
  types need another shape (indices into a flat list, or raw bytes as `NBT`
  does).
- The protocol `Writer` struct shadows the stdlib `Writer` trait used by
  `write_to(self, mut writer: Some[Writer])`. In a module that needs both,
  import it as `from ..writer import Writer as ProtocolWriter`.
- Generic code over `Marshaler` values needs the trait's `Deinitable` bound;
  it is already in `Marshaler`.

## Porting conventions

The goal is that a reader can put a Go file and its Mojo port side by side.

- **One Mojo file per Go file**, same base name:
  `protocol/item_stack.go` → `src/minecraft/protocol/item_stack.mojo`,
  `protocol/packet/start_game.go` → `src/minecraft/protocol/packet/start_game.mojo`.
  Each module has a test file at the mirrored path under `test/`.
- **Names**: Go type names unchanged (`ItemStack`, `StartGame`); fields and
  functions in `snake_case` (`EntityRuntimeID` → `entity_runtime_id`,
  `XUID` → `xuid`); constants in `SCREAMING_SNAKE_CASE` with the Go prefix
  kept (`PlayStatusLoginSuccess` → `PLAY_STATUS_LOGIN_SUCCESS`,
  `IDStartGame` → `ID_START_GAME`). Keep field order identical to Go.
- **Types**:

  | Go | Mojo |
  | --- | --- |
  | `bool`, `uint8`…`int64`, `float32/64` | `Bool`, `UInt8`…`Int64`, `Float32/64` |
  | `string` | `String` |
  | `[]byte` | `List[UInt8]` |
  | `[]T` | `List[T]` |
  | `[N]T` | `InlineArray[T, N]` or `List[T]` |
  | `protocol.Optional[T]` | `Optional[T]` |
  | `mgl32.Vec2/Vec3` | `Vec2`, `Vec3` (`protocol/math.mojo`) |
  | `BlockPos`, `ChunkPos`, `SubChunkPos` | same names (`protocol/block_pos.mojo`) |
  | `uuid.UUID` | `UUID` (`protocol/uuid.mojo`) |
  | `color.RGBA` | `RGBA` (`protocol/color.mojo`) |
  | `map[string]any` NBT field | `NBT` (`minecraft/nbt/nbt.mojo`) |
  | an interface with N implementations | `Variant[A, B, …]` (`std.utils`) of the concrete structs, dispatched on the wire type ID |
  | `map[K]V` | `List` of `(K, V)` structs in wire order |

- **Marshalers**: every Go type with `Marshal(r IO)` becomes a struct that
  implements `Marshaler` (`protocol/io.mojo`):

  ```mojo
  struct ItemEntry(Marshaler):
      var name: String
      var runtime_id: Int16
      def __init__(out self):
          self.name = String()
          self.runtime_id = 0
      def marshal[I: IO](mut self, mut io: I) raises:
          io.string(self.name)
          io.int16(self.runtime_id)
  ```

  The same `marshal` reads (`Reader`) and writes (`Writer`); branch on
  `io.reads()` only where Go branches on the concrete IO type.
- **Packets** additionally implement `Packet` with `comptime ID: UInt32`
  from `packet/id.mojo`. See `packet/text.mojo` and `packet/disconnect.mojo`
  for the reference shape, and `test/minecraft/protocol/packet/test_login_packets.mojo`
  for the test shape (byte-exact encodings plus round trips).
- **Go `IO` methods** map as follows. Methods on the Go interface that take
  only a primitive are methods on the Mojo `IO` trait (`io.varint32(x)`,
  `io.string(x)`, `io.byte_slice(x)`). Every other Go `IO` method becomes a
  free function in `protocol/io.mojo` or in the module that owns the type:
  `r.Vec3(&x)` → `vec3(io, x)`, `r.UUID(&x)` → `uuid(io, x)`,
  `r.ItemInstance(&x)` → `item_instance(io, x)` in `item_stack.mojo`.
  Generic helpers: `slice(io, list)` (varuint32 count), `slice_uint8_length`,
  `slice_uint32_length`, `slice_of_len`, `optional_marshaler`,
  `string_slice`, the `*_slice` and `optional_*` primitive helpers.
  Add a helper to `io.mojo` rather than open-coding a loop when Go uses a
  generic `protocol.Slice`/`FuncSlice`/`OptionalFunc`.
- **NBT fields** use `nbt(io, self.x, NETWORK_LITTLE_ENDIAN)` (or the
  encoding Go passes). NBT is kept as raw bytes; `minecraft/nbt/` decodes
  it into a tree when a caller needs the values.
- **Errors**: Go's `r.UnknownEnumOption` / `r.InvalidValue` panics map to
  `unknown_enum_option(...)` / `invalid_value(...)`, which raise. Never
  abort on network input.
- **Limits**: keep every Go length limit (`r.SliceLimit`, `MaxSliceLength`
  checks) via `io.slice_length(n, max)`; the reader enforces them.
- Comments: keep Go's doc comments as docstrings, shortened. Every public
  symbol needs one (`pixi run lint-docs`). Module docstrings name the Go file.

## Architecture

```text
src/minecraft/
  protocol/          types and IO (protocol/*.go)
    io.mojo          IO trait, Marshaler, free IO helpers
    reader.mojo      Reader (bounds-checked, limits)
    writer.mojo      Writer
    packet/          one file per packet, id.mojo, packet.mojo, batch codec
    login/           ConnectionRequest encoding, IdentityData, ClientData
  nbt/               NBT walk/copy (nbt.mojo) and tree codec
  internal/          inflate/deflate and snappy
  conn.mojo, dial.mojo, game_data.mojo   the client connection over NetherNet
interop/             Go programs: Dragonfly server, gophertunnel bot, auth helper
```

- Packages depend downward: `protocol` → `packet` → `login` → `conn`.
  `protocol` and `nbt` never import `nethernet` or touch sockets.
- Inside `src/minecraft` import relatively; tests and examples import
  absolutely (`from minecraft.protocol.packet.text import Text`).

## Quality bar

- `pixi run format` before committing; never hand-format.
- Bug fixes come with a reproducing test.
- Never print, log or commit account tokens, refresh tokens or private keys.
  `.secrets/` is ignored; keep generated credentials there with mode 0600.
- Do not edit `third_party/nethernet` here; change nethernet in its own repo
  and bump the submodule.
- Do not commit agent notes or scratch files.
