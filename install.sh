#!/usr/bin/env bash
set -e

echo "⬇️ Downloading Precheck (v1.0.0-beta)..."

curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0-beta/precheck_v1.0.0.tar.gz -o precheck.tar.gz

echo "📦 Extracting package..."
tar -xzf precheck.tar.gz

echo "⚙️ Installing..."
chmod +x precheck
sudo mv precheck /usr/local/bin/

echo "✅ Precheck installed successfully!"
