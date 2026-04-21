#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_tfo"
BENCH_LABEL="TFO comparison"
RESULT_SUBDIR="tfo"
LOG_PREFIX="tfo"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
