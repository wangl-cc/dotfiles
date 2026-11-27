#!/usr/bin/env bash
# Query the configured shared server and its sessions without changing state.
set -euo pipefail
exec python3 -B "$(dirname -- "${BASH_SOURCE[0]}")/client.py" discover "$@"
