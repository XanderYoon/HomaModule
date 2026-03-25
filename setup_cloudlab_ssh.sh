#!/usr/bin/env bash
set -euo pipefail

USER_NAME="ARY"
EXP_FQDN="homabaseline.gt-8803-dns-pg0.utah.cloudlab.us"
CONTROL_HOST="node0.${EXP_FQDN}"
NODES=(node1 node2 node3 node4 node5 node6 node7 node8 node9)

PUBKEY="$(ssh "${USER_NAME}@${CONTROL_HOST}" 'cat ~/.ssh/id_rsa.pub')"

for node in "${NODES[@]}"; do
    host="${node}.${EXP_FQDN}"
    echo "Installing key on ${host}"
    ssh "${USER_NAME}@${host}" \
        "mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -qxF '${PUBKEY}' ~/.ssh/authorized_keys 2>/dev/null || echo '${PUBKEY}' >> ~/.ssh/
authorized_keys && chmod 600 ~/.ssh/authorized_keys"
done

echo "Verifying from node0"
ssh "${USER_NAME}@${CONTROL_HOST}" 'ssh -o StrictHostKeyChecking=no node1 hostname'
