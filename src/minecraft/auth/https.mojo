"""The real transport: HTTPS over the pure-Mojo TLS 1.3 client.

Adapts `http.client.HttpClient` (one TLS connection per request,
`Connection: close`, servers verified against the system CA bundle) to the
sign-in flow's `Transport` trait. Requests without a `User-Agent` get the
HTTP client's default instead of Go's `Go-http-client/1.1`; every other
header is sent as built.
"""

from http.client import HttpClient

from .transport import Request, Response, Transport


struct HttpsTransport(Movable, Transport):
    """Performs the sign-in exchanges over HTTPS."""

    var client: HttpClient
    """The HTTPS client."""
    var timeout_ms: Int
    """The limit for each exchange."""

    def __init__(out self, var client: HttpClient, timeout_ms: Int = 30000):
        """Wraps an HTTPS client.

        Args:
            client: The client.
            timeout_ms: The limit for each exchange.
        """
        self.client = client^
        self.timeout_ms = timeout_ms

    @staticmethod
    def system() raises -> HttpsTransport:
        """Creates a transport that trusts the system CA bundle.

        Returns:
            The transport.

        Raises:
            Error: If the CA bundle cannot be read.
        """
        return HttpsTransport(HttpClient.system())

    def round_trip(mut self, request: Request) raises -> Response:
        """Sends a request and returns the response.

        Args:
            request: The request.

        Returns:
            The response, whatever its status.

        Raises:
            Error: On connection, TLS, verification or framing failures.
        """
        var r = self.client.request(
            request.method,
            request.url,
            request.headers,
            Span(request.body),
            self.timeout_ms,
        )
        return Response(r.status, r.headers.copy(), r.body.copy())
