#!/bin/bash

set -euo pipefail

# Configuration
REPO_OWNER="bennydreamtech23"  
REPO_NAME="precheck"        
INSTALL_DIR="${HOME}/.local/bin"
VERSION="${1:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==== Utility Functions ====

print_error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ==== Platform Detection ====

detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux" ;;
        Darwin*)    echo "darwin" ;;
        *)          echo "unknown" ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)       echo "amd64" ;;
        aarch64|arm64)      echo "arm64" ;;
        *)                  echo "unknown" ;;
    esac
}

# ==== GitHub Release Functions ====

get_latest_version() {
    local url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    
    local version=$(curl -s "$url" | grep '"tag_name"' | head -1 | cut -d'"' -f4 | sed 's/^v//')
    
    if [ -z "$version" ]; then
        print_error "Could not fetch latest version from GitHub"
        return 1
    fi
    
    echo "$version"
}

get_download_url() {
    local version=$1
    local os=$2
    local arch=$3
    
    # Format: precheck_v1.0.0_linux_amd64.tar.gz
    local filename="precheck_v${version}_${os}_${arch}.tar.gz"
    local url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/v${version}/${filename}"
    
    echo "$url"
}

# ==== Installation ====

main() {
    print_info "Installing Precheck..."
    
    local os=$(detect_os)
    local arch=$(detect_arch)
    
    if [ "$os" = "unknown" ] || [ "$arch" = "unknown" ]; then
        print_error "Unsupported platform: ${os}_${arch}"
        exit 1
    fi
    
    print_info "Detected platform: ${os}_${arch}"
    
    # Get version
    if [ "$VERSION" = "latest" ]; then
        print_info "Fetching latest version..."
        VERSION=$(get_latest_version)
        if [ $? -ne 0 ]; then
            exit 1
        fi
    fi
    
    print_info "Version: ${VERSION}"
    
    # Get download URL
    local url=$(get_download_url "$VERSION" "$os" "$arch")
    print_info "Download URL: $url"
    
    # Create temp directory
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT
    
    # Download
    print_info "Downloading..."
    if ! curl -fsSL "$url" -o "$temp_dir/precheck.tar.gz"; then
        print_error "Failed to download from $url"
        exit 1
    fi
    
    print_success "Downloaded"
    
    # Extract
    print_info "Extracting..."
    if ! tar -xzf "$temp_dir/precheck.tar.gz" -C "$temp_dir"; then
        print_error "Failed to extract archive"
        exit 1
    fi
    
    # Find binary (handle different possible names)
    local binary
    if [ -f "$temp_dir/precheck" ]; then
        binary="$temp_dir/precheck"
    elif [ -f "$temp_dir/precheck-${os}-${arch}" ]; then
        binary="$temp_dir/precheck-${os}-${arch}"
    else
        print_error "Binary not found in archive"
        ls -la "$temp_dir"
        exit 1
    fi
    
    # Create install directory if needed
    mkdir -p "$INSTALL_DIR"
    
    # Copy and make executable
    print_info "Installing to $INSTALL_DIR..."
    cp "$binary" "$INSTALL_DIR/precheck"
    chmod +x "$INSTALL_DIR/precheck"
    
    print_success "Installed to $INSTALL_DIR/precheck"
    
    # Verify
    print_info "Verifying installation..."
    if ! "$INSTALL_DIR/precheck" --version > /dev/null 2>&1; then
        print_error "Verification failed"
        exit 1
    fi
    
    local installed_version
    installed_version=$("$INSTALL_DIR/precheck" --version)
    print_success "Verified: $installed_version"
    
    # PATH check
    if ! command -v precheck &> /dev/null; then
        print_warn "precheck is not in your PATH"
        print_info "Add to your shell profile:"
        echo ""
        echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
        echo ""
        print_info "Then run: source ~/.bashrc (or ~/.zshrc)"
    else
        print_success "precheck is ready!"
    fi
    
    print_info "Quick start:"
    echo "  precheck --help"
}

# Run main
main "$@"