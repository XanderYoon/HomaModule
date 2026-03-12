#!/usr/bin/env bash

set -e

CLOUDLAB_USER=$(whoami)
NODES=$(seq 0 9)

echo "====================================="
echo "CloudLab Cluster Bootstrap Starting"
echo "User: $CLOUDLAB_USER"
echo "====================================="

############################################
# 1. Install SSH client and generate key
############################################

echo "Installing SSH client..."
sudo apt install -y openssh-client

if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""
fi

KEY=$(cat ~/.ssh/id_ed25519.pub)

echo "Distributing SSH keys to nodes..."

for i in {1..9}; do
    ssh node$i "mkdir -p /users/$CLOUDLAB_USER/.ssh && echo '$KEY' >> /users/$CLOUDLAB_USER/.ssh/authorized_keys"
done

############################################
# 2. Verify SSH connectivity
############################################

echo "Verifying SSH connectivity..."

for i in $NODES; do
    ssh node$i hostname
done

echo "SSH connectivity OK."

############################################
# 3. Test LAN connectivity
############################################

echo "Testing LAN connectivity..."

for i in {1..9}; do
    ping -c 2 node$i
done

echo "LAN connectivity OK."

############################################
# 4. Install build tools
############################################

echo "Updating package lists..."

for i in $NODES; do
    ssh node$i "sudo apt update"
done

echo "Installing build tools..."

for i in $NODES; do
    ssh node$i "sudo apt install -y git make gcc g++ linux-headers-\$(uname -r)"
done

############################################
# 5. Install Homa
############################################

echo "Cloning HomaModule..."

if [ ! -d ~/HomaModule ]; then
    git clone https://github.com/PlatformLab/HomaModule.git
fi

echo "Copying HomaModule to nodes..."

for i in {1..9}; do
    scp -r ~/HomaModule node$i:~
done

############################################
# 6. Compile utilities
############################################

echo "Compiling utilities..."

cd ~/HomaModule/util
make

for i in {1..9}; do
    ssh node$i "cd ~/HomaModule/util && make"
done

############################################
# 7. Load kernel module
############################################

echo "Loading Homa kernel module..."

for i in $NODES; do
    ssh node$i "cd ~/HomaModule && sudo insmod homa.ko || true"
done

echo "Verifying module load..."

for i in $NODES; do
    ssh node$i "lsmod | grep homa || echo 'Homa not loaded on node$i'"
done

############################################
# Done
############################################

echo "====================================="
echo "Cluster bootstrap complete."
echo "====================================="
