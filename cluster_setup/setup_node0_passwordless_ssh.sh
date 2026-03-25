#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOSTS_FILE="${HOSTS_FILE:-$SCRIPT_DIR/hosts.txt}"
SSH_DIR="$HOME/.ssh"
KEY_FILE="${SSH_KEY_FILE:-$SSH_DIR/id_ed25519}"
REMOTE_USER="${CLOUDLAB_USER:-$(whoami)}"

if [[ ! -f "$HOSTS_FILE" ]]; then
    echo "hosts.txt not found at $HOSTS_FILE" >&2
    exit 1
fi

HOSTS=()
while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [[ -z "$line" || "$line" == \#* ]]; then
        continue
    fi
    HOSTS+=("$line")
done <"$HOSTS_FILE"

if [[ "${#HOSTS[@]}" -lt 2 ]]; then
    echo "hosts.txt must contain node0 and at least one additional node" >&2
    exit 1
fi

echo "====================================="
echo "Node0 Passwordless SSH Setup"
echo "====================================="

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$KEY_FILE" ]]; then
    echo "Creating SSH key at $KEY_FILE"
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N ""
else
    echo "Using existing SSH key at $KEY_FILE"
fi

if [[ ! -f "${KEY_FILE}.pub" ]]; then
    echo "Public key ${KEY_FILE}.pub not found" >&2
    exit 1
fi

NODE0_HOST="${HOSTS[0]}"
NODE0_SHORT="${NODE0_HOST%%.*}"
CURRENT_HOST="$(hostname -f 2>/dev/null || hostname)"
CURRENT_SHORT="$(hostname -s 2>/dev/null || hostname)"
if [[ "$CURRENT_HOST" != "$NODE0_HOST" && "$CURRENT_SHORT" != "$NODE0_SHORT" ]]; then
    echo "This script must be run on node0 so node0's SSH key is installed on the other nodes." >&2
    echo "hosts.txt node0 is $NODE0_HOST, current host is $CURRENT_HOST" >&2
    exit 1
fi

for i in "${!HOSTS[@]}"; do
    if [[ "$i" -eq 0 ]]; then
        continue
    fi

    host="${HOSTS[$i]}"
    echo "Installing node0 public key on node$i ($host)"
    ssh-copy-id -i "${KEY_FILE}.pub" -o StrictHostKeyChecking=no "$REMOTE_USER@$host"
done

echo "Passwordless SSH from node0 is configured for nodes 1 through $(( ${#HOSTS[@]} - 1 ))."
