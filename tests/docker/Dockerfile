# Pinned to the digest of python:3.12-slim for supply-chain integrity; tag kept for readability: 3.12-slim
FROM python:3.12-slim@sha256:57cd7c3a7a273101a6485ba99423ee568157882804b1124b4dd04266317710de

WORKDIR /tests
RUN mkdir -p /tests/unit_tests

COPY tests/unit_tests/ /tests/unit_tests/

CMD ["python", "-m", "unittest", "discover", "-s", "./unit_tests", "-p", "test_*.py", "-v"]
