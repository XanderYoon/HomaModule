#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_static_offsets"
BENCH_LABEL="static offset tuning"
RESULT_SUBDIR="static_offset"
LOG_PREFIX="static_offset"
VARIANT_FLAG="--offsets-us"
VARIANT_VALUE="${OFFSETS_US:-0,5,10,25,50}"
VARIANT_HELP_NAME="OFFSETS_US"
VARIANT_HELP_TEXT="Comma-separated scheduler offset values in microseconds to compare"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
