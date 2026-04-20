#!/usr/bin/env bash
set -euo pipefail

: "${BENCH_SCRIPT:?}"
: "${BENCH_LABEL:?}"
: "${RESULT_SUBDIR:?}"
: "${LOG_PREFIX:?}"
: "${VARIANT_FLAG:?}"
: "${VARIANT_VALUE:?}"
: "${VARIANT_HELP_NAME:?}"
: "${VARIANT_HELP_TEXT:?}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_USER="${CLOUDLAB_USER:-$(whoami)}"
NODE0_ALIAS="${NODE0_ALIAS:-node0}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/HomaModule}"
REMOTE_COMPAT_REPO_LINK="${REMOTE_COMPAT_REPO_LINK:-~/homaModule}"
NUM_NODES="${NUM_NODES:-10}"
RUN_SECONDS="${RUN_SECONDS:-10}"
SECONDS_MULTIPLIER="${SECONDS_MULTIPLIER:-1}"
CLIENT_MAX="${CLIENT_MAX:-200}"
CLIENT_PORTS="${CLIENT_PORTS:-3}"
PORT_RECEIVERS="${PORT_RECEIVERS:-3}"
PORT_THREADS="${PORT_THREADS:-3}"
SERVER_PORTS="${SERVER_PORTS:-3}"
TCP_CLIENT_PORTS="${TCP_CLIENT_PORTS:-4}"
TCP_PORT_RECEIVERS="${TCP_PORT_RECEIVERS:-1}"
TCP_SERVER_PORTS="${TCP_SERVER_PORTS:-8}"
TCP_PORT_THREADS="${TCP_PORT_THREADS:-1}"
UNSCHED="${UNSCHED:-0}"
UNSCHED_BOOST="${UNSCHED_BOOST:-0.0}"
LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR_DEFAULT="$REPO_ROOT/experiments/results"
LOCAL_RESULTS_DIR="$LOCAL_RESULTS_DIR_DEFAULT"
WORKLOAD="${WORKLOAD:-w4}"
GBPS="${GBPS:-20}"
SERVER_COUNT="${SERVER_COUNT:-1}"
RESULTS_RUN_ROOT=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Optional:
  --workload W          Workload for ${BENCH_SCRIPT} (w1-w5 or a fixed size);
                        empty means run the built-in workload set
  --gbps B              Override bandwidth for the workload
  --servers N           Layout: 0 means all nodes act as both clients
                        and servers, 1 gives 1 server + 9 clients in the
                        default 10-node setup (default: 1)
  --seconds S           Duration of each experiment phase (default: 10)
  --seconds-multiplier M  Scale the run duration by this factor (default: 1)
  --client-max N        Maximum outstanding RPCs per client machine
  --client-ports N      Homa client ports baseline parameter
  --port-receivers N    Homa receiver threads baseline parameter
  --port-threads N      Homa server threads baseline parameter
  --server-ports N      Homa server ports baseline parameter
  --tcp-client-ports N  Baseline TCP client ports
  --tcp-port-receivers N  Baseline TCP receiver threads
  --tcp-server-ports N  Baseline TCP server ports
  --tcp-port-threads N  Baseline TCP server threads
  --unsched N           Preserve run_baselines CLI compatibility
  --unsched-boost F     Preserve run_baselines CLI compatibility
  --log-root DIR        Parent directory for benchmark logs (default: logs)
  --local-results-dir D Copy finished results from node0 to this local dir
                        (default: experiments/results)
  --num-nodes N         Total nodes in the cluster (default: 10)
  --node0 HOST          SSH alias for orchestrator node (default: node0)
  ${VARIANT_FLAG} V     ${VARIANT_HELP_TEXT}
EOF
}

