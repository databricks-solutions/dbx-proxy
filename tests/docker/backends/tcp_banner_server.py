"""Simple TCP banner server for integration tests."""

from __future__ import annotations

import os
import socket


def main() -> None:
    """Start a TCP server that writes a banner on connect and closes."""
    host = "0.0.0.0"
    port = int(os.environ.get("PORT", "5432"))
    banner = (os.environ.get("BANNER", "BANNER") + "\n").encode("utf-8")

    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((host, port))
        s.listen(128)

        while True:
            conn, _addr = s.accept()
            with conn:
                try:
                    conn.sendall(banner)
                except OSError:
                    pass


if __name__ == "__main__":
    main()

