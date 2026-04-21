#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_static_offsets"
BENCH_LABEL="static scheduler comparison"
RESULT_SUBDIR="static_offset"
LOG_PREFIX="static_offset"
VARIANT_FLAG="--offset-us"
VARIANT_VALUE="${OFFSET_US:-5}"
VARIANT_HELP_NAME="OFFSET_US"
VARIANT_HELP_TEXT="Static scheduler offset in microseconds to compare"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
