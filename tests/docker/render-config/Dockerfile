# Pinned to the digest of hashicorp/terraform:1.14.3 for supply-chain integrity; tag kept for readability: 1.14.3
FROM hashicorp/terraform:1.14.3@sha256:20056ea0d2706f2a944e202befa8a558dbcc5798da0b64f884b2647aab82a4ef

# Used to robustly extract the cfg from `terraform show -json` without brittle heredoc parsing.
RUN apk add --no-cache jq
