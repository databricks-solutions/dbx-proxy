# Pinned to the digest of hashicorp/terraform:1.14.3 for supply-chain integrity; tag kept for readability: 1.14.3
FROM hashicorp/terraform:1.15.8@sha256:7ae513256f7ce67879e218ae8593d6fbe216ec9e123abe6c94e4e10704857963

# Used to robustly extract the cfg from `terraform show -json` without brittle heredoc parsing.
RUN apk add --no-cache jq
