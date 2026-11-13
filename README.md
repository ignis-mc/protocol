# protocol

The Minecraft: Bedrock Edition network protocol in pure Mojo, ported from
[gophertunnel](https://github.com/Sandertv/gophertunnel) v1.63.0
(protocol 2225, game version 1.26.60).

- `minecraft.protocol`: the protocol types and the `IO` reader/writer.
- `minecraft.protocol.packet`: every packet, the packet header and the batch
  codec (flate, snappy or none).
- `minecraft.protocol.login`: login request encoding and client data.
- `minecraft.nbt`: NBT in the network and storage encodings.
- `minecraft`: a client `Dialer` and `Conn`.

The transport is [NetherNet](https://github.com/ignis-mc/nethernet), included
as the `third_party/nethernet` submodule. RakNet is deliberately not
supported.

## Use

```sh
git clone --recursive https://github.com/ignis-mc/protocol
pixi run test
```

Compile programs with both source roots:
`mojo run -I src -I third_party/nethernet/src your_program.mojo`.

## Development

See [AGENTS.md](AGENTS.md) for the porting conventions and quality bar.

## License

MIT. gophertunnel is © Sandertv and contributors, also under the MIT license.
