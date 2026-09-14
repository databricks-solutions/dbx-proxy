# Pinned to the digest of hashicorp/terraform:1.14.3 for supply-chain integrity; tag kept for readability: 1.14.3
FROM hashicorp/terraform:1.16.2@sha256:c3308fcbb530627c102c4c4b993e226b202429084328c3cc505cc2a69342e883

# Used to robustly extract the cfg from `terraform show -json` without brittle heredoc parsing.
RUN apk add --no-cache jq
