# Precheck

Secure pre-deployment checks distributed as compiled artifacts.

## Install

```bash
curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.1/install.sh | bash
```

To install a specific version:

```bash
curl -fsSL https://github.com/bennydreamtech23/precheck/releases/download/v1.0.1/install.sh | bash -s -- v1.0.1
```

## What Gets Installed

- `/usr/local/bin/precheck` (symlink to compiled core)
- `/usr/local/bin/precheck-core` (compiled core)
- `/usr/local/lib/precheck/bin/precheck-core`
- `/usr/local/lib/precheck/priv/native/precheck_native.so`

## Security Model

- Public release ships compiled runtime assets only.
- Public release does not ship internal shell business-logic scripts.
- Installer verifies artifact checksums (`.sha256`) before extraction.

## Requirements

- `curl`, `tar`, `awk`
- Erlang/OTP runtime (`erl` in PATH)
- `sudo` or root privileges for system install locations

## Usage

```bash
precheck --help
precheck --version
precheck -p .
```

## Verify Installation

```bash
which precheck
precheck --version
ls -l /usr/local/lib/precheck/bin/precheck-core
ls -l /usr/local/lib/precheck/priv/native/precheck_native.so
```
