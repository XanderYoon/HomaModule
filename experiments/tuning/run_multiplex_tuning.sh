#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_multiplex_sessions"
BENCH_LABEL="multiplexing comparison"
RESULT_SUBDIR="multiplex"
LOG_PREFIX="multiplex"
VARIANT_FLAG="--multiplex-sessions"
VARIANT_VALUE="${MULTIPLEX_SESSIONS:-4}"
VARIANT_HELP_NAME="MULTIPLEX_SESSIONS"
VARIANT_HELP_TEXT="Max concurrent logical streams per shared TCP session for the multiplexing variant"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
