"""Simple TLS HTTP server for SNI passthrough integration tests."""

from __future__ import annotations

import os
import ssl
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    """Return a small text response to identify the backend."""

    def do_GET(self) -> None:  # noqa: N802
        """Handle GET requests."""
        body = (os.environ.get("RESPONSE_BODY", "OK") + "\n").encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, _format: str, *_args: object) -> None:
        """Silence default http.server logging."""


def main() -> None:
    """Start a TLS HTTP server on PORT using the bundled self-signed cert."""
    port = int(os.environ.get("PORT", "443"))
    server = HTTPServer(("0.0.0.0", port), Handler)

    cert_file = "/app/backends/tls_cert.txt"
    key_file = "/app/backends/tls_key.txt"

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(certfile=cert_file, keyfile=key_file)
    server.socket = ctx.wrap_socket(server.socket, server_side=True)

    server.serve_forever()


if __name__ == "__main__":
    main()

