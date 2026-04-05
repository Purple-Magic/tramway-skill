#!/usr/bin/env bash
set -euo pipefail

if command -v terraform >/dev/null 2>&1; then
  terraform -version
  exit 0
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

run_privileged() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "This install path needs root or sudo: $*" >&2
    exit 1
  fi
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

fetch_latest_version() {
  need_cmd curl
  curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform \
    | sed -n 's/.*"current_version":"\([^"]*\)".*/\1/p'
}

manual_install() {
  local os="$1"
  local arch version tmpdir archive_url

  need_cmd curl
  need_cmd unzip
  need_cmd install

  arch="$(detect_arch)"
  version="${TERRAFORM_VERSION:-$(fetch_latest_version)}"

  if [ -z "$version" ]; then
    echo "Unable to determine Terraform version." >&2
    exit 1
  fi

  archive_url="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${os}_${arch}.zip"
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  curl -fsSL "$archive_url" -o "$tmpdir/terraform.zip"
  unzip -q "$tmpdir/terraform.zip" -d "$tmpdir"

  if [ -w /usr/local/bin ]; then
    install -m 0755 "$tmpdir/terraform" /usr/local/bin/terraform
  else
    run_privileged install -m 0755 "$tmpdir/terraform" /usr/local/bin/terraform
  fi
}

install_with_apt() {
  local arch codename

  need_cmd curl
  need_cmd gpg
  arch="$(dpkg --print-architecture)"
  codename="$(
    . /etc/os-release
    if [ -n "${UBUNTU_CODENAME:-}" ]; then
      printf '%s' "$UBUNTU_CODENAME"
    else
      printf '%s' "$VERSION_CODENAME"
    fi
  )"

  if [ -z "$codename" ]; then
    echo "Unable to determine Debian/Ubuntu codename for Terraform apt repo." >&2
    exit 1
  fi

  run_privileged mkdir -p /usr/share/keyrings
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | run_privileged gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  printf 'deb [arch=%s signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com %s main\n' "$arch" "$codename" \
    | run_privileged tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  run_privileged apt-get update
  run_privileged apt-get install -y terraform
}

case "$(uname -s)" in
  Darwin)
    if command -v brew >/dev/null 2>&1; then
      brew tap hashicorp/tap
      brew install hashicorp/tap/terraform
    else
      manual_install "darwin"
    fi
    ;;
  Linux)
    if command -v apt-get >/dev/null 2>&1 && [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID:-}" in
        ubuntu|debian)
          install_with_apt
          ;;
        *)
          manual_install "linux"
          ;;
      esac
    else
      manual_install "linux"
    fi
    ;;
  *)
    echo "Unsupported operating system: $(uname -s)" >&2
    exit 1
    ;;
esac

terraform -version
