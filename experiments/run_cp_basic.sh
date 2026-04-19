#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NODE0_ALIAS="${NODE0_ALIAS:-node0}"
REMOTE_REPO_DIR="${REMOTE_REPO_DIR:-~/HomaModule}"
REMOTE_COMPAT_REPO_LINK="${REMOTE_COMPAT_REPO_LINK:-~/homaModule}"
START_SCRIPT="${START_SCRIPT:-start_xl170}"
NUM_NODES="${NUM_NODES:-10}"
RUN_SECONDS="${RUN_SECONDS:-5}"
LINK_MBPS="${LINK_MBPS:-25000}"
PAPER_MODE="${PAPER_MODE:-true}"
PAPER_MTU="${PAPER_MTU:-3000}"
PAPER_EXPECT_XL170="${PAPER_EXPECT_XL170:-true}"
PAPER_SWITCH_CONFIG_REQUIRED="${PAPER_SWITCH_CONFIG_REQUIRED:-false}"
PAPER_SWITCH_CONFIGURED="${PAPER_SWITCH_CONFIGURED:-false}"
PAPER_SWITCH_CONFIG_PATH="${PAPER_SWITCH_CONFIG_PATH:-$REPO_ROOT/experiments/results/paper_switch_config.txt}"
HOMA_MAX_NIC_QUEUE_NS="${HOMA_MAX_NIC_QUEUE_NS:-2000}"
HOMA_RTT_BYTES="${HOMA_RTT_BYTES:-60000}"
HOMA_GRANT_INCREMENT="${HOMA_GRANT_INCREMENT:-10000}"
HOMA_MAX_GSO_SIZE="${HOMA_MAX_GSO_SIZE:-20000}"
UNSCHED="${UNSCHED:-0}"
UNSCHED_BOOST="${UNSCHED_BOOST:-0.0}"
LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR="${LOCAL_RESULTS_DIR:-$REPO_ROOT/experiments/results}"
DCTCP="${DCTCP:-true}"
RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/basic"

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
require_cmd python3

if [[ "$PAPER_MODE" == "true" ]]; then
    mkdir -p "$(dirname "$PAPER_SWITCH_CONFIG_PATH")"
    python3 "$REPO_ROOT/cloudlab/config_switch" > "$PAPER_SWITCH_CONFIG_PATH"
    if [[ "$PAPER_SWITCH_CONFIGURED" != "true" ]]; then
        if [[ "$PAPER_SWITCH_CONFIG_REQUIRED" == "true" ]]; then
            echo "Paper switch configuration has not been acknowledged. Review $PAPER_SWITCH_CONFIG_PATH and rerun with PAPER_SWITCH_CONFIGURED=true after applying the switch config." >&2
            exit 1
        fi
        log warn "Paper switch configuration is not acknowledged; generated commands at $PAPER_SWITCH_CONFIG_PATH"
    fi
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
    need_pkgs=0
    command -v ethtool >/dev/null 2>&1 || need_pkgs=1
    command -v rsync >/dev/null 2>&1 || need_pkgs=1
    command -v python3 >/dev/null 2>&1 || need_pkgs=1
    command -v cpupower >/dev/null 2>&1 || need_pkgs=1
    if [[ \$need_pkgs -eq 1 ]]; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-numpy python3-matplotlib rsync ethtool linux-tools-common linux-tools-generic
    fi
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
    "$HOMA_GRANT_INCREMENT" "$HOMA_MAX_GSO_SIZE" "$PAPER_MODE" "$PAPER_MTU" \
    "$PAPER_EXPECT_XL170" <<'EOF'
set -euo pipefail
remote_repo_dir="$1"
start_script="$2"
num_nodes="$3"
link_mbps="$4"
max_nic_queue_ns="$5"
rtt_bytes="$6"
grant_increment="$7"
max_gso_size="$8"
paper_mode="$9"
paper_mtu="${10}"
paper_expect_xl170="${11}"
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
    ssh "$node" "
        set -euo pipefail
        need_pkgs=0
        command -v ethtool >/dev/null 2>&1 || need_pkgs=1
        command -v rsync >/dev/null 2>&1 || need_pkgs=1
        command -v python3 >/dev/null 2>&1 || need_pkgs=1
        command -v cpupower >/dev/null 2>&1 || need_pkgs=1
        if [[ \$need_pkgs -eq 1 ]]; then
            sudo apt-get update
            sudo apt-get install -y python3 rsync ethtool linux-tools-common linux-tools-generic linux-tools-\$(uname -r)
        fi
    "
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
    elif [[ "$start_script" == "start_xl170" ]]; then
        ssh "$node" bash -s -- "$link_mbps" "$max_nic_queue_ns" "$rtt_bytes" \
            "$grant_increment" "$max_gso_size" "$paper_mode" "$paper_mtu" \
            "$paper_expect_xl170" <<'INNER'
