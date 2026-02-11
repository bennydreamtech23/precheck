#!/usr/bin/env bash
set -e

REPO="bennydreamtech23/precheck"
VERSION="${1:-latest}"

# ── Resolve "latest" to the actual tag ───────────────────────────────────────
if [ "$VERSION" = "latest" ]; then
  VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\(.*\)".*/\1/')
fi

if [ -z "$VERSION" ]; then
  echo "❌ Could not determine the latest version. Please pass a version explicitly:"
  echo "   bash install.sh v1.2.0"
  exit 1
fi

echo "🔍 Installing Precheck $VERSION..."

# ── Detect OS and architecture ────────────────────────────────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  linux)
    case "$ARCH" in
      x86_64) PLATFORM="linux-x64" ;;
      aarch64|arm64) PLATFORM="linux-arm64" ;;
      *)
        echo "❌ Unsupported Linux architecture: $ARCH"
        exit 1
        ;;
    esac
    ;;
  darwin)
    case "$ARCH" in
      arm64) PLATFORM="darwin-arm64" ;;
      x86_64) PLATFORM="darwin-x64" ;;
      *)
        echo "❌ Unsupported macOS architecture: $ARCH"
        exit 1
        ;;
    esac
    ;;
  *)
    echo "❌ Unsupported operating system: $OS"
    echo "   Precheck supports Linux (x64) and macOS (ARM64 / x64)."
    exit 1
    ;;
esac

FILENAME="precheck-${VERSION}-${PLATFORM}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${FILENAME}"

# ── Download ──────────────────────────────────────────────────────────────────
TEMP_DIR=$(mktemp -d)
echo "⬇️  Downloading $FILENAME..."
curl -fsSL "$DOWNLOAD_URL" -o "$TEMP_DIR/$FILENAME" || {
  echo "❌ Download failed. Check that release $VERSION exists and supports platform '$PLATFORM'."
  rm -rf "$TEMP_DIR"
  exit 1
}

# ── Extract ───────────────────────────────────────────────────────────────────
echo "📦 Extracting..."
tar -xzf "$TEMP_DIR/$FILENAME" -C "$TEMP_DIR"

# ── Install binary ────────────────────────────────────────────────────────────
INSTALL_DIR="/usr/local/bin"

if [ -f "$TEMP_DIR/bin/precheck-native" ]; then
  echo "⚙️  Installing native binary..."
  if [ -w "$INSTALL_DIR" ]; then
    cp "$TEMP_DIR/bin/precheck-native" "$INSTALL_DIR/precheck-native"
    chmod +x "$INSTALL_DIR/precheck-native"
  else
    sudo cp "$TEMP_DIR/bin/precheck-native" "$INSTALL_DIR/precheck-native"
    sudo chmod +x "$INSTALL_DIR/precheck-native"
  fi
fi

if [ -f "$TEMP_DIR/bin/precheck" ]; then
  echo "⚙️  Installing precheck..."
  if [ -w "$INSTALL_DIR" ]; then
    cp "$TEMP_DIR/bin/precheck" "$INSTALL_DIR/precheck"
    chmod +x "$INSTALL_DIR/precheck"
  else
    sudo cp "$TEMP_DIR/bin/precheck" "$INSTALL_DIR/precheck"
    sudo chmod +x "$INSTALL_DIR/precheck"
  fi
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TEMP_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✅ Precheck $VERSION installed successfully!"
echo ""
precheck --help