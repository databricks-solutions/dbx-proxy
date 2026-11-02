# Pinned to the digest of python:3.12-slim for supply-chain integrity; tag kept for readability: 3.12-slim
FROM python:3.14-slim@sha256:cd89c30eda26ee911a4611b18680086e0ea42e6f5f8cbe653d07fa7958c9cec8

WORKDIR /tests
RUN mkdir -p /tests/unit_tests

COPY tests/unit_tests/ /tests/unit_tests/

CMD ["python", "-m", "unittest", "discover", "-s", "./unit_tests", "-p", "test_*.py", "-v"]
