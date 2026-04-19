#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NODE0_ALIAS="${NODE0_ALIAS:-node0}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/HomaModule}"
REMOTE_COMPAT_REPO_LINK="${REMOTE_COMPAT_REPO_LINK:-~/homaModule}"
START_SCRIPT="${START_SCRIPT:-generic}"
NUM_NODES="${NUM_NODES:-10}"
RUN_SECONDS="${RUN_SECONDS:-10}"
LINK_MBPS="${LINK_MBPS:-25000}"
HOMA_MAX_NIC_QUEUE_NS="${HOMA_MAX_NIC_QUEUE_NS:-2000}"
HOMA_RTT_BYTES="${HOMA_RTT_BYTES:-60000}"
HOMA_GRANT_INCREMENT="${HOMA_GRANT_INCREMENT:-10000}"
HOMA_MAX_GSO_SIZE="${HOMA_MAX_GSO_SIZE:-20000}"
LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR="${LOCAL_RESULTS_DIR:-$REPO_ROOT/experiments/results}"
WORKLOAD="${WORKLOAD:-w4}"
GBPS="${GBPS:-20}"
HTTP2_SESSION_COUNTS="${HTTP2_SESSION_COUNTS:-1,2,4,8}"
RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/transport_http2_sessions"

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
LOG_DIR="$LOG_ROOT/cp_transport_http2_sessions_${WORKLOAD}_${STAMP}"
LOCAL_RUN_DIR="$RESULTS_RUN_ROOT/$(basename "$LOG_DIR")"
mkdir -p "$RESULTS_RUN_ROOT"

require_cmd ssh
require_cmd rsync
require_cmd date

PRIVATE_IP_PATTERN='^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'

log sync "Pushing updated HTTP/2 session benchmark sources to $NODE0_ALIAS"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$REPO_ROOT/util/cp_node.cc" \
    "$REPO_ROOT/util/cperf.py" \
    "$REPO_ROOT/util/cp_transport_vs_http2_sessions" \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/"

ssh "$NODE0_ALIAS" "chmod 755 $REMOTE_REPO_DIR/util/cp_transport_vs_http2_sessions"

log cleanup "Stopping stale benchmark processes on node0"
ssh "$NODE0_ALIAS" "
    set -euo pipefail
    ps -ef | awk '/[c]p_transport_vs_http2_sessions/ {print \$2}' | xargs -r kill >/dev/null 2>&1 || true
    ps -ef | awk '/[c]p_node/ {print \$2}' | xargs -r kill >/dev/null 2>&1 || true
    ps -ef | awk '/[h]oma_prio/ {print \$2}' | xargs -r sudo kill >/dev/null 2>&1 || true
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
    sudo apt-get install -y python3 python3-numpy python3-matplotlib rsync
    cd $REMOTE_REPO_DIR
    make -j
    make -C util clean
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

log setup "Validating node0 SSH to node-1 through node-$((NUM_NODES-1))"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail
num_nodes="$1"
for i in $(seq 1 $((num_nodes-1))); do
    ssh -o StrictHostKeyChecking=no "node-$i" hostname >/dev/null
done
EOF

log setup "Copying runtime files to node-0 through node-$((NUM_NODES-1)) and loading Homa with $START_SCRIPT"
ssh "$NODE0_ALIAS" bash -s -- "$REMOTE_REPO_DIR" "$START_SCRIPT" "$NUM_NODES" \
    "$LINK_MBPS" "$HOMA_MAX_NIC_QUEUE_NS" "$HOMA_RTT_BYTES" \
    "$HOMA_GRANT_INCREMENT" "$HOMA_MAX_GSO_SIZE" <<'EOF'
set -euo pipefail
remote_repo_dir="$1"
start_script="$2"
num_nodes="$3"
link_mbps_override="$4"
max_nic_queue_ns_override="$5"
rtt_bytes_override="$6"
grant_increment_override="$7"
max_gso_size_override="$8"
node0_pubkey="$(cat ~/.ssh/id_ed25519.pub)"
private_ip_pattern='^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'

