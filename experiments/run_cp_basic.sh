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
PAPER_MTU="${PAPER_MTU:-1500}"
PAPER_EXPECT_XL170="${PAPER_EXPECT_XL170:-true}"
MGMT_IFACE="${MGMT_IFACE:-eno49}"
MGMT_MTU="${MGMT_MTU:-1500}"
PRIVATE_IFACE="${PRIVATE_IFACE:-ens1f1}"
PAPER_SWITCH_CONFIG_REQUIRED="${PAPER_SWITCH_CONFIG_REQUIRED:-false}"
PAPER_SWITCH_CONFIGURED="${PAPER_SWITCH_CONFIGURED:-false}"
PAPER_SWITCH_CONFIG_PATH="${PAPER_SWITCH_CONFIG_PATH:-$REPO_ROOT/experiments/results/paper_switch_config.txt}"

HOMA_MAX_NIC_QUEUE_NS="${HOMA_MAX_NIC_QUEUE_NS:-2000}"
HOMA_RTT_BYTES="${HOMA_RTT_BYTES:-60000}"
HOMA_GRANT_INCREMENT="${HOMA_GRANT_INCREMENT:-10000}"
HOMA_MAX_GSO_SIZE="${HOMA_MAX_GSO_SIZE:-20000}"

UNSCHED="${UNSCHED:-0}"
UNSCHED_BOOST="${UNSCHED_BOOST:-0.0}"
DCTCP="${DCTCP:-true}"

LOG_ROOT="${LOG_ROOT:-logs}"
LOCAL_RESULTS_DIR="${LOCAL_RESULTS_DIR:-$REPO_ROOT/experiments/results}"
RESULTS_RUN_ROOT="$LOCAL_RESULTS_DIR/runs/basic"

log() {
    printf '\n[%s] %s\n' "$1" "$2"
}

