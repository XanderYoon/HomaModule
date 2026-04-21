#!/usr/bin/env bash
set -euo pipefail

BENCH_SCRIPT="cp_transport_vs_connection_pools"
BENCH_LABEL="connection pooling comparison"
RESULT_SUBDIR="connection_pooling"
LOG_PREFIX="connection_pooling"
VARIANT_FLAG="--pool-size"
VARIANT_VALUE="${POOL_SIZE:-4}"
VARIANT_HELP_NAME="POOL_SIZE"
VARIANT_HELP_TEXT="Pooled TCP connection count for the application-layer pooling variant"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../run_dctcp_tuning.sh" "$@"
