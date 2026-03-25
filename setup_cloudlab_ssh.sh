#!/usr/bin/env bash
set -euo pipefail

USER_NAME="ARY"
EXP_FQDN="homabaseline.gt-8803-dns-pg0.utah.cloudlab.us"
CONTROL_NODE="node0"
CONTROL_HOST="${CONTROL_NODE}.${EXP_FQDN}"
REMOTE_REPO_DIR="HomaModule"
REMOTE_REPO_PATH="\$HOME/${REMOTE_REPO_DIR}"
NODES=(node1 node2 node3 node4 node5 node6 node7 node8 node9)

run_remote() {
  ssh "${USER_NAME}@${CONTROL_HOST}" "$@"
}

echo "Reading node0 public key"
PUBKEY="$(ssh "${USER_NAME}@${CONTROL_HOST}" 'cat ~/.ssh/id_rsa.pub')"

echo "Installing node0 SSH key on node1-node9"
for node in "${NODES[@]}"; do
  host="${USER_NAME}@${node}.${EXP_FQDN}"
  echo "== ${host} =="
  printf '%s\n' "${PUBKEY}" | ssh -o StrictHostKeyChecking=no "${host}" \
    'mkdir -p ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && cat >> ~/.ssh/authorized_keys && sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
done

echo "Configuring node-<n> SSH aliases on node0"
run_remote "mkdir -p ~/.ssh && cat > ~/.ssh/config <<'EOF'
Host node-0
    HostName node0
    User ${USER_NAME}
Host node-1
    HostName node1
    User ${USER_NAME}
Host node-2
    HostName node2
    User ${USER_NAME}
Host node-3
    HostName node3
    User ${USER_NAME}
Host node-4
    HostName node4
    User ${USER_NAME}
Host node-5
    HostName node5
    User ${USER_NAME}
Host node-6
    HostName node6
    User ${USER_NAME}
Host node-7
    HostName node7
    User ${USER_NAME}
Host node-8
    HostName node8
    User ${USER_NAME}
Host node-9
    HostName node9
    User ${USER_NAME}
EOF
chmod 600 ~/.ssh/config
ssh -o StrictHostKeyChecking=no node-1 hostname"

echo "Preparing node0 shell environment and helper scripts"
run_remote "mkdir -p ~/bin
cp ${REMOTE_REPO_PATH}/cloudlab/bashrc ~/.bashrc
cp ${REMOTE_REPO_PATH}/cloudlab/bash_profile ~/.bash_profile
cp ${REMOTE_REPO_PATH}/cloudlab/gdbinit ~/.gdbinit
rsync -rtv ${REMOTE_REPO_PATH}/cloudlab/bin/ ~/bin/"

echo "Installing python and cpupower prerequisites on node0"
run_remote "sudo apt update && sudo apt install -y python3-pip linux-tools-common linux-tools-\$(uname -r)"

echo "Distributing ${REMOTE_REPO_DIR} from node0 to node1-node9"
run_remote "cd ${REMOTE_REPO_PATH} && for n in ${NODES[*]}; do echo \"=== \${n} ===\"; rsync -rtv --exclude-from=rsync-exclude.txt ./ ${USER_NAME}@\${n}:~/${REMOTE_REPO_DIR}/; done"

echo "Installing ~/bin helpers on node1-node9"
run_remote "for n in ${NODES[*]}; do echo \"=== \${n} ===\"; ssh \${n} 'mkdir -p ~/bin'; rsync -rtv ${REMOTE_REPO_PATH}/cloudlab/bin/ ${USER_NAME}@\${n}:~/bin/; done"

echo "Verifying node-to-node SSH and remote files"
run_remote "ssh node-1 hostname && ssh node1 'ls ~/${REMOTE_REPO_DIR}/homa.ko ~/bin/start_xl170 ~/bin/install ~/bin/on_nodes'"

cat <<'EOF'

Bootstrap complete.

Next commands to run on node0:
  cd ~/HomaModule
  ~/bin/start_xl170 ~/HomaModule/homa.ko
  ~/bin/install 9 1

If cpupower is still missing on remote nodes, install it from node0 with:
  for n in node1 node2 node3 node4 node5 node6 node7 node8 node9; do
    ssh "$n" 'sudo apt update && sudo apt install -y linux-tools-common linux-tools-$(uname -r) python3-pip'
  done
EOF
