#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NODE0_ALIAS="${NODE0_ALIAS:-node0}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/HomaModule}"
REMOTE_COMPAT_REPO_LINK="${REMOTE_COMPAT_REPO_LINK:-~/homaModule}"
START_SCRIPT="${START_SCRIPT:-generic}"
NUM_NODES="${NUM_NODES:-10}"
RUN_SECONDS="${RUN_SECONDS:-5}"
LINK_MBPS="${LINK_MBPS:-25000}"
HOMA_MAX_NIC_QUEUE_NS="${HOMA_MAX_NIC_QUEUE_NS:-2000}"
HOMA_RTT_BYTES="${HOMA_RTT_BYTES:-60000}"
HOMA_GRANT_INCREMENT="${HOMA_GRANT_INCREMENT:-10000}"
HOMA_MAX_GSO_SIZE="${HOMA_MAX_GSO_SIZE:-20000}"
LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR="${LOCAL_RESULTS_DIR:-$REPO_ROOT/experiments/results}"
DCTCP="${DCTCP:-true}"
RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/baseline"

log() {
    printf '\n[%s] %s\n' "$1" "$2"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

STAMP="$(date +%Y%m%d%H%M%S)"
LOG_DIR="$LOG_ROOT/cp_basic_${STAMP}"
LOCAL_RUN_DIR="$RESULTS_RUN_ROOT/$(basename "$LOG_DIR")"
mkdir -p "$RESULTS_RUN_ROOT"

require_cmd ssh
require_cmd rsync
require_cmd date

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
    /usr/bin/install -m 755 $REMOTE_REPO_DIR/homa.ko ~/bin/homa.ko
    /usr/bin/install -m 755 $REMOTE_REPO_DIR/util/cp_node ~/bin/cp_node
    /usr/bin/install -m 755 $REMOTE_REPO_DIR/util/homa_prio ~/bin/homa_prio
    /usr/bin/install -m 755 $REMOTE_REPO_DIR/util/*.py ~/bin/
    chmod +x ~/bin/*
    cp cloudlab/bashrc ~/.bashrc
    cp cloudlab/bash_profile ~/.bash_profile
"

log setup "Authorizing node0 SSH key on node1 through node9"
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

log setup "Loading Homa on node-0 through node-9 for cp_basic"
ssh "$NODE0_ALIAS" bash -s -- "$REMOTE_REPO_DIR" "$START_SCRIPT" "$NUM_NODES" \
    "$LINK_MBPS" "$HOMA_MAX_NIC_QUEUE_NS" "$HOMA_RTT_BYTES" \
    "$HOMA_GRANT_INCREMENT" "$HOMA_MAX_GSO_SIZE" <<'EOF'
set -euo pipefail
remote_repo_dir="$1"
start_script="$2"
num_nodes="$3"
link_mbps="$4"
max_nic_queue_ns="$5"
rtt_bytes="$6"
grant_increment="$7"
max_gso_size="$8"
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
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv ~/bin/ "$node:~/bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        homa.ko util/cp_node util/homa_prio util/*.py "$node:~/bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv /tmp/homa_node_hosts "$node:/tmp/homa_node_hosts"
    ssh "$node" "sudo /usr/bin/install -m 755 ~/bin/cp_node /usr/bin/cp_node && sudo /usr/bin/install -m 755 ~/bin/homa_prio /usr/bin/homa_prio && sudo /usr/bin/install -m 755 ~/bin/*.py /usr/bin/"
    ssh "$node" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -qxF '$node0_pubkey' ~/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$node0_pubkey' >> ~/.ssh/authorized_keys"
    ssh "$node" "sudo sed -i '/ node-[0-9]\\b/d;/ node[0-9]\\b/d' /etc/hosts && cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null"

    if [[ "$start_script" == "generic" ]]; then
        ssh "$node" bash -s -- "$link_mbps" "$max_nic_queue_ns" "$rtt_bytes" \
            "$grant_increment" "$max_gso_size" <<'INNER'
set -eu
link_mbps="$1"
max_nic_queue_ns="$2"
rtt_bytes="$3"
grant_increment="$4"
max_gso_size="$5"
iface=$(ip -o -4 addr show scope global | awk '$4 ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print $2; exit}')
if [[ -z "$iface" ]]; then
    echo "Couldn't determine private interface for Homa setup" >&2
    exit 1
fi
sudo rmmod homa >/dev/null 2>&1 || true
sudo insmod ~/bin/homa.ko
sudo sysctl -w net.homa.link_mbps="$link_mbps"
sudo sysctl -w net.homa.max_nic_queue_ns="$max_nic_queue_ns"
sudo sysctl -w net.homa.rtt_bytes="$rtt_bytes"
sudo sysctl -w net.homa.grant_increment="$grant_increment"
sudo sysctl -w net.homa.max_gso_size="$max_gso_size"
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
    fi
done
EOF

log setup "Refreshing Homa runtime on node-0 through node-9 before cp_basic"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" "$LINK_MBPS" "$HOMA_MAX_NIC_QUEUE_NS" \
    "$HOMA_RTT_BYTES" "$HOMA_GRANT_INCREMENT" "$HOMA_MAX_GSO_SIZE" <<'EOF'
set -euo pipefail
num_nodes="$1"
link_mbps="$2"
max_nic_queue_ns="$3"
rtt_bytes="$4"
grant_increment="$5"
max_gso_size="$6"
for i in $(seq 0 $((num_nodes-1))); do
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        ~/bin/homa.ko ~/bin/cp_node ~/bin/homa_prio ~/bin/*.py "node-$i:~/bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        /tmp/homa_node_hosts "node-$i:/tmp/homa_node_hosts"
    ssh "node-$i" "
        sudo pkill cp_node >/dev/null 2>&1 || true
        sudo pkill homa_prio >/dev/null 2>&1 || true
        sudo rmmod homa >/dev/null 2>&1 || true
        sudo sed -i '/ node-[0-9]\\b/d;/ node[0-9]\\b/d' /etc/hosts
        cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null
        sudo insmod ~/bin/homa.ko
        sudo /usr/bin/install -m 755 ~/bin/cp_node /usr/bin/cp_node
        sudo /usr/bin/install -m 755 ~/bin/homa_prio /usr/bin/homa_prio
        sudo /usr/bin/install -m 755 ~/bin/*.py /usr/bin/
        sudo sysctl -w net.homa.link_mbps=$link_mbps \
            net.homa.max_nic_queue_ns=$max_nic_queue_ns \
            net.homa.rtt_bytes=$rtt_bytes \
            net.homa.grant_increment=$grant_increment \
            net.homa.max_gso_size=$max_gso_size >/dev/null
    "
done
EOF

log setup "Validating private-network connectivity for node-0 through node-9"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail
num_nodes="$1"
private_ip_pattern='^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    ssh "$node" "bash -s -- $(printf '%q' "$node") $(printf '%q' "$private_ip_pattern")" <<'INNER'
set -euo pipefail
node_name="$1"
private_ip_pattern="$2"
iface="$(ip -o -4 addr show scope global | awk -v pattern="$private_ip_pattern" '$4 ~ pattern {print $2; exit}')"
if [[ -z "$iface" ]]; then
    echo "$node_name: couldn't determine private interface" >&2
    exit 1
fi
carrier="$(cat /sys/class/net/"$iface"/carrier 2>/dev/null || echo 0)"
operstate="$(cat /sys/class/net/"$iface"/operstate 2>/dev/null || echo unknown)"
if [[ "$carrier" != "1" ]]; then
    echo "$node_name: private interface $iface has no carrier (operstate=$operstate)" >&2
    exit 1
fi
if [[ "$node_name" != "node-0" ]]; then
    ping -c 1 -W 1 node-0 >/dev/null
fi
INNER
    if [[ "$node" != "node-0" ]]; then
        ping -c 1 -W 1 "$node" >/dev/null
    fi
done
EOF

log run "Launching cp_basic on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "bash -lc 'cd $REMOTE_REPO_DIR/util && ./cp_basic -n $NUM_NODES -s $RUN_SECONDS --dctcp $DCTCP -l $LOG_DIR'"

log fetch "Copying cp_basic results back to $LOCAL_RUN_DIR"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/$LOG_DIR/" "$LOCAL_RUN_DIR/"
ln -sfn "$(basename "$LOCAL_RUN_DIR")" "$RESULTS_RUN_ROOT/latest"

log done "cp_basic complete. Remote results are under $REMOTE_REPO_DIR/util/$LOG_DIR on $NODE0_ALIAS and local copies are under $LOCAL_RUN_DIR"
