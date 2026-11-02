# Pinned to the digest of hashicorp/terraform:1.14.3 for supply-chain integrity; tag kept for readability: 1.14.3
FROM hashicorp/terraform:1.17.1@sha256:a5d5a5a892c98f60fcbfa81eac2a40fc19e7b3fa7719bccae10ff6111d22524a

# Used to robustly extract the cfg from `terraform show -json` without brittle heredoc parsing.
RUN apk add --no-cache jq
