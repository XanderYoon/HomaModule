#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat <<'EOF'
Usage: run_tuned.sh [options]

Wrapper around run_baselines.sh for the tuned DCTCP comparison.

Tuned defaults:
  TCP disabled, DCTCP enabled
  HTTP/2 enabled
  connection pooling enabled
  HTTP/2 sessions = 4
  pool size = 1
  TFO disabled

Tuned-specific aliases:
  --http2-sessions N    Tuned DCTCP HTTP/2 session count (default: 4)
  --pool-size N         Tuned DCTCP pooled connection count (default: 1)
  --tfo BOOL            Enable TCP Fast Open for tuned DCTCP (default: false)
  -h, --help            Show this help, then run_baselines.sh help

All other arguments are passed through to run_baselines.sh unchanged.
EOF
}

export BENCH_LABEL="${BENCH_LABEL:-Tuned baseline}"
export LOG_PREFIX="${LOG_PREFIX:-tuned}"
export RESULTS_SUBDIR="${RESULTS_SUBDIR:-tuned}"
export SUMMARY_TITLE="${SUMMARY_TITLE:-Tuned baseline Summary}"
export TCP="${TCP:-false}"
export DCTCP="${DCTCP:-true}"
export TCP_CLIENT_POOLING="${TCP_CLIENT_POOLING:-true}"
export TCP_HTTP2="${TCP_HTTP2:-true}"
export TCP_HTTP2_SESSIONS="${TCP_HTTP2_SESSIONS:-4}"
export TCP_FASTOPEN="${TCP_FASTOPEN:-false}"
export TCP_CLIENT_PORTS="${TCP_CLIENT_PORTS:-4}"
export TCP_POOL_SIZE="${TCP_POOL_SIZE:-1}"
export TCP_PORT_RECEIVERS="${TCP_PORT_RECEIVERS:-1}"

forwarded=()
show_help=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --http2-sessions)
            TCP_HTTP2_SESSIONS="$2"
            shift 2
            ;;
        --pool-size)
            TCP_POOL_SIZE="$2"
            TCP_CLIENT_POOLING=true
            shift 2
            ;;
        --tfo)
            TCP_FASTOPEN="$2"
            shift 2
            ;;
        -h|--help)
            show_help=true
            forwarded+=("$1")
            shift
            ;;
        *)
            forwarded+=("$1")
            shift
            ;;
    esac
done

export TCP_CLIENT_PORTS
export TCP_HTTP2_SESSIONS
export TCP_POOL_SIZE
export TCP_PORT_RECEIVERS
export TCP_FASTOPEN

if [[ "$show_help" == true ]]; then
    usage
    echo
fi

exec "$SCRIPT_DIR/run_baselines.sh" "${forwarded[@]}"
