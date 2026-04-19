#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_http2_sessions"
BENCH_LABEL="HTTP/2 tuning"
RESULT_SUBDIR="http2"
LOG_PREFIX="http2"
VARIANT_FLAG="--http2-session-counts"
VARIANT_VALUE="${HTTP2_SESSION_COUNTS:-1,2,4,8}"
VARIANT_HELP_NAME="HTTP2_SESSION_COUNTS"
VARIANT_HELP_TEXT="Comma-separated HTTP/2 multiplexed session counts to compare"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
