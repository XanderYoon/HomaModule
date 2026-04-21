#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_connection_pools"
BENCH_LABEL="connection pooling comparison"
RESULT_SUBDIR="connection_pooling"
LOG_PREFIX="connection_pooling"
VARIANT_FLAG="--pool-sizes"
VARIANT_VALUE="${POOL_SIZES:-2,4,8}"
VARIANT_HELP_NAME="POOL_SIZES"
VARIANT_HELP_TEXT="Comma-separated pooled TCP connection counts for the application-layer pooling variants"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
