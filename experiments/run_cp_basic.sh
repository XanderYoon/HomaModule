#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

NODE0_ALIAS="${NODE0_ALIAS:-node0}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/HomaModule}"
NUM_NODES="${NUM_NODES:-5}"
RUN_SECONDS="${RUN_SECONDS:-5}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-}"
LINK_MBPS="${LINK_MBPS:-25000}"
HOMA_MAX_NIC_QUEUE_NS="${HOMA_MAX_NIC_QUEUE_NS:-2000}"
HOMA_RTT_BYTES="${HOMA_RTT_BYTES:-60000}"
HOMA_GRANT_INCREMENT="${HOMA_GRANT_INCREMENT:-10000}"
HOMA_MAX_GSO_SIZE="${HOMA_MAX_GSO_SIZE:-20000}"
LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR="${LOCAL_RESULTS_DIR:-$REPO_ROOT/experiments/results}"
RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/basic"
LOG_DIR=""
LOCAL_RUN_DIR=""
BASIC_OUTPUT=""
SUMMARY_MD=""

log() {
    printf '\n[%s] %s\n' "$1" "$2"
}

fetch_partial_logs() {
    if [[ -z "$LOCAL_RUN_DIR" ]]; then
        return
    fi
    mkdir -p "$LOCAL_RUN_DIR"
    if [[ -n "$LOG_DIR" ]]; then
        rsync -e "ssh -o StrictHostKeyChecking=no" -rt \
            "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/$LOG_DIR/" "$LOCAL_RUN_DIR/" \
            >/dev/null 2>&1 || true
    fi
}

on_error() {
    local exit_code="$1"
    log warn "cp_basic run failed; fetching any partial logs to $LOCAL_RUN_DIR"
    fetch_partial_logs
    if [[ -n "$BASIC_OUTPUT" && -f "$BASIC_OUTPUT" ]]; then
        if [[ -s "$BASIC_OUTPUT" ]]; then
            log warn "Last cp_basic output lines"
            tail -n 40 "$BASIC_OUTPUT" || true
        elif [[ -f "$LOCAL_RUN_DIR/reports/cperf.log" ]]; then
            log warn "No remote stdout/stderr was captured; tail of reports/cperf.log"
            tail -n 40 "$LOCAL_RUN_DIR/reports/cperf.log" || true
        fi
    fi
    exit "$exit_code"
}

usage() {
    cat <<'EOF'
Usage: run_cp_basic.sh [options]

Quick post-ssh-setup validation for Homa, TCP, and DCTCP.
This assumes node0 can already SSH to node-0..node-(N-1) and that runtime
artifacts are already present from ssh_setup.

Options:
  --seconds S           Duration for each cp_basic phase (default: 5)
  --timeout S           Timeout for the full cp_basic invocation
                        (default: auto, scaled from --seconds)
  --num-nodes N         Total nodes in the cluster (default: 5)
  --node0 HOST          SSH alias for orchestrator node (default: node0)
  --log-root DIR        Parent directory for remote logs (default: logs)
  --local-results-dir D Copy finished results from node0 to this local dir
                        (default: experiments/results)
  -h, --help            Show this help

Environment overrides:
  NODE0_ALIAS, REMOTE_REPO_DIR, NUM_NODES, RUN_SECONDS, TIMEOUT_SECONDS,
  LOG_ROOT, LOCAL_RESULTS_DIR, LINK_MBPS, HOMA_MAX_NIC_QUEUE_NS,
  HOMA_RTT_BYTES, HOMA_GRANT_INCREMENT, HOMA_MAX_GSO_SIZE
EOF
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --seconds)
            RUN_SECONDS="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT_SECONDS="$2"
            shift 2
            ;;
        --num-nodes)
            NUM_NODES="$2"
            shift 2
            ;;
        --node0)
            NODE0_ALIAS="$2"
            shift 2
            ;;
        --log-root)
            LOG_ROOT="$2"
            shift 2
            ;;
        --local-results-dir)
            LOCAL_RESULTS_DIR="$2"
            RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/basic"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

require_cmd ssh
require_cmd rsync
require_cmd date
require_cmd python3

if [[ -z "$TIMEOUT_SECONDS" ]]; then
    # cp_basic runs 18 timed phases plus substantial per-phase setup/teardown.
    TIMEOUT_SECONDS=$((RUN_SECONDS * 45 + 120))
fi

STAMP="$(date +%Y%m%d%H%M%S)"
LOG_DIR="$LOG_ROOT/cp_basic_${STAMP}"
LOCAL_RUN_DIR="$RESULTS_RUN_ROOT/$(basename "$LOG_DIR")"
mkdir -p "$RESULTS_RUN_ROOT"
trap 'on_error $?' ERR

log setup "Checking node0 runtime prerequisites on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "
    set -euo pipefail
    [[ -d $REMOTE_REPO_DIR/.git ]]
    [[ -x $REMOTE_REPO_DIR/util/cp_basic ]]
    [[ -x ~/bin/cp_node ]]
    [[ -x ~/bin/homa_prio ]]
    [[ -f ~/bin/homa.ko ]]
    [[ -f /tmp/homa_node_hosts ]]
    command -v timeout >/dev/null 2>&1
    command -v python3 >/dev/null 2>&1
"

log setup "Validating node0 SSH reachability to node-0 through node-$((NUM_NODES-1))"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail
num_nodes="$1"
for i in $(seq 0 $((num_nodes-1))); do
    ssh -o StrictHostKeyChecking=no "node-$i" hostname >/dev/null
