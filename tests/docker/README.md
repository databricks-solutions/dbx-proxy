## Dockerized integration tests

Run:

```bash
docker compose -f docker-compose.test.yml up --build --abort-on-container-exit --exit-code-from tests
```

Notes:
- The test container polls `http://dbx-proxy:${DBX_PROXY_HEALTH_PORT}/status` until it returns 200.
- Add future integration tests under `tests/docker/` as `test_*.py`.