set -euo pipefail
link_mbps="$1"
max_nic_queue_ns="$2"
rtt_bytes="$3"
grant_increment="$4"
max_gso_size="$5"
paper_mode="$6"
paper_mtu="$7"
paper_expect_xl170="$8"
iface="ens1f1"

if [[ ! -d /sys/class/net/$iface ]]; then
    echo "Expected xl170 private interface $iface is missing" >&2
    exit 1
fi
if [[ "$paper_expect_xl170" == "true" ]]; then
    cpu_model="$(lscpu | awk -F: '/Model name:/ {gsub(/^ +/, "", $2); print $2; exit}')"
    nic_driver="$(ethtool -i "$iface" 2>/dev/null | awk -F: '/driver:/ {gsub(/^ +/, "", $2); print $2; exit}')"
    nic_speed="$(ethtool "$iface" 2>/dev/null | awk -F: '/Speed:/ {gsub(/^ +/, "", $2); print $2; exit}')"
    if [[ "$cpu_model" != *"E5-2640 v4"* && "$cpu_model" != *"E5-2640v4"* ]]; then
        echo "Unexpected CPU model for xl170-style run: $cpu_model" >&2
        exit 1
    fi
    if [[ "$nic_driver" != "mlx5_core" ]]; then
        echo "Unexpected NIC driver for xl170-style run: $nic_driver" >&2
        exit 1
    fi
    if [[ "$nic_speed" != "25000Mb/s" ]]; then
        echo "Unexpected NIC speed for xl170-style run: $nic_speed" >&2
        exit 1
    fi
fi

if [[ "$paper_mode" == "true" ]]; then
    sudo ip link set dev "$iface" mtu "$paper_mtu"
fi
sudo rmmod homa >/dev/null 2>&1 || true
sudo insmod ~/bin/homa.ko
sudo sysctl -w net.homa.link_mbps="$link_mbps"
sudo sysctl -w net.homa.max_nic_queue_ns="$max_nic_queue_ns"
sudo sysctl -w net.homa.rtt_bytes="$rtt_bytes"
sudo sysctl -w net.homa.grant_increment="$grant_increment"
sudo sysctl -w net.homa.max_gso_size="$max_gso_size"
sudo sysctl -w net.homa.num_priorities=8
if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi
sudo ethtool -K "$iface" tso on gso on gro on >/dev/null 2>&1 || true
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [[ -e "$f" ]] || continue
    printf 'performance\n' | sudo tee "$f" >/dev/null || true
done
rm -f ~/.homa_metrics
sudo sysctl -w net.core.rps_sock_flow_entries=32768
sudo ethtool -C "$iface" adaptive-rx off rx-usecs 5 rx-frames 1 >/dev/null 2>&1 || true
for f in /sys/class/net/"$iface"/queues/rx-*/rps_flow_cnt; do
    [[ -e "$f" ]] || continue
    printf '2048\n' | sudo tee "$f" >/dev/null || true
done
for f in /sys/class/net/"$iface"/queues/rx-*/rps_cpus; do
    [[ -e "$f" ]] || continue
    printf 'fffff\n' | sudo tee "$f" >/dev/null || true
done
sudo ethtool -K "$iface" ntuple on >/dev/null 2>&1 || true
INNER
    else
        ssh "$node" "bash -lc '~/bin/$start_script ~/bin/homa.ko'"
    fi
done
EOF

log setup "Refreshing Homa runtime on node-0 through node-9 before cp_basic"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" "$LINK_MBPS" "$HOMA_MAX_NIC_QUEUE_NS" \
    "$HOMA_RTT_BYTES" "$HOMA_GRANT_INCREMENT" "$HOMA_MAX_GSO_SIZE" \
    "$PAPER_MODE" "$PAPER_MTU" <<'EOF'
