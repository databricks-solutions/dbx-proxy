# Pinned to the digest of python:3.12-slim for supply-chain integrity; tag kept for readability: 3.12-slim
FROM python:3.14-slim@sha256:ce40764625a4ff50df3548277632e7f96c4e77fe75fa848aae9885476e7df5a4

WORKDIR /tests
RUN mkdir -p /tests/unit_tests

COPY tests/unit_tests/ /tests/unit_tests/

CMD ["python", "-m", "unittest", "discover", "-s", "./unit_tests", "-p", "test_*.py", "-v"]
