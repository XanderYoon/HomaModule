#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REMOTE_USER="${CLOUDLAB_USER:-$(whoami)}"
NODE0_ALIAS="${NODE0_ALIAS:-node0}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/HomaModule}"
REMOTE_COMPAT_REPO_LINK="${REMOTE_COMPAT_REPO_LINK:-~/homaModule}"
START_SCRIPT="${START_SCRIPT:-generic}"
NUM_NODES="${NUM_NODES:-5}"
RUN_SECONDS="${RUN_SECONDS:-10}"
LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR_DEFAULT="$REPO_ROOT/experiments/results"
LOCAL_RESULTS_DIR="$LOCAL_RESULTS_DIR_DEFAULT"
WORKLOAD=""
GBPS=""
TCP="false"
DCTCP="true"

usage() {
    cat <<'EOF'
Usage: run_cp_vs_tcp_5nodes.sh --workload WORKLOAD [options]

Required:
  --workload W          Workload for cp_vs_tcp (w1-w5 or a fixed size)

Optional:
  --gbps B              Override bandwidth for the workload
  --seconds S           Duration of each experiment phase (default: 10)
  --tcp BOOL            Run the regular TCP comparison too (default: false)
  --dctcp BOOL          Run the DCTCP comparison (default: true)
  --log-root DIR        Parent directory for cp_vs_tcp logs (default: logs)
  --start-script NAME   Remote module start script, or 'generic'
                        (default: generic)
  --local-results-dir D Copy finished results from node0 to this local dir
                        (default: experiments/results)
  --num-nodes N         Total nodes in the cluster (default: 5)
  --node0 HOST          SSH alias for orchestrator node (default: node0)

Environment overrides:
  CLOUDLAB_USER, REMOTE_REPO_DIR, REMOTE_COMPAT_REPO_LINK,
  START_SCRIPT, NUM_NODES, RUN_SECONDS, LOG_ROOT, NODE0_ALIAS

Notes:
  - Run ssh_setup_5nodes.sh first so node aliases and key-based SSH are configured.
  - This script assumes node0 is the only server and nodes 1..4 are clients.
  - The default startup path is 'generic', which discovers the active NIC
    and applies best-effort Homa setup for nodes that don't match the
    repo's xl170/m510-specific scripts.
EOF
}

log() {
    printf '\n[%s] %s\n' "$1" "$2"
}

shell_quote() {
    printf "%q" "$1"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
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
        --seconds)
            RUN_SECONDS="$2"
            shift 2
            ;;
        --tcp)
            TCP="$2"
            shift 2
            ;;
        --dctcp)
            DCTCP="$2"
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
        --start-script)
            START_SCRIPT="$2"
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

if [[ -z "$WORKLOAD" ]]; then
    echo "--workload is required" >&2
    usage
    exit 1
fi

if [[ "$NUM_NODES" -ne 5 ]]; then
    echo "This script is intended for 5 total nodes (1 server + 4 clients)." >&2
    exit 1
fi

require_cmd ssh
require_cmd rsync
require_cmd date

STAMP="$(date +%Y%m%d%H%M%S)"
LOG_DIR="$LOG_ROOT/cp_vs_tcp_${WORKLOAD}_${STAMP}"
mkdir -p "$LOCAL_RESULTS_DIR"
HOSTS_FILE="$REPO_ROOT/ssh_setup/hosts_5.txt"

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "hosts_5.txt not found at $HOSTS_FILE" >&2
    exit 1
fi

mapfile -t HOSTS < <(awk 'NF && $1 !~ /^#/' "$HOSTS_FILE")
if [[ "${#HOSTS[@]}" -ne "$NUM_NODES" ]]; then
    echo "Expected $NUM_NODES hosts in $HOSTS_FILE, found ${#HOSTS[@]}" >&2
    exit 1
fi

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
    sudo apt-get install -y python3 python3-numpy python3-matplotlib rsync
    cd $REMOTE_REPO_DIR
    make -j
    make -C util -j
    cp cloudlab/bin/* ~/bin/
    chmod +x ~/bin/*
    cp cloudlab/bashrc ~/.bashrc
    cp cloudlab/bash_profile ~/.bash_profile
"

log setup "Copying runtime files to node-0 through node-9 and loading Homa with $START_SCRIPT"
ssh "$NODE0_ALIAS" bash -s -- "$REMOTE_REPO_DIR" "$START_SCRIPT" "$NUM_NODES" <<'EOF'
set -euo pipefail
remote_repo_dir="$1"
start_script="$2"
num_nodes="$3"
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
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv ~/.bashrc ~/.bash_profile "$node:"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv ~/bin/ "$node:bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        homa.ko util/cp_node util/homa_prio util/*.py "$node:bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv /tmp/homa_node_hosts "$node:/tmp/homa_node_hosts"
    ssh "$node" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -qxF '$node0_pubkey' ~/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$node0_pubkey' >> ~/.ssh/authorized_keys"
    ssh "$node" "sudo sed -i '/ node-[0-9]\\b/d;/ node[0-9]\\b/d' /etc/hosts && cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null"
    if [[ "$start_script" == "generic" ]]; then
        ssh "$node" bash -s <<'INNER'
set -eu
iface=$(ip -o -4 addr show scope global | awk '$4 ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print $2; exit}')
if [[ -z "$iface" ]]; then
    echo "Couldn't determine private interface for Homa setup" >&2
    exit 1
fi
sudo rmmod homa >/dev/null 2>&1 || true
sudo insmod ~/bin/homa.ko
sudo sysctl -w net.homa.link_mbps=9500
sudo sysctl -w net.homa.max_nic_queue_ns=10000
sudo sysctl -w net.homa.rtt_bytes=70000
sudo sysctl -w net.homa.grant_increment=10000
sudo sysctl -w net.homa.max_gso_size=20000
if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi
rm -f ~/.homa_metrics
sudo sysctl -w net.core.rps_sock_flow_entries=32768
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
    else
        ssh "$node" "$start_script ~/bin/homa.ko"
    fi
done
EOF

CP_VS_TCP_CMD="./cp_vs_tcp -n $NUM_NODES --servers 1 --tcp $TCP --dctcp $DCTCP -w $WORKLOAD -s $RUN_SECONDS -l $LOG_DIR"
if [[ -n "$GBPS" ]]; then
    CP_VS_TCP_CMD+=" -b $GBPS"
fi

log run "Launching cp_vs_tcp on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "bash -lc 'cd $REMOTE_REPO_DIR/util && $CP_VS_TCP_CMD'"

log fetch "Copying results back to $LOCAL_RESULTS_DIR"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/$LOG_DIR/" "$LOCAL_RESULTS_DIR/"

log done "Benchmark complete. Remote results are under $REMOTE_REPO_DIR/util/$LOG_DIR on $NODE0_ALIAS and local copies are under $LOCAL_RESULTS_DIR/$(basename "$LOG_DIR")"