set -euo pipefail
num_nodes="$1"
link_mbps="$2"
max_nic_queue_ns="$3"
rtt_bytes="$4"
grant_increment="$5"
max_gso_size="$6"
paper_mode="$7"
paper_mtu="$8"
for i in $(seq 0 $((num_nodes-1))); do
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        ~/bin/homa.ko ~/bin/cp_node ~/bin/homa_prio ~/bin/*.py "node-$i:~/bin/"
    rsync -e 'ssh -o StrictHostKeyChecking=no' -rtv \
        /tmp/homa_node_hosts "node-$i:/tmp/homa_node_hosts"
    ssh "node-$i" "
        iface=ens1f1
        sudo pkill cp_node >/dev/null 2>&1 || true
        sudo pkill homa_prio >/dev/null 2>&1 || true
        sudo rmmod homa >/dev/null 2>&1 || true
        sudo sed -i '/ node-[0-9]\\b/d;/ node[0-9]\\b/d' /etc/hosts
        cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null
        if [[ \"$paper_mode\" == \"true\" ]] && [[ -d /sys/class/net/\$iface ]]; then
            sudo ip link set dev \$iface mtu $paper_mtu
            sudo ethtool -K \$iface tso on gso on gro on >/dev/null 2>&1 || true
        fi
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

if [[ "$START_SCRIPT" == "start_xl170" ]]; then
log setup "Reapplying xl170 host tuning on node-0 through node-9"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail
num_nodes="$1"
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    ssh "$node" bash -s <<'INNER'
set -euo pipefail
iface="ens1f1"
if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi
for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [[ -e "$f" ]] || continue
    printf 'performance\n' | sudo tee "$f" >/dev/null
done
sudo sysctl -w net.core.rps_sock_flow_entries=32768 >/dev/null
sudo ethtool -C "$iface" adaptive-rx off rx-usecs 5 rx-frames 1 >/dev/null 2>&1 || true
for f in /sys/class/net/"$iface"/queues/rx-*/rps_flow_cnt; do
    [[ -e "$f" ]] || continue
    printf '2048\n' | sudo tee "$f" >/dev/null
done
for f in /sys/class/net/"$iface"/queues/rx-*/rps_cpus; do
    [[ -e "$f" ]] || continue
    printf 'fffff\n' | sudo tee "$f" >/dev/null
done
sudo ethtool -K "$iface" ntuple on >/dev/null 2>&1 || true
INNER
done
EOF

log setup "Validating xl170 host tuning on node-0 through node-9"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" "$PAPER_MODE" "$PAPER_MTU" "$PAPER_EXPECT_XL170" <<'EOF'
set -euo pipefail
num_nodes="$1"
paper_mode="$2"
paper_mtu="$3"
paper_expect_xl170="$4"
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    ssh "$node" bash -s -- "$node" "$paper_mode" "$paper_mtu" "$paper_expect_xl170" <<'INNER'
set -euo pipefail
node_name="$1"
paper_mode="$2"
paper_mtu="$3"
paper_expect_xl170="$4"
iface="ens1f1"
if [[ ! -d /sys/class/net/$iface ]]; then
    echo "$node_name: expected interface $iface is missing" >&2
    exit 1
fi
if [[ "$paper_expect_xl170" == "true" ]]; then
    cpu_model="$(lscpu | awk -F: '/Model name:/ {gsub(/^ +/, "", $2); print $2; exit}')"
    nic_driver="$(ethtool -i "$iface" 2>/dev/null | awk -F: '/driver:/ {gsub(/^ +/, "", $2); print $2; exit}')"
    nic_speed="$(ethtool "$iface" 2>/dev/null | awk -F: '/Speed:/ {gsub(/^ +/, "", $2); print $2; exit}')"
    if [[ "$cpu_model" != *"E5-2640 v4"* && "$cpu_model" != *"E5-2640v4"* ]]; then
        echo "$node_name: unexpected CPU model '$cpu_model' for xl170-style run" >&2
        exit 1
    fi
    if [[ "$nic_driver" != "mlx5_core" ]]; then
        echo "$node_name: unexpected NIC driver '$nic_driver' for xl170-style run" >&2
        exit 1
    fi
    if [[ "$nic_speed" != "25000Mb/s" ]]; then
        echo "$node_name: NIC speed is '$nic_speed', expected 25000Mb/s" >&2
        exit 1
    fi
