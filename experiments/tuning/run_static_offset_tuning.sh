#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_static_offsets"
BENCH_LABEL="static scheduler comparison"
RESULT_SUBDIR="static_offset"
LOG_PREFIX="static_offset"
VARIANT_FLAG="--offsets-us"
VARIANT_VALUE="${OFFSETS_US:-3,5,10}"
VARIANT_HELP_NAME="OFFSETS_US"
VARIANT_HELP_TEXT="Comma-separated static scheduler offsets in microseconds to compare"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
