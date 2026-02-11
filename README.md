# Precheck

A comprehensive pre-deployment validation toolkit for modern development teams. Automatically detects your project type and runs intelligent checks to ensure deployment readiness.

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/bennydreamtech23/precheck/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Supported Languages](https://img.shields.io/badge/supports-Elixir%20%7C%20Node.js-orange.svg)](#supported-languages)

---

## Installation

### Quick Install (Recommended)

**Linux (x64)**
```bash
curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0/install.sh | bash
```

**macOS (ARM / Apple Silicon)**
```bash
curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0/install.sh | bash
```

> 💡 **Tip:** If you encounter a "Permission denied" error, run with `sudo`:
> ```bash
> curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0/install.sh | sudo bash
> ```

### Manual Installation

Download the appropriate tarball for your platform from the [latest release](https://github.com/bennydreamtech23/precheck/releases/latest):

**Linux (x64)**
```bash
curl -LO https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0/precheck-v1.0.0-linux-x64.tar.gz
tar -xzf precheck-v1.0.0-linux-x64.tar.gz
sudo mv bin/precheck-native /usr/local/bin/precheck-native
sudo chmod +x /usr/local/bin/precheck-native
```

**macOS (ARM / Apple Silicon)**
```bash
curl -LO https://github.com/bennydreamtech23/precheck/releases/download/v1.0.0/precheck-v1.0.0-darwin-arm64.tar.gz
tar -xzf precheck-v1.0.0-darwin-arm64.tar.gz
sudo mv bin/precheck-native /usr/local/bin/precheck-native
sudo chmod +x /usr/local/bin/precheck-native
```

### Verify Installation

```bash
precheck --help
```

---

## Usage

### Basic Usage

Run precheck in your project directory:

```bash
precheck
```

This will automatically detect your project type and run the appropriate checks.

### Advanced Options

```bash
# Run checks on a specific directory
precheck --path ./src

# Output results in JSON format
precheck --format json

# Run specific check types only
precheck --checks security,quality

# Configure precheck for your project
precheck --setup

# Show version
precheck --version
```

---

## Supported Languages

- **Elixir** - Mix projects, dependency checks, code quality
- **Node.js** - npm/yarn projects, dependency security, linting
- More languages coming soon!

---

## Features

✅ **Automatic Project Detection** - Identifies your tech stack automatically  
✅ **Dependency Security Scanning** - Checks for known vulnerabilities  
✅ **Code Quality Analysis** - Linting, formatting, and best practices  
✅ **Build Validation** - Ensures your project can compile/build successfully  
✅ **Deployment Readiness** - Verifies environment configs and required files  
✅ **Fast & Lightweight** - Native Rust-powered performance

---

## Release Assets

The latest release (`v1.0.0`) includes:

| Asset | Size | SHA-256 Checksum |
|-------|------|------------------|
| **install.sh** | 3.77 KB | `934b0e70efd1dbcb4056c1962f0e8a4d16a33477f00fe41a14d67d4217aa91dc` |
| **precheck-v1.0.0-linux-x64.tar.gz** | 898 KB | `38ce46cea16db894b5ea90b9b4819d98c03ecabf3994a43a9a7a4540362432ac` |
| **precheck-v1.0.0-darwin-arm64.tar.gz** | 760 KB | `a0af4d23e1c680440d692ed11abce93c61d0fe7c8bde1e9f7089ecd04364daf8` |

---

## Contributing

We welcome contributions! Please see our [contributing guidelines](CONTRIBUTING.md) for details.

---

## Support

- 📖 [Documentation](https://github.com/bennydreamtech23/precheck/wiki)
- 🐛 [Report Issues](https://github.com/bennydreamtech23/precheck/issues)
- 💬 [Discussions](https://github.com/bennydreamtech23/precheck/discussions)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Changelog

See [RELEASES](https://github.com/bennydreamtech23/precheck/releases) for version history.