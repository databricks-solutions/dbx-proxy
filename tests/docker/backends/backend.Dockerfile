# Pinned to the digest of python:3.12-slim for supply-chain integrity; tag kept for readability: 3.12-slim
FROM python:3.14-slim@sha256:cea0e6040540fb2b965b6e7fb5ffa00871e632eef63719f0ea54bca189ce14a6

WORKDIR /app

# Generate an ephemeral self-signed cert/key for the test TLS backend at build time.
# These are throwaway test credentials, so they are regenerated on every image build
# rather than committed to the repo.
RUN apt-get update && apt-get install -y --no-install-recommends openssl \
    && rm -rf /var/lib/apt/lists/*

COPY backends /app/backends

RUN openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /app/backends/tls_key.txt \
    -out /app/backends/tls_cert.txt \
    -days 3650 -subj "/CN=dbx-proxy"

EXPOSE 443 5432
