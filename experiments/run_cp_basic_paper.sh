#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_PATH="${OUTPUT_PATH:-$REPO_ROOT/homa_reproduced.md}"
RUN_DIR_LINK="${RUN_DIR_LINK:-$REPO_ROOT/experiments/results/runs/baseline/latest}"

export NUM_NODES="${NUM_NODES:-10}"
export RUN_SECONDS="${RUN_SECONDS:-5}"
export DCTCP="${DCTCP:-true}"
export START_SCRIPT="${START_SCRIPT:-start_xl170}"
unset CLIENT_PORTS PORT_RECEIVERS PORT_THREADS SERVER_PORTS
unset TCP_CLIENT_PORTS TCP_PORT_RECEIVERS TCP_SERVER_PORTS TCP_PORT_THREADS

"$SCRIPT_DIR/run_cp_basic.sh" "$@"

python3 "$REPO_ROOT/experiments/generate_cp_basic.py" \
    "$RUN_DIR_LINK" \
    --output "$OUTPUT_PATH" \
    --title "Homa Reproduced" \
    --include-paper-reference \
    --paper-caption

printf '\n[done] wrote %s\n' "$OUTPUT_PATH"
