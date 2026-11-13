"""PlayFab sign-in with an Xbox Live token.

Port of `go-playfab/v2` `LoginWithXbox` (`xbox.go`, `login.go`,
`internal/request.go`). The request carries the XSTS token for the relying
party NSAL assigns to `*.playfabapi.com` in its body; the session ticket in
the result authenticates the Minecraft services session.
"""

from .json import get_raw, go_quote, lookup, opt_int, opt_string, parse_object
from .transport import Request, Response, status_error


def playfab_url(title_id: String) -> String:
    """Returns a title's PlayFab API base URL (`title.Title.URL`).

    Args:
        title_id: The PlayFab title ID, e.g. `20CA2`.

    Returns:
        `https://<lowercase id>.playfabapi.com`.
    """
    return String("https://", title_id.lower(), ".playfabapi.com")


def login_with_xbox_url(title_id: String) -> String:
    """Returns the `LoginWithXbox` URL, used to resolve its relying party.

    Args:
        title_id: The PlayFab title ID.

    Returns:
        `https://<id>.playfabapi.com/Client/LoginWithXbox`.
    """
    return String(playfab_url(title_id), "/Client/LoginWithXbox")


def login_with_xbox_request(
    title_id: String, xbox_token: String, create_account: Bool
) -> Request:
    """Builds the `Client/LoginWithXbox` request.

    Args:
        title_id: The PlayFab title ID.
        xbox_token: The XSTS token as `XBL3.0 x=<uhs>;<token>`.
        create_account: Whether to create a PlayFab account if none exists.

    Returns:
        The request; the body is Go's `json.Encoder` output.
    """
    var body = String('{"TitleId":', go_quote(title_id))
    if create_account:
        body += ',"CreateAccount":true'
    body += String(',"XboxToken":', go_quote(xbox_token), "}\n")
    var headers = List[Tuple[String, String]]()
    headers.append(("Content-Type", "application/json"))
    return Request(
        "POST",
        login_with_xbox_url(title_id),
        headers^,
        List[UInt8](body.as_bytes()),
    )


@fieldwise_init
struct LoginResult(Copyable, Movable):
    """The parts of a PlayFab `LoginResult` the flow uses."""

    var session_ticket: String
    """The session ticket (a secret)."""
    var playfab_id: String
    """The PlayFab player ID."""
    var newly_created: Bool
    """Whether the account was created by this login."""


def parse_login_response(
    request: Request, response: Response
) raises -> LoginResult:
    """Decodes a `LoginWithXbox` response.

    Args:
        request: The request that was sent.
        response: Its response.

    Returns:
        The login result.

    Raises:
        Error: On a non-200 status (with PlayFab's error code and message)
            or a result without entity token, session ticket or player ID.
    """
    if response.status != 200:
        var detail = Optional[String](None)
        try:
            var obj = parse_object(Span(response.body))
            detail = String(
                "playfab: ",
                opt_int(obj, "errorCode"),
                " (",
                opt_string(obj, "error"),
                "): ",
                opt_string(obj, "errorMessage"),
            )
        except:
            pass
        if case .Some(msg) = detail:
            raise Error(msg)
        raise status_error(request, response)
    var data = parse_object(
        get_raw(parse_object(Span(response.body)), "data").as_bytes()
    )
    var newly = False
    if case .Some(v) = lookup(data, "NewlyCreated"):
        newly = v.strip() == "true"
    var result = LoginResult(
        opt_string(data, "SessionTicket"),
        opt_string(data, "PlayFabId"),
        newly,
    )
    if (
        not lookup(data, "EntityToken")
        or result.session_ticket.byte_length() == 0
        or result.playfab_id.byte_length() == 0
    ):
        raise Error("playfab: invalid *LoginResult result")
    return result^
