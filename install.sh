set -e

echo "⬇️ Downloading Precheck (v1.0.0)..."
curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0/precheck-v1.0.0-linux-x64.tar.gz -o precheck.tar.gz

echo "📦 Extracting package..."
tar -xzf precheck.tar.gz

echo "⚙️ Installing..."
sudo mv bin/precheck /usr/local/bin/precheck

echo "✅ Precheck installed successfully!"
precheck --help