fi
governor="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true)"
if [[ "$governor" != "performance" ]]; then
    echo "$node_name: CPU governor is '$governor', expected 'performance'" >&2
    exit 1
fi
if [[ "$paper_mode" == "true" ]]; then
    mtu="$(ip -o link show "$iface" | awk '{for (i = 1; i <= NF; i++) if ($i == "mtu") {print $(i+1); exit}}')"
    if [[ "$mtu" != "$paper_mtu" ]]; then
        echo "$node_name: MTU is '$mtu', expected '$paper_mtu'" >&2
        exit 1
    fi
fi
rps_sock="$(sysctl -n net.core.rps_sock_flow_entries 2>/dev/null || echo 0)"
if [[ "$rps_sock" != "32768" ]]; then
    echo "$node_name: net.core.rps_sock_flow_entries=$rps_sock, expected 32768" >&2
    exit 1
fi
rx_usecs="$(ethtool -c "$iface" 2>/dev/null | awk -F: '/rx-usecs:/ {gsub(/^ +/, "", $2); print $2; exit}')"
rx_frames="$(ethtool -c "$iface" 2>/dev/null | awk -F: '/rx-frames:/ {gsub(/^ +/, "", $2); print $2; exit}')"
adaptive_rx="$(ethtool -c "$iface" 2>/dev/null | awk -F: '/Adaptive RX:/ {gsub(/^ +/, "", $2); print $2; exit}')"
if [[ "$rx_usecs" != "5" || "$rx_frames" != "1" || "$adaptive_rx" != off* ]]; then
    echo "$node_name: coalescing is Adaptive RX=$adaptive_rx rx-usecs=$rx_usecs rx-frames=$rx_frames, expected off/5/1" >&2
    exit 1
fi
ntuple="$(ethtool -k "$iface" 2>/dev/null | awk -F: '/ntuple-filters:/ {gsub(/^ +/, "", $2); print $2; exit}')"
if [[ "$ntuple" != "on" ]]; then
    echo "$node_name: ntuple-filters=$ntuple, expected on" >&2
    exit 1
fi
tso="$(ethtool -k "$iface" 2>/dev/null | awk -F: '/tcp-segmentation-offload:/ {gsub(/^ +/, "", $2); print $2; exit}')"
if [[ "$tso" != "on" ]]; then
    echo "$node_name: tcp-segmentation-offload=$tso, expected on" >&2
    exit 1
fi
for f in /sys/class/net/"$iface"/queues/rx-*/rps_flow_cnt; do
    [[ -e "$f" ]] || continue
    value="$(cat "$f")"
    if [[ "$value" != "2048" ]]; then
        echo "$node_name: $f=$value, expected 2048" >&2
        exit 1
    fi
done
for f in /sys/class/net/"$iface"/queues/rx-*/rps_cpus; do
    [[ -e "$f" ]] || continue
    value="$(cat "$f")"
    if [[ "$value" != "fffff" ]]; then
        echo "$node_name: $f=$value, expected fffff" >&2
        exit 1
    fi
done
INNER
done
EOF
fi

log run "Launching cp_basic on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "bash -lc 'cd $REMOTE_REPO_DIR/util && ./cp_basic -n $NUM_NODES -s $RUN_SECONDS --dctcp $DCTCP -l $LOG_DIR --unsched $UNSCHED --unsched-boost $UNSCHED_BOOST'"

log fetch "Copying cp_basic results back to $LOCAL_RUN_DIR"
rsync -e "ssh -o StrictHostKeyChecking=no" -rtv \
    "$NODE0_ALIAS:$REMOTE_REPO_DIR/util/$LOG_DIR/" "$LOCAL_RUN_DIR/"
ln -sfn "$(basename "$LOCAL_RUN_DIR")" "$RESULTS_RUN_ROOT/latest"

log report "Generating homa_reproduced.md from $LOCAL_RUN_DIR"
if ! python3 "$REPO_ROOT/experiments/generate_cp_basic.py" \
    "$LOCAL_RUN_DIR" \
    --output "$REPO_ROOT/homa_reproduced.md" \
    --title "Homa Reproduced" \
    --include-paper-reference \
    --paper-caption; then
    log warn "cp_basic report generation failed; benchmark artifacts were still fetched successfully"
fi

log done "cp_basic complete. Remote results are under $REMOTE_REPO_DIR/util/$LOG_DIR on $NODE0_ALIAS and local copies are under $LOCAL_RUN_DIR"