done
EOF

log setup "Checking remote runtime prerequisites and private-network reachability"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail
num_nodes="$1"
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    ssh "$node" bash -s -- "$node" <<'INNER'
set -euo pipefail
node_name="$1"
command -v cp_node >/dev/null 2>&1
test -x ~/bin/homa_prio
test -f ~/bin/homa.ko
iface="$(ip -o -4 addr show scope global | awk '$4 ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print $2; exit}')"
if [[ -z "$iface" ]]; then
    echo "$node_name: couldn't determine private interface" >&2
    exit 1
fi
carrier="$(cat /sys/class/net/"$iface"/carrier 2>/dev/null || echo 0)"
if [[ "$carrier" != "1" ]]; then
    echo "$node_name: private interface $iface has no carrier" >&2
    exit 1
fi
if [[ "$node_name" != "node-0" ]]; then
    ping -c 1 -W 1 node-0 >/dev/null
fi
INNER
done
EOF

log setup "Refreshing Homa runtime and clearing stale benchmark processes"
ssh "$NODE0_ALIAS" bash -s -- \
    "$NUM_NODES" \
    "$LINK_MBPS" \
    "$HOMA_MAX_NIC_QUEUE_NS" \
    "$HOMA_RTT_BYTES" \
    "$HOMA_GRANT_INCREMENT" \
    "$HOMA_MAX_GSO_SIZE" <<'EOF'
set -euo pipefail
num_nodes="$1"
link_mbps="$2"
max_nic_queue_ns="$3"
rtt_bytes="$4"
grant_increment="$5"
max_gso_size="$6"

for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    ssh "$node" "
        set -euo pipefail
        iface=\$(ip -o -4 addr show scope global | awk '\$4 ~ /^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.)/ {print \$2; exit}')
        if [[ -z \$iface ]]; then
            echo '$node: unable to find private interface' >&2
            exit 1
        fi
        sudo pkill cp_node >/dev/null 2>&1 || true
        sudo pkill homa_prio >/dev/null 2>&1 || true
        sudo rmmod homa >/dev/null 2>&1 || true
        sudo insmod ~/bin/homa.ko
        sudo sysctl -w \
            net.homa.link_mbps=$link_mbps \
            net.homa.max_nic_queue_ns=$max_nic_queue_ns \
            net.homa.rtt_bytes=$rtt_bytes \
            net.homa.grant_increment=$grant_increment \
            net.homa.max_gso_size=$max_gso_size \
            net.homa.num_priorities=8 >/dev/null
        sudo sysctl -w net.core.rps_sock_flow_entries=32768 >/dev/null
        sudo ethtool -K \$iface tso on gso on gro on >/dev/null 2>&1 || true
        sudo ethtool -C \$iface adaptive-rx off rx-usecs 0 rx-frames 0 tx-usecs 0 tx-frames 0 >/dev/null 2>&1 || true
        sudo ethtool -K \$iface ntuple on >/dev/null 2>&1 || true
        if command -v cpupower >/dev/null 2>&1; then
            sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
        fi
        for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
            [[ -e \$f ]] || continue
            printf 'performance\n' | sudo tee \$f >/dev/null || true
        done
        for f in /sys/class/net/\$iface/queues/rx-*/rps_flow_cnt; do
            [[ -e \$f ]] || continue
            printf '2048\n' | sudo tee \$f >/dev/null || true
        done
        for f in /sys/class/net/\$iface/queues/rx-*/rps_cpus; do
            [[ -e \$f ]] || continue
            printf 'fffff\n' | sudo tee \$f >/dev/null || true
        done
        [[ -r /proc/net/homa_metrics ]]
    "
done
EOF

log run "Running cp_basic for Homa, TCP, and DCTCP"
BASIC_OUTPUT="$LOCAL_RUN_DIR/basic_output.txt"
mkdir -p "$LOCAL_RUN_DIR"
ssh "$NODE0_ALIAS" "bash -lc 'cd $REMOTE_REPO_DIR/util && timeout $TIMEOUT_SECONDS ./cp_basic -n $NUM_NODES -s $RUN_SECONDS --dctcp true -l $LOG_DIR'" \
    2>&1 | tee "$BASIC_OUTPUT"

log fetch "Copying cp_basic artifacts back to $LOCAL_RUN_DIR"
fetch_partial_logs
ln -sfn "$(basename "$LOCAL_RUN_DIR")" "$RESULTS_RUN_ROOT/latest"

SUMMARY_MD="$LOCAL_RUN_DIR/basic_summary.md"
if find "$LOCAL_RUN_DIR" -maxdepth 1 -name 'node-*.log' | grep -q .; then
    log report "Generating saved summary table at $SUMMARY_MD"
    python3 "$REPO_ROOT/experiments/generate_cp_basic.py" \
        "$LOCAL_RUN_DIR" \
        --output "$SUMMARY_MD" \
        --title "cp_basic Summary"

    log summary "Saved summary table"
    sed -n '/^| Metric | Homa | TCP | DCTCP |$/,/^$/p' "$SUMMARY_MD"
else
    log warn "Skipping summary generation because node-*.log files were not fetched"
    if [[ -f "$LOCAL_RUN_DIR/reports/cperf.log" ]]; then
        log warn "Tail of reports/cperf.log"
        tail -n 40 "$LOCAL_RUN_DIR/reports/cperf.log"
    fi
fi

log done "cp_basic run complete. Logs are in $LOCAL_RUN_DIR"
