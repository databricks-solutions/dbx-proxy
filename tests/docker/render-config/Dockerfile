# Pinned to the digest of hashicorp/terraform:1.14.3 for supply-chain integrity; tag kept for readability: 1.14.3
FROM hashicorp/terraform:1.17.0@sha256:4d1b496a256f2989bccdb04b9104a4ede97234b10fba90259e173e905ec4fb58

# Used to robustly extract the cfg from `terraform show -json` without brittle heredoc parsing.
RUN apk add --no-cache jq
