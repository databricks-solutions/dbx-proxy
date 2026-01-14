"""Routing tests for dbx-proxy using the Terraform-rendered HAProxy config."""

from __future__ import annotations

import os
import socket
import ssl
import time
import unittest


def _wait_for_tcp(host: str, port: int, timeout_s: float = 60.0) -> None:
    """Wait until a TCP connection to host:port succeeds."""
    deadline = time.monotonic() + timeout_s
    last_err: str | None = None

    while time.monotonic() < deadline:
        try:
            with socket.create_connection((host, port), timeout=2):
                return
        except OSError as e:
            last_err = str(e)
            time.sleep(1.0)

    raise AssertionError(f"TCP port not reachable: {host}:{port} last_err={last_err}")


class TestDbxProxyListener(unittest.TestCase):
    """Validate rendered config and basic routing behavior."""

    def setUp(self) -> None:
        """Load commonly used environment variables."""
        self.host = os.environ.get("DBX_PROXY_HOST", "test-dbx-proxy")
        self.tcp_port = int(os.environ.get("DBX_PROXY_TCP_PORT", "5432"))
        self.tls_port = int(os.environ.get("DBX_PROXY_TLS_PORT", "443"))

    def test_rendered_cfg_contains_expected_rules(self) -> None:
        """Assert the Terraform-rendered dbx-proxy.cfg contains key sections."""
        cfg_path = "/proxy-conf/dbx-proxy.cfg"
        with open(cfg_path, "r", encoding="utf-8") as f:
            cfg = f.read()

        self.assertIn("frontend health", cfg)
        self.assertIn("frontend database-5432_fe", cfg)
        self.assertIn("backend database-5432_be", cfg)
        self.assertIn("frontend https-443_fe", cfg)
        self.assertIn("acl sni_https-443_app-a req_ssl_sni -i app-a.application.domain", cfg)
        self.assertIn("acl sni_https-443_app-b req_ssl_sni -i app-b.application.domain", cfg)

    def test_tcp_routing_banner(self) -> None:
        """Connect to the TCP listener and assert we reach the expected backend."""
        _wait_for_tcp(self.host, self.tcp_port)
        with socket.create_connection((self.host, self.tcp_port), timeout=5) as s:
            banner = s.recv(1024).decode("utf-8", errors="replace")
        self.assertIn("test-backend-database", banner)

    def test_sni_routing_app_a(self) -> None:
        """SNI app-a should reach backend-app-a."""
        self._assert_sni_backend("app-a.application.domain", "APP_A")

    def test_sni_routing_app_b(self) -> None:
        """SNI app-b should reach backend-app-b."""
        self._assert_sni_backend("app-b.application.domain", "APP_B")

    def _assert_sni_backend(self, sni: str, expected_body: str) -> None:
        """Connect with a given SNI and assert the response body matches."""
        _wait_for_tcp(self.host, self.tls_port)

        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        with socket.create_connection((self.host, self.tls_port), timeout=5) as raw:
            with ctx.wrap_socket(raw, server_hostname=sni) as tls_sock:
                tls_sock.settimeout(5)
                tls_sock.sendall(b"GET / HTTP/1.1\r\nHost: example\r\nConnection: close\r\n\r\n")
                data = b""
                while True:
                    chunk = tls_sock.recv(4096)
                    if not chunk:
                        break
                    data += chunk

        text = data.decode("utf-8", errors="replace")
        self.assertIn(expected_body, text)
