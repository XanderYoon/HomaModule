# One time setup
## 1. Create a experiment Profile 
Create an Rspec file (already done and shouldn't need replication)

## 2. Create a experiment using the profile
Create an experiment from the configured profile (already done and shouldn't need replication). 

## 3. Create and attach ssh keys to your CloudLab Account
For MAC / Unix:
1. `cd ~/.ssh`
2. `ssh-keygen -t ed25519`
3. ``` 
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/<ssh_key_file>
    chmod 644 ~/.ssh/<ssh_key_file>.pub
    ```
4. `ssh-add ~/.ssh/<ssh_key_file>`, verify with `ssh-add -l`
5. Add `~/.ssh/<ssh_key_file>.pub` to CloudLab profile

# Homa Install
Needs to be done everytime you start a experiment
## 1. SSH into Node0 (sender)
1. Go to **Experiments** in Cloudlab and select the experiment
2. You should be able to click the ssh for each node, open in terminal, and be connected.

## 2. Enable node-to-node SSH
1. ```
    sudo apt install -y openssh-client

    ssh-keygen -t ed25519
    KEY=$(cat ~/.ssh/id_ed25519.pub)

    for i in {1..9}; do
    sudo ssh node$i "mkdir -p /users/<Cloudlab Username>/.ssh && echo '$KEY' >> /users/<Cloudlab Username>/.ssh/authorized_keys"
    done
    ```
2. Veryify:
    ```
    for i in {0..9}; do
        ssh node$i hostname
    done
    ```
    Should see:
    ```
    node1.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node2.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node3.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node4.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node5.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node6.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node7.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node8.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    node9.<experiment name>.gt-8803-dns-pg0.utah.cloudlab.us
    ```

    Test LAN:
    ```
    for i in {1..9}; do
        ping -c 2 node$i
    done
    ```

## 3. Install build tools
From node 0:

1. 
    ```
    for i in {0..9}; do
        ssh node$i "sudo apt update"
    done
    ```
2. 
    ```
    for i in {0..9}; do
    ssh node$i "sudo apt install -y git make gcc g++ linux-headers-\$(uname -r)"
    done
    ```

## 4.
1. Install Homa: `git clone git clone -b linux_5.4.80 --single-branch git@github.com:XanderYoon/HomaModule.git`
2. 
    ```
    for i in {1..9}; do
    scp -r HomaModule node$i:~
    done
    ```
3.  `cd ~/HomaModule/util && make &&