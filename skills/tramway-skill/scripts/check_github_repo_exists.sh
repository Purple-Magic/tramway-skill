#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <owner/repo>" >&2
  exit 2
fi

repo_slug="$1"
api_url="https://api.github.com/repos/${repo_slug}"

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

http_code="$(
  curl -sS -o /dev/null -w '%{http_code}' \
    -H 'Accept: application/vnd.github+json' \
    "${auth_header[@]}" \
    "${api_url}"
)"

case "${http_code}" in
  200)
    echo "exists"
    exit 0
    ;;
  404)
    echo "missing"
    exit 1
    ;;
  401|403)
    echo "unauthorized_or_forbidden"
    exit 3
    ;;
  *)
    echo "unexpected_http_${http_code}"
    exit 4
    ;;
esac
