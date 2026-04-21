#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_dctcp_static_load_aware"
BENCH_LABEL="Homa vs DCTCP vs static scheduler + load-aware comparison"
RESULT_SUBDIR="dctcp_static_load_aware"
LOG_PREFIX="dctcp_static_load_aware"
VARIANT_FLAG="--offset-us"
VARIANT_VALUE="${OFFSET_US:-5}"
VARIANT_HELP_NAME="OFFSET_US"
VARIANT_HELP_TEXT="Static scheduler offset in microseconds for the combined DCTCP static+load-aware variant"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
