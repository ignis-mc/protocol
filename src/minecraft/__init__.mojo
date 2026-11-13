"""The Minecraft: Bedrock Edition network protocol, ported from gophertunnel.

`minecraft.protocol` holds the wire types and the `IO` abstraction,
`minecraft.protocol.packet` the packets and batch framing,
`minecraft.protocol.login` the login request, and the top-level modules the
`Dialer` and `Conn` that run a client connection over NetherNet.
"""