log() {
    printf '\n[%s] %s\n' "$1" "$2"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

normalize_workload() {
    local workload="$1"
    case "${workload,,}" in
        w[1-5])
            printf '%s' "${workload,,}"
            ;;
        *)
            printf '%s' "$workload"
            ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --workload)
            WORKLOAD="$2"
            shift 2
            ;;
        --gbps)
            GBPS="$2"
            shift 2
            ;;
        --servers)
            SERVER_COUNT="$2"
            shift 2
            ;;
        --seconds)
            RUN_SECONDS="$2"
            shift 2
            ;;
        --seconds-multiplier)
            SECONDS_MULTIPLIER="$2"
            shift 2
            ;;
        --client-max)
            CLIENT_MAX="$2"
            shift 2
            ;;
        --client-ports)
            CLIENT_PORTS="$2"
            shift 2
            ;;
        --port-receivers)
            PORT_RECEIVERS="$2"
            shift 2
            ;;
        --port-threads)
            PORT_THREADS="$2"
            shift 2
            ;;
        --server-ports)
            SERVER_PORTS="$2"
            shift 2
            ;;
        --tcp-client-ports)
            TCP_CLIENT_PORTS="$2"
            shift 2
            ;;
        --tcp-port-receivers)
            TCP_PORT_RECEIVERS="$2"
            shift 2
            ;;
        --tcp-server-ports)
            TCP_SERVER_PORTS="$2"
            shift 2
            ;;
        --tcp-port-threads)
            TCP_PORT_THREADS="$2"
            shift 2
            ;;
        --unsched)
            UNSCHED="$2"
            shift 2
            ;;
        --unsched-boost)
            UNSCHED_BOOST="$2"
            shift 2
            ;;
        --log-root)
            LOG_ROOT="$2"
            shift 2
            ;;
        --local-results-dir)
            LOCAL_RESULTS_DIR="$2"
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
        "${VARIANT_FLAG}")
            VARIANT_VALUE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            exit 1
            ;;
    esac
done

if [[ -n "$WORKLOAD" ]]; then
    WORKLOAD="$(normalize_workload "$WORKLOAD")"
fi

if (( NUM_NODES < 2 )); then
    echo "--num-nodes must be at least 2" >&2
    exit 1
fi

if (( SERVER_COUNT < 0 || SERVER_COUNT >= NUM_NODES )); then
    echo "--servers must be between 0 and $((NUM_NODES-1))" >&2
    exit 1
fi

require_cmd ssh
require_cmd rsync
require_cmd date

STAMP="$(date +%Y%m%d%H%M%S)"
TOPOLOGY_TAG="allnodes"
if (( SERVER_COUNT > 0 )); then
    TOPOLOGY_TAG="servers${SERVER_COUNT}"
fi
WORKLOAD_TAG="${WORKLOAD:-allworkloads}"
LOG_DIR="$LOG_ROOT/${LOG_PREFIX}_${TOPOLOGY_TAG}_${WORKLOAD_TAG}_${STAMP}"
RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/$RESULT_SUBDIR"
LOCAL_RUN_DIR="$RESULTS_RUN_ROOT/$(basename "$LOG_DIR")"
mkdir -p "$RESULTS_RUN_ROOT"

log sync "Pushing updated ${BENCH_LABEL} sources to $NODE0_ALIAS"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$REPO_ROOT/util/cp_node.cc" \
    "$REPO_ROOT/util/cperf.py" \
    "$REPO_ROOT/util/$BENCH_SCRIPT" \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/"

ssh "$NODE0_ALIAS" "chmod 755 $REMOTE_REPO_DIR/util/$BENCH_SCRIPT"

log cleanup "Stopping stale benchmark processes on node0"
ssh "$NODE0_ALIAS" "
    set -euo pipefail
    pkill -f '$BENCH_SCRIPT' >/dev/null 2>&1 || true
    ps -ef | awk '/[c]p_node/ {print \$2}' | xargs -r kill >/dev/null 2>&1 || true
"

