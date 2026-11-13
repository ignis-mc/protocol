"""The Xbox Live-signed Minecraft login chain.

Port of gophertunnel `minecraft/auth/minecraft.go`
(`RequestMinecraftChain`). The request is authorized with the XSTS token for
the relying party NSAL assigns to `multiplayer.minecraft.net` and, like the
vanilla client, carries no `Signature` header.
"""

from ..protocol.info import CURRENT_VERSION
from ..protocol.login.request import marshal_public_key
from .json import go_quote
from .transport import Request, Response, status_error

comptime MINECRAFT_AUTH_URL = "https://multiplayer.minecraft.net/authentication"
"""Where the chain is requested."""


def minecraft_chain_request(
    private_key: Span[UInt8, _], authorization: String
) raises -> Request:
    """Builds the chain request.

    Args:
        private_key: The client's 48-byte P-384 private scalar; the chain
            certifies its public key.
        authorization: The `XBL3.0 x=…` header of the XSTS token.

    Returns:
        The `POST multiplayer.minecraft.net/authentication` request.

    Raises:
        Error: If the private key is invalid.
    """
    var body = String(
        '{"identityPublicKey":', go_quote(marshal_public_key(private_key)), "}"
    )
    var headers = List[Tuple[String, String]]()
    headers.append(("User-Agent", "MCPE/Android"))
    headers.append(("Client-Version", String(CURRENT_VERSION)))
    headers.append(("Content-Type", "application/json"))
    headers.append(("Authorization", authorization))
    return Request(
        "POST", MINECRAFT_AUTH_URL, headers^, List[UInt8](body.as_bytes())
    )


def parse_minecraft_chain_response(
    request: Request, response: Response
) raises -> String:
    """Returns the chain JSON (`{"chain":[…]}`) from a 200 response.

    Args:
        request: The request that was sent.
        response: Its response.

    Returns:
        The response body as text.

    Raises:
        Error: On a non-200 status or a body that is not UTF-8.
    """
    if response.status != 200:
        raise status_error(request, response)
    return String(from_utf8=Span(response.body))
