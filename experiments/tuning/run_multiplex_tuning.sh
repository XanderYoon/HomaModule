#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_multiplex_sessions"
BENCH_LABEL="HTTP/2 tuning"
RESULT_SUBDIR="multiplex"
LOG_PREFIX="multiplex"
VARIANT_FLAG="--multiplex-session-counts"
VARIANT_VALUE="${MULTIPLEX_SESSION_COUNTS:-1,2,4,8}"
VARIANT_HELP_NAME="MULTIPLEX_SESSION_COUNTS"
VARIANT_HELP_TEXT="Comma-separated HTTP/2 max-concurrent-stream settings to compare"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
