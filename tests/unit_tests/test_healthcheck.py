"""Dockerized integration tests for dbx-proxy."""

from __future__ import annotations

import json
import os
import time
import unittest
import urllib.error
import urllib.request


class TestDbxProxyHealthcheck(unittest.TestCase):
    """Verify dbx-proxy comes up and serves the health endpoint."""

    def test_healthcheck_returns_200(self) -> None:
        """Wait for the health endpoint and assert it returns 200 + expected payload."""
        host = os.environ.get("DBX_PROXY_HOST", "dbx-proxy")
        port = int(os.environ.get("DBX_PROXY_HEALTH_PORT", "8080"))
        url = f"http://{host}:{port}/status"

        deadline = time.monotonic() + 60.0
        last_err: str | None = None

        while time.monotonic() < deadline:
            try:
                with urllib.request.urlopen(url, timeout=2) as resp:  # noqa: S310
                    body = resp.read().decode("utf-8", errors="replace")
                    if resp.status != 200:
                        last_err = f"unexpected status={resp.status} body={body}"
                        time.sleep(1.0)
                        continue

                    payload = json.loads(body)
                    self.assertEqual(payload, {"detail": "HEALTHY"})
                    return
            except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
                last_err = str(e)
                time.sleep(1.0)

        self.fail(f"dbx-proxy healthcheck did not become ready: {url} last_err={last_err}")
