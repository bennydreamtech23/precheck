#!/usr/bin/env bash
set -euo pipefail

REPO="bennydreamtech23/precheck"
VERSION="${1:-latest}"
INSTALL_ROOT="/usr/local/lib/precheck"
BIN_DIR="/usr/local/bin"

log() {
  printf "%s\n" "$1"
}

die() {
  printf "ERROR: %s\n" "$1" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

run_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "This step needs root permissions. Install sudo or run as root."
  fi
}

resolve_latest_version() {
  local api_url="https://api.github.com/repos/$REPO/releases/latest"
  local json

  json="$(curl -fsSL "$api_url")"
  if command -v jq >/dev/null 2>&1; then
    jq -r '.tag_name // empty' <<<"$json"
  else
    sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' <<<"$json" | head -n1
  fi
}

detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$os" in
    linux)
      case "$arch" in
        x86_64) echo "linux-x64" ;;
        aarch64|arm64) echo "linux-arm64" ;;
        *) die "Unsupported Linux architecture: $arch" ;;
      esac
      ;;
    darwin)
      case "$arch" in
        arm64) echo "darwin-arm64" ;;
        x86_64) echo "darwin-x64" ;;
        *) die "Unsupported macOS architecture: $arch" ;;
      esac
      ;;
    *)
      die "Unsupported operating system: $os"
      ;;
  esac
}

verify_checksum() {
  local file="$1"
  local checksum_file="$2"
  local expected actual

  expected="$(awk '{print $1}' "$checksum_file")"
  [ -n "$expected" ] || die "Checksum file is empty or invalid: $checksum_file"

  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  fi

  [ "$expected" = "$actual" ] || die "Checksum mismatch for $(basename "$file")"
}

check_otp() {
  log "Checking Erlang/OTP runtime..."

  if ! command -v erl >/dev/null 2>&1; then
    cat <<'EOF'
WARNING: Erlang/OTP not found in PATH.
Precheck requires Erlang runtime to execute.

Install Erlang and rerun:
  Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y erlang-base
  macOS (Homebrew): brew install erlang
EOF
    exit 1
  fi

  log "Erlang/OTP found."
}

main() {
  need_cmd curl
  need_cmd tar
  need_cmd awk

  check_otp

  if [ "$VERSION" = "latest" ]; then
    VERSION="$(resolve_latest_version)"
  fi

  [ -n "$VERSION" ] || die "Unable to resolve release version"
  case "$VERSION" in
    v*) ;;
    *) die "Version must be a tag like v1.0.1. Got: $VERSION" ;;
  esac

  local platform filename download_url checksum_url
  platform="$(detect_platform)"
  filename="precheck-${VERSION}-${platform}.tar.gz"
  download_url="https://github.com/${REPO}/releases/download/${VERSION}/${filename}"
  checksum_url="${download_url}.sha256"

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT

  log "Downloading ${filename}..."
  curl -fsSL "$download_url" -o "$temp_dir/$filename" || die "Failed to download $filename"

  log "Downloading checksum..."
  curl -fsSL "$checksum_url" -o "$temp_dir/$filename.sha256" || die "Failed to download checksum file"

  log "Verifying artifact integrity..."
  verify_checksum "$temp_dir/$filename" "$temp_dir/$filename.sha256"

  log "Extracting archive..."
  tar -xzf "$temp_dir/$filename" -C "$temp_dir"

  local core_src nif_src
  core_src="$temp_dir/bin/precheck-core"
  [ -f "$core_src" ] || core_src="$temp_dir/bin/precheck"
  [ -f "$core_src" ] || die "Core binary not found in archive"

  nif_src="$(find "$temp_dir/priv/native" -maxdepth 1 -type f -name 'precheck_native.*' | head -n1 || true)"
  [ -n "$nif_src" ] || die "Native library not found in archive (priv/native/precheck_native.*)"

  log "Installing to $INSTALL_ROOT..."
  run_root mkdir -p "$INSTALL_ROOT/bin" "$INSTALL_ROOT/priv/native"
  run_root install -m 0755 "$core_src" "$INSTALL_ROOT/bin/precheck-core"
  run_root install -m 0644 "$nif_src" "$INSTALL_ROOT/priv/native/$(basename "$nif_src")"

  log "Creating command symlinks..."
  run_root mkdir -p "$BIN_DIR"
  run_root ln -sf "$INSTALL_ROOT/bin/precheck-core" "$BIN_DIR/precheck"
  run_root ln -sf "$INSTALL_ROOT/bin/precheck-core" "$BIN_DIR/precheck-core"

  log ""
  log "Precheck $VERSION installed successfully."
  log "Command: precheck --help"

  if precheck --version >/dev/null 2>&1 || precheck --help >/dev/null 2>&1; then
    log "Runtime verification passed."
  else
    die "Runtime verification failed. Check Erlang runtime and installation paths."
  fi
}

main "$@"