usage() {
    cat <<EOF
Usage:
  bash experiments/run_cp_basic.sh

Rerun:
  CLOUDLAB_USER=ARY bash experiments/run_cp_basic.sh

Later, when jumbo works end-to-end:
  PAPER_MTU=3000 CLOUDLAB_USER=ARY bash experiments/run_cp_basic.sh

Notes:
  - This script assumes ssh_setup/ssh_setup_10nodes.sh has already been run.
  - Default private experiment MTU is $PAPER_MTU on $PRIVATE_IFACE.
  - Management MTU remains $MGMT_MTU on $MGMT_IFACE.
EOF
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

if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help|help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
fi

if [[ "$PAPER_MODE" == "true" ]]; then
    mkdir -p "$(dirname "$PAPER_SWITCH_CONFIG_PATH")"
    python3 "$REPO_ROOT/cloudlab/config_switch" >"$PAPER_SWITCH_CONFIG_PATH"
    if [[ "$PAPER_SWITCH_CONFIGURED" != "true" ]]; then
        if [[ "$PAPER_SWITCH_CONFIG_REQUIRED" == "true" ]]; then
            echo "Paper switch configuration has not been acknowledged. Review $PAPER_SWITCH_CONFIG_PATH and rerun with PAPER_SWITCH_CONFIGURED=true after applying the switch config." >&2
            exit 1
        fi
        log warn "Paper switch configuration is not acknowledged; generated commands at $PAPER_SWITCH_CONFIG_PATH"
    fi
fi

log setup "Preflighting node0 bootstrap prerequisites on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "
    set -euo pipefail
    if [[ ! -d $REMOTE_REPO_DIR/.git ]]; then
        echo 'Remote repo not found at $REMOTE_REPO_DIR' >&2
        exit 1
    fi

    command -v ethtool >/dev/null 2>&1
    command -v rsync >/dev/null 2>&1
    command -v python3 >/dev/null 2>&1
    command -v cpupower >/dev/null 2>&1
    python3 -c 'import matplotlib, numpy' >/dev/null 2>&1
    test -x ~/bin/cp_node
    test -x ~/bin/homa_prio
    test -f /tmp/homa_node_hosts
    ssh -G node-1 >/dev/null
    getent hosts node-1 >/dev/null
"

log setup "Building fresh runtime artifacts on $NODE0_ALIAS"
ssh "$NODE0_ALIAS" "
    set -euo pipefail
    ln -sfn $REMOTE_REPO_DIR $REMOTE_COMPAT_REPO_LINK
    mkdir -p ~/bin

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

log setup "Loading Homa and distributing runtime artifacts on node-0 through node-9"
ssh "$NODE0_ALIAS" bash -s -- \
    "$REMOTE_REPO_DIR" \
    "$START_SCRIPT" \
    "$NUM_NODES" \
    "$LINK_MBPS" \
    "$HOMA_MAX_NIC_QUEUE_NS" \
    "$HOMA_RTT_BYTES" \
    "$HOMA_GRANT_INCREMENT" \
    "$HOMA_MAX_GSO_SIZE" \
    "$PAPER_MODE" \
    "$PAPER_MTU" \
    "$PAPER_EXPECT_XL170" \
    "$MGMT_IFACE" \
    "$MGMT_MTU" \
    "$PRIVATE_IFACE" <<'EOF'
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
mgmt_iface="${12}"
mgmt_mtu="${13}"
private_iface="${14}"

cd "$remote_repo_dir"
node0_pubkey="$(cat ~/.ssh/id_ed25519.pub)"

for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"
    echo "=== $node ==="

    ssh "$node" "
        set -euo pipefail
        mkdir -p ~/bin ~/.ssh
        chmod 700 ~/.ssh

        command -v ethtool >/dev/null 2>&1
        command -v rsync >/dev/null 2>&1
        command -v python3 >/dev/null 2>&1
        command -v cpupower >/dev/null 2>&1
        python3 -c 'import matplotlib, numpy' >/dev/null 2>&1
    "

    rsync -e 'ssh -o StrictHostKeyChecking=no' -rt \
        ~/.bashrc ~/.bash_profile "$node:"

    rsync -e 'ssh -o StrictHostKeyChecking=no' -rt \
        ~/bin/ "$node:~/bin/"

    rsync -e 'ssh -o StrictHostKeyChecking=no' -rt \
        homa.ko util/cp_node util/homa_prio util/*.py "$node:~/bin/"

    rsync -e 'ssh -o StrictHostKeyChecking=no' -rt \
        /tmp/homa_node_hosts "$node:/tmp/homa_node_hosts"

    ssh "$node" "
        set -euo pipefail
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
        grep -qxF '$node0_pubkey' ~/.ssh/authorized_keys 2>/dev/null || \
            printf '%s\n' '$node0_pubkey' >> ~/.ssh/authorized_keys

        sudo /usr/bin/install -m 755 ~/bin/cp_node /usr/bin/cp_node
        sudo /usr/bin/install -m 755 ~/bin/homa_prio /usr/bin/homa_prio
        sudo /usr/bin/install -m 755 ~/bin/*.py /usr/bin/

        sudo sed -i '/ node-[0-9]\b/d;/ node[0-9]\b/d' /etc/hosts
        cat /tmp/homa_node_hosts | sudo tee -a /etc/hosts >/dev/null
    "

    if [[ "$start_script" == "generic" ]]; then
        ssh "$node" bash -s -- "$link_mbps" "$max_nic_queue_ns" "$rtt_bytes" \
            "$grant_increment" "$max_gso_size" <<'INNER'
set -euo pipefail

link_mbps="$1"
max_nic_queue_ns="$2"
rtt_bytes="$3"
grant_increment="$4"
max_gso_size="$5"

iface="$(ip -o -4 addr show scope global | awk '$4 ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print $2; exit}')"
if [[ -z "$iface" ]]; then
    echo "Couldn't determine private interface for Homa setup" >&2
    exit 1
fi

sudo rmmod homa >/dev/null 2>&1 || true
sudo insmod ~/bin/homa.ko

sudo sysctl -w net.homa.link_mbps="$link_mbps" >/dev/null
sudo sysctl -w net.homa.max_nic_queue_ns="$max_nic_queue_ns" >/dev/null
sudo sysctl -w net.homa.rtt_bytes="$rtt_bytes" >/dev/null
sudo sysctl -w net.homa.grant_increment="$grant_increment" >/dev/null
sudo sysctl -w net.homa.max_gso_size="$max_gso_size" >/dev/null

if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi

rm -f ~/.homa_metrics
sudo sysctl -w net.core.rps_sock_flow_entries=32768 >/dev/null

if command -v ethtool >/dev/null 2>&1; then
    sudo ethtool -C "$iface" adaptive-rx off rx-usecs 0 rx-frames 0 tx-usecs 0 tx-frames 0 >/dev/null 2>&1 || true
    for f in /sys/class/net/"$iface"/queues/rx-*/rps_flow_cnt; do
        [[ -e "$f" ]] || continue
        printf '2048\n' | sudo tee "$f" >/dev/null || true
    done
    for f in /sys/class/net/"$iface"/queues/rx-*/rps_cpus; do
        [[ -e "$f" ]] || continue
        printf 'fffff\n' | sudo tee "$f" >/dev/null || true
    done
    sudo ethtool -K "$iface" ntuple on >/dev/null 2>&1 || true
fi
INNER

    elif [[ "$start_script" == "start_xl170" ]]; then
        ssh "$node" bash -s -- "$link_mbps" "$max_nic_queue_ns" "$rtt_bytes" \
            "$grant_increment" "$max_gso_size" "$paper_mode" "$paper_mtu" \
            "$paper_expect_xl170" "$mgmt_iface" "$mgmt_mtu" "$private_iface" <<'INNER'
set -euo pipefail

link_mbps="$1"
max_nic_queue_ns="$2"
rtt_bytes="$3"
grant_increment="$4"
max_gso_size="$5"
paper_mode="$6"
paper_mtu="$7"
paper_expect_xl170="$8"
mgmt_iface="$9"
mgmt_mtu="${10}"
iface="${11}"

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
    if [[ -d /sys/class/net/$mgmt_iface ]]; then
        sudo ip link set dev "$mgmt_iface" mtu "$mgmt_mtu"
    fi
    sudo ip link set dev "$iface" mtu "$paper_mtu"
fi

sudo pkill cp_node >/dev/null 2>&1 || true
sudo pkill homa_prio >/dev/null 2>&1 || true
sudo rmmod homa >/dev/null 2>&1 || true
sudo insmod ~/bin/homa.ko

sudo sysctl -w net.homa.link_mbps="$link_mbps" >/dev/null
sudo sysctl -w net.homa.max_nic_queue_ns="$max_nic_queue_ns" >/dev/null
sudo sysctl -w net.homa.rtt_bytes="$rtt_bytes" >/dev/null
sudo sysctl -w net.homa.grant_increment="$grant_increment" >/dev/null
sudo sysctl -w net.homa.max_gso_size="$max_gso_size" >/dev/null
sudo sysctl -w net.homa.num_priorities=8 >/dev/null

if command -v cpupower >/dev/null 2>&1; then
    sudo cpupower frequency-set -g performance >/dev/null 2>&1 || true
fi

sudo ethtool -K "$iface" tso on gso on gro on >/dev/null 2>&1 || true

for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [[ -e "$f" ]] || continue
    printf 'performance\n' | sudo tee "$f" >/dev/null || true
done

rm -f ~/.homa_metrics
sudo sysctl -w net.core.rps_sock_flow_entries=32768 >/dev/null

# Paper says interrupt moderation disabled.
sudo ethtool -C "$iface" adaptive-rx off rx-usecs 0 rx-frames 0 tx-usecs 0 tx-frames 0 >/dev/null 2>&1 || true

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

log setup "Validating private-network connectivity for node-0 through node-9"
ssh "$NODE0_ALIAS" bash -s -- "$NUM_NODES" <<'EOF'
set -euo pipefail

num_nodes="$1"
for i in $(seq 0 $((num_nodes-1))); do
    node="node-$i"

    ssh "$node" bash -s -- "$node" <<'INNER'
set -euo pipefail
node_name="$1"

iface="$(ip -o -4 addr show scope global | awk '$4 ~ /^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)/ {print $2; exit}')"
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
tx_usecs="$(ethtool -c "$iface" 2>/dev/null | awk -F: '/tx-usecs:/ {gsub(/^ +/, "", $2); print $2; exit}')"
tx_frames="$(ethtool -c "$iface" 2>/dev/null | awk -F: '/tx-frames:/ {gsub(/^ +/, "", $2); print $2; exit}')"
adaptive_rx="$(ethtool -c "$iface" 2>/dev/null | awk -F: '/Adaptive RX:/ {gsub(/^ +/, "", $2); print $2; exit}')"

if [[ "$rx_usecs" != "0" || "$rx_frames" != "0" || "$tx_usecs" != "0" || "$tx_frames" != "0" || "$adaptive_rx" != off* ]]; then
    echo "$node_name: coalescing is Adaptive RX=$adaptive_rx rx-usecs=$rx_usecs rx-frames=$rx_frames tx-usecs=$tx_usecs tx-frames=$tx_frames, expected disabled (0/0/0/0)" >&2
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
rsync -e "ssh -o StrictHostKeyChecking=no" -rt \
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
