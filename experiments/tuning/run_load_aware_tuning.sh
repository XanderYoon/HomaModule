#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_load_aware"
BENCH_LABEL="load-aware tuning"
RESULT_SUBDIR="load_aware"
LOG_PREFIX="load_aware"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
