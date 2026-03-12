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
1. SSH into Node0: Go to **Experiments** in Cloudlab, select the experiment, ssh into Node0
2. From the Node0 ssh, run `/.cluster_setup.sh` to setup the other nodes.
3. Running a workload: setup server (ssh on server node): `./cp_node server`, run client (ssh on client nodes)`client --protocol homa --first-server 0 --server-nodes 1 --workload w4`