log setup "Preparing node0 build and runtime environment on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "
    set -euo pipefail
    if [[ ! -d $REMOTE_REPO_DIR/.git ]]; then
        echo 'Remote repo not found at $REMOTE_REPO_DIR' >&2
        exit 1
    fi
    ln -sfn $REMOTE_REPO_DIR $REMOTE_COMPAT_REPO_LINK
    mkdir -p ~/bin ~/.ssh
    chmod 700 ~/.ssh
    if [[ ! -f ~/.ssh/id_ed25519 ]]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ''
    fi
    grep -qxF \"\$(cat ~/.ssh/id_ed25519.pub)\" ~/.ssh/authorized_keys 2>/dev/null || \
        cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    sudo apt-get update
    sudo apt-get install -y python3 python3-numpy python3-matplotlib rsync ethtool linux-tools-common linux-tools-generic
    cd $REMOTE_REPO_DIR
    make -C util clean
    make -C util -j
    /usr/bin/install -m 755 $REMOTE_REPO_DIR/util/cp_node ~/bin/cp_node
    /usr/bin/install -m 755 $REMOTE_REPO_DIR/util/*.py ~/bin/
    chmod +x ~/bin/*
    cp cloudlab/bashrc ~/.bashrc
    cp cloudlab/bash_profile ~/.bash_profile
"

log setup "Authorizing node0 SSH key on node1 through node$((NUM_NODES-1))"
NODE0_PUBKEY="$(ssh "$NODE0_ALIAS" "cat ~/.ssh/id_ed25519.pub")"
for i in $(seq 1 $((NUM_NODES-1))); do
    ssh "node$i" "
        set -euo pipefail
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        grep -qxF '$NODE0_PUBKEY' ~/.ssh/authorized_keys 2>/dev/null || \
            printf '%s\n' '$NODE0_PUBKEY' >> ~/.ssh/authorized_keys
    "
done

log setup "Copying runtime files to node-0 through node-$((NUM_NODES-1))"
ssh "$NODE0_ALIAS" bash -s -- "$REMOTE_REPO_DIR" "$NUM_NODES" <<'EOF'
set -euo pipefail
remote_repo_dir="$1"
num_nodes="$2"
node0_pubkey="$(cat ~/.ssh/id_ed25519.pub)"
private_ip_pattern='^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'

cd "$remote_repo_dir"
rm -f /tmp/homa_node_hosts
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    private_ip="$(ssh "$node" "hostname -I | tr ' ' '\n' | grep -E '$private_ip_pattern' | head -n1")"
    if [[ -z "$private_ip" ]]; then
        echo "Couldn't determine private IPv4 address for $node" >&2
        exit 1
    fi
    printf '%s node-%d node%d\n' "$private_ip" "$i" "$i" >> /tmp/homa_node_hosts
done

for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    echo "=== $node ==="
    ssh "$node" "mkdir -p ~/bin ~/.ssh"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv ~/.bashrc ~/.bash_profile "$node:"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        util/cp_node util/*.py "$node:/tmp/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        /tmp/homa_node_hosts "$node:/tmp/homa_node_hosts"
    ssh "$node" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -qxF '$node0_pubkey' ~/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$node0_pubkey' >> ~/.ssh/authorized_keys"
    ssh "$node" "/usr/bin/install -m 755 /tmp/cp_node ~/bin/cp_node && /usr/bin/install -m 755 /tmp/*.py ~/bin/ && sudo /usr/bin/install -m 755 /tmp/cp_node /usr/bin/cp_node && sudo /usr/bin/install -m 755 /tmp/*.py /usr/bin/"
    ssh "$node" "sudo pkill cp_node >/dev/null 2>&1 || true; sudo sed -i '/ node-[0-9]\\b/d;/ node[0-9]\\b/d' /etc/hosts; cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null"
    ssh "$node" bash -s <<'INNER'
set -euo pipefail
resolve_cluster_iface() {
    local iface=""
    local peer_ip=""
    for host in node-1 node-0; do
        peer_ip="$(getent ahostsv4 "$host" 2>/dev/null | awk '!seen[$1]++ {print $1; exit}')"
        [[ -n "$peer_ip" ]] || continue
        iface="$(ip -o route get "$peer_ip" 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "dev") {print $(i+1); exit}}')"
        if [[ -n "$iface" && "$iface" != "lo" && -e /sys/class/net/"$iface" ]]; then
            echo "$iface"
            return 0
        fi
    done
    ip -o -4 addr show scope global | awk '$4 ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ && $2 != "lo" {print $2; exit}'
}
iface="$(resolve_cluster_iface)"
if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi
sudo sysctl -w net.ipv4.tcp_fastopen=0 >/dev/null
sudo sysctl -w net.core.rps_sock_flow_entries=32768 >/dev/null
if command -v ethtool >/dev/null 2>&1 && [[ -n "$iface" ]]; then
    sudo ethtool -C "$iface" adaptive-rx off rx-usecs 0 rx-frames 1 >/dev/null 2>&1 || true
    for f in /sys/class/net/"$iface"/queues/rx-*/rps_flow_cnt; do
        [[ -e "$f" ]] || continue
        printf '2048\n' | sudo tee "$f" >/dev/null || true
    done
    for f in /sys/class/net/"$iface"/queues/rx-*/rps_cpus; do
        [[ -e "$f" ]] || continue
        printf 'ffff\n' | sudo tee "$f" >/dev/null || true
    done
    sudo ethtool -K "$iface" ntuple on >/dev/null 2>&1 || true
fi
INNER
done
EOF

log setup "Validating node-<id> host resolution and private-network reachability"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail
num_nodes="$1"
private_ip_pattern='^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    getent hosts "$node" >/dev/null
    ssh "$node" "bash -s -- $(printf '%q' "$node") $(printf '%q' "$private_ip_pattern")" <<'INNER'
set -euo pipefail
node_name="$1"
private_ip_pattern="$2"
iface="$(ip -o -4 addr show scope global | awk -v pattern="$private_ip_pattern" '$4 ~ pattern && $2 != "lo" {print $2; exit}')"
if [[ -z "$iface" ]]; then
    echo "$node_name: couldn't determine private interface" >&2
    exit 1
fi
if [[ "$node_name" != "node-0" ]]; then
    ping -c 1 -W 1 node-0 >/dev/null
fi
INNER
done
EOF

EFFECTIVE_SECONDS=$(awk "BEGIN { s = int($RUN_SECONDS * $SECONDS_MULTIPLIER); print (s < 1 ? 1 : s) }")
CP_CMD="./$BENCH_SCRIPT -n $NUM_NODES --servers $SERVER_COUNT -b $GBPS -s $EFFECTIVE_SECONDS -l $LOG_DIR --client-max $CLIENT_MAX --client-ports $CLIENT_PORTS --port-receivers $PORT_RECEIVERS --port-threads $PORT_THREADS --server-ports $SERVER_PORTS --tcp-client-ports $TCP_CLIENT_PORTS --tcp-port-receivers $TCP_PORT_RECEIVERS --tcp-server-ports $TCP_SERVER_PORTS --tcp-port-threads $TCP_PORT_THREADS --unsched $UNSCHED --unsched-boost $UNSCHED_BOOST $VARIANT_FLAG $VARIANT_VALUE"
if [[ -n "$WORKLOAD" ]]; then
    CP_CMD+=" -w $WORKLOAD"
fi

log run "Launching $BENCH_SCRIPT on $NODE0_ALIAS with --servers $SERVER_COUNT"
ssh "$NODE0_ALIAS" "bash -lc 'cd $REMOTE_REPO_DIR/util && timeout 1800 $CP_CMD'"

log fetch "Copying results back to $LOCAL_RUN_DIR"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/$LOG_DIR/" "$LOCAL_RUN_DIR/"
ln -sfn "$(basename "$LOCAL_RUN_DIR")" "$RESULTS_RUN_ROOT/latest"

log done "${BENCH_LABEL} complete. Remote results are under $REMOTE_REPO_DIR/util/$LOG_DIR on $NODE0_ALIAS and local copies are under $LOCAL_RUN_DIR"
