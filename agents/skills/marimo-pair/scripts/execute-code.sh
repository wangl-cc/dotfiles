#!/usr/bin/env bash
# Execute scratchpad code in one notebook on the configured shared server.
set -euo pipefail
exec python3 -B "$(dirname -- "${BASH_SOURCE[0]}")/client.py" execute "$@"
