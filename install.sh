#!/usr/bin/env bash
set -e

REPO="bennydreamtech23/precheck"
VERSION="${1:-latest}"

# ── Check for Erlang/OTP ──────────────────────────────────────────────────────
echo "🔍 Checking for Erlang/OTP..."

ERLANG_FOUND=false
ERL_VERSION="unknown"

if [ -n "$SUDO_USER" ]; then
  # Try to detect shell config file
  USER_HOME=$(eval echo "~$SUDO_USER")
  if [ -f "$USER_HOME/.zshrc" ]; then
    SHELL_RC="$USER_HOME/.zshrc"
  elif [ -f "$USER_HOME/.bashrc" ]; then
    SHELL_RC="$USER_HOME/.bashrc"
  else
    SHELL_RC=""
  fi

  # Compose command to source shell config and check for erl/asdf
  if [ -n "$SHELL_RC" ]; then
    CHECK_CMD="source $SHELL_RC; command -v erl"
    ASDF_CMD="source $SHELL_RC; command -v asdf"
    WHICH_ERL_CMD="source $SHELL_RC; asdf which erl"
  else
    CHECK_CMD="command -v erl"
    ASDF_CMD="command -v asdf"
    WHICH_ERL_CMD="asdf which erl"
  fi

  if su - "$SUDO_USER" -c "$CHECK_CMD" &> /dev/null; then
    ERLANG_FOUND=true
    ERL_VERSION=$(su - "$SUDO_USER" -c "source $SHELL_RC; erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null" || echo "unknown")
  elif su - "$SUDO_USER" -c "$ASDF_CMD" &> /dev/null; then
    if su - "$SUDO_USER" -c "$WHICH_ERL_CMD" &> /dev/null; then
      ERLANG_FOUND=true
      ERL_PATH=$(su - "$SUDO_USER" -c "$WHICH_ERL_CMD")
      ERL_VERSION=$(su - "$SUDO_USER" -c "source $SHELL_RC; $ERL_PATH -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null" || echo "unknown")
    fi
  fi
else
  # Regular user
  if command -v erl &> /dev/null; then
    ERLANG_FOUND=true
    ERL_VERSION=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo "unknown")
  elif command -v asdf &> /dev/null; then
    if asdf which erl &> /dev/null; then
      ERLANG_FOUND=true
      ERL_PATH=$(asdf which erl)
      ERL_VERSION=$($ERL_PATH -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo "unknown")
    fi
  fi
fi

if [ "$ERLANG_FOUND" = false ]; then
  echo ""
  echo "⚠️  WARNING: Erlang/OTP is not installed or not found in your PATH!"
  echo ""
  echo "Precheck requires Erlang/OTP to run. Please install it first:"
  echo ""
  echo "  Ubuntu/Debian:"
  echo "    sudo apt-get update && sudo apt-get install -y erlang-base"
  echo ""
  echo "  macOS (Homebrew):"
  echo "    brew install erlang"
  echo ""
  echo "  Or use asdf:"
  echo "    asdf plugin-add erlang"
  echo "    asdf install erlang latest"
  echo "    asdf global erlang latest"
  echo ""
  echo "After installing Erlang, run this script again."
  echo ""
  exit 1
else
  echo "✅ Erlang/OTP found (version: $ERL_VERSION)"
fi

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

if [ -f "$TEMP_DIR/bin/precheck" ]; then
  echo "⚙️  Installing precheck..."
  if [ -w "$INSTALL_DIR" ]; then
    cp "$TEMP_DIR/bin/precheck" "$INSTALL_DIR/precheck"
    chmod +x "$INSTALL_DIR/precheck"
  else
    sudo cp "$TEMP_DIR/bin/precheck" "$INSTALL_DIR/precheck"
    sudo chmod +x "$INSTALL_DIR/precheck"
  fi
else
  echo "❌ ERROR: precheck binary not found in archive!"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$TEMP_DIR"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "✅ Precheck $VERSION installed successfully!"
echo ""

# Verify installation
echo "🔍 Verifying installation..."
if command -v precheck &> /dev/null; then
  if precheck --version &> /dev/null || precheck --help &> /dev/null; then
    echo "✅ Precheck is working correctly!"
    echo ""
    echo "To start using precheck, run one of the following:"
    echo ""
    echo "  # Option 1: Start a new terminal session"
    echo "  # Option 2: Reload your shell config"
    if [ -n "$ZSH_VERSION" ]; then
      echo "  source ~/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
      echo "  source ~/.bashrc"
    else
      echo "  source ~/.profile"
    fi
    echo ""
    echo "Then run:"
    echo "  precheck --help"
  else
    echo "⚠️  Warning: precheck installed but may not be working correctly."
    echo "This could be due to missing dependencies or Erlang configuration."
  fi
else
  echo "⚠️  Warning: precheck command not found in PATH."
  echo "You may need to reload your shell or add /usr/local/bin to your PATH."
fi