cd "$remote_repo_dir"
rm -f /tmp/homa_node_hosts
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    private_ip="$(ssh "$node" "hostname -I | tr ' ' '\n' | grep -E '$private_ip_pattern' | head -n1")"
    printf '%s node-%d node%d\n' "$private_ip" "$i" "$i" >> /tmp/homa_node_hosts
done

for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv ~/.bashrc ~/.bash_profile "$node:"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv homa.ko "$node:bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv util/cp_node "$node:/tmp/cp_node"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv util/homa_prio "$node:/tmp/homa_prio"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv util/*.py "$node:/tmp/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv /tmp/homa_node_hosts "$node:/tmp/homa_node_hosts"
    ssh "$node" "/usr/bin/install -m 755 /tmp/cp_node ~/bin/cp_node && /usr/bin/install -m 755 /tmp/homa_prio ~/bin/homa_prio && /usr/bin/install -m 755 /tmp/*.py ~/bin/ && sudo /usr/bin/install -m 755 /tmp/cp_node /usr/bin/cp_node && sudo /usr/bin/install -m 755 /tmp/homa_prio /usr/bin/homa_prio && sudo /usr/bin/install -m 755 /tmp/*.py /usr/bin/"
    ssh "$node" "mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && grep -qxF '$node0_pubkey' ~/.ssh/authorized_keys 2>/dev/null || printf '%s\n' '$node0_pubkey' >> ~/.ssh/authorized_keys"
    ssh "$node" "sudo sed -i '/ node-[0-9]\\b/d;/ node[0-9]\\b/d' /etc/hosts && cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null"
    if [[ "$start_script" == "generic" ]]; then
        ssh "$node" bash -s -- "$link_mbps_override" "$max_nic_queue_ns_override" \
            "$rtt_bytes_override" "$grant_increment_override" \
            "$max_gso_size_override" <<'INNER'
set -eu
link_mbps="$1"
max_nic_queue_ns="$2"
rtt_bytes="$3"
grant_increment="$4"
max_gso_size="$5"
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
sudo rmmod homa >/dev/null 2>&1 || true
sudo insmod ~/bin/homa.ko
sudo sysctl -w net.homa.link_mbps="$link_mbps"
sudo sysctl -w net.homa.max_nic_queue_ns="$max_nic_queue_ns"
sudo sysctl -w net.homa.rtt_bytes="$rtt_bytes"
sudo sysctl -w net.homa.grant_increment="$grant_increment"
sudo sysctl -w net.homa.max_gso_size="$max_gso_size"
sudo sysctl -w net.ipv4.tcp_fastopen=0 >/dev/null
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

log setup "Refreshing Homa runtime on node-0 through node-$((NUM_NODES-1)) before HTTP/2 session benchmark"
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
            net.homa.max_gso_size=$max_gso_size \
            net.ipv4.tcp_fastopen=0 >/dev/null
    "
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
getent hosts node-0 >/dev/null
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
    ip -o -4 addr show scope global | awk -v pattern="$private_ip_pattern" '$4 ~ pattern && $2 != "lo" {print $2; exit}'
}
iface="$(resolve_cluster_iface)"
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

log run "Launching cp_transport_vs_http2_sessions on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "bash -lc 'cd $REMOTE_REPO_DIR/util && timeout 1800 ./cp_transport_vs_http2_sessions -n $NUM_NODES --servers 1 -w $WORKLOAD -b $GBPS -s $RUN_SECONDS --http2-session-counts $HTTP2_SESSION_COUNTS -l $LOG_DIR'"

log fetch "Copying HTTP/2 session benchmark results back to $LOCAL_RUN_DIR"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/$LOG_DIR/" "$LOCAL_RUN_DIR/"
ln -sfn "$(basename "$LOCAL_RUN_DIR")" "$RESULTS_RUN_ROOT/latest"

log done "HTTP/2 session benchmark complete. Remote results are under $REMOTE_REPO_DIR/util/$LOG_DIR on $NODE0_ALIAS and local copies are under $LOCAL_RUN_DIR"
