# Experiments Guide

This directory contains the cluster benchmark wrappers and post-processing used to run Homa-vs-TCP style experiments on a CloudLab-style testbed.

This file is intentionally detailed. It is meant to answer:
- what each experiment script does
- what assumptions it makes about the cluster
- how the setup is pushed to nodes
- where failures usually happen
- what output files are generated
- how to rerun experiments safely

## Scope

This directory currently contains:
- `run_cp_basic_5nodes.sh`
- `run_cp_basic.sh`
- `run_cp_transport_basic.sh`
- `run_cp_vs_tcp_5nodes.sh`
- `run_cp_transport_vs_dctcp.sh`
- `run_cp_vs_tcp_10nodes.sh`
- `tuning/run_http2_tuning.sh`
- `tuning/run_connection_pooling_tuning.sh`
- `tuning/run_static_offset_tuning.sh`
- `run_dctcp_tuning.sh`
- `analyze_cp_vs_tcp_runs.py`
- `results/`

The scripts here are wrappers around the benchmark drivers in `util/`, especially:
- `util/cp_basic`
- `util/cp_transport_basic`
- `util/cp_vs_tcp`
- `util/cp_transport_vs_dctcp`
- `util/cp_transport_vs_http2_sessions`
- `util/cp_transport_vs_connection_pools`
- `util/cp_transport_vs_static_offsets`
- `util/cperf.py`
- `util/cp_node`
- `util/homa_prio`

The transport-only DCTCP tuning wrappers live under `experiments/tuning/`.
Their shared setup helper is `experiments/run_dctcp_tuning.sh`.

The wrappers exist because the raw `util/` drivers assume a working cluster environment with:
- SSH aliases like `node-0`, `node-1`, ...
- `cp_node` available on every machine
- `homa_prio` available on every machine
- `homa.ko` present on every machine
- `/etc/hosts` entries for `node-<id>` naming
- Homa loaded and configured on every machine

The experiment wrappers are responsible for creating that environment from `node0`.

## Cluster Model

### 5-node topology

The 5-node scripts assume:
- `node0` is the orchestrator machine
- `node-0` is also the benchmark server when `--servers 1` is used
- `node-1` through `node-4` are benchmark clients

Practical mapping:
- SSH alias from the local workstation: `node0`, `node1`, `node2`, `node3`, `node4`
- SSH alias inside the cluster and inside `cperf`: `node-0`, `node-1`, `node-2`, `node-3`, `node-4`

That distinction matters because `cperf.py` launches nodes with commands like:
- `ssh node-1 cp_node`

If only `node1` works and `node-1` does not, the experiments fail.

### 10-node topology

The 10-node script assumes:
- `node0` is the orchestrator
- `node-0` is the benchmark server
- `node-1` through `node-9` are clients

The 10-node script was the known-good reference when the 5-node wrappers were debugged.

## High-Level Experiment Flow

All wrappers follow the same broad sequence:

1. Check that `node0` is reachable and the remote repo exists.
2. Build the kernel module and utility binaries on `node0`.
3. Make sure `node0` has an SSH key and that peers trust it.
4. Push runtime files from `node0` to every test node.
5. Generate `/tmp/homa_node_hosts` and append `node-<id>` aliases to `/etc/hosts` on every test node.
6. Load `homa.ko` and apply Homa sysctls on every test node.
7. Run the benchmark driver from `node0`.
8. Copy the generated log directory back into `experiments/results/`.

## Important Design Details

### Why the 5-node wrappers were changed

The original 5-node wrappers diverged from the 10-node script in one critical way:
- they special-cased `node0`
- they mixed `node0`/`node1` style addressing with `node-0`/`node-1`
- they relied on state carried between setup steps

That led to several concrete failure modes:
- `~/bin/homa.ko` missing on `node0`
- `/etc/hosts` containing `node1` but not `node-1`
- `cp_node` finding peers manually but not when launched by `cperf`
- Homa loaded on one node but not another
- stale `cp_node` or `homa_prio` processes leaving ports in use

The 5-node wrappers were updated so that they now:
- provision every node through `node-<id>` consistently
- copy the same runtime files to every node
- install `cp_node`, `homa_prio`, and Python helpers into `/usr/bin` on every node
- rebuild `/etc/hosts` entries for `node-<id>` on every node
- do an explicit final "refresh" step immediately before the benchmark:
  - `pkill cp_node`
  - `pkill homa_prio`
  - `rmmod homa`
  - `insmod ~/bin/homa.ko`
  - reapply the `net.homa.*` sysctls

That final refresh step is what made the 5-node wrappers reliable in practice.

## Script-by-Script Breakdown

### `run_cp_vs_tcp_5nodes.sh`

Purpose:
- run `util/cp_vs_tcp` on a 5-node cluster
- typically compare Homa vs DCTCP for a workload such as `w4`
- fetch the resulting RTT data and generated PDFs back to the local repo

Inputs:
- required:
  - `--workload`
- optional:
  - `--gbps`
  - `--seconds`
  - `--tcp`
  - `--dctcp`
  - `--link-mbps`
  - `--log-root`
  - `--start-script`
  - `--local-results-dir`
  - `--num-nodes`
  - `--node0`

Defaults:
- `NUM_NODES=5`
- `RUN_SECONDS=10`
- `TCP=false`
- `DCTCP=true`
- `LINK_MBPS=25000`
- `HOMA_MAX_NIC_QUEUE_NS=2000`
- `HOMA_RTT_BYTES=60000`
- `HOMA_GRANT_INCREMENT=10000`
- `HOMA_MAX_GSO_SIZE=20000`

Main phases:
- prepare `node0`
- authorize `node0` key on peers
- push runtime files to `node-0` through `node-4`
- load Homa on all nodes
- explicitly refresh Homa runtime on all nodes
- run:
  - `./cp_vs_tcp -n 5 --servers 1 ...`
- fetch logs to local `experiments/results/`

Primary outputs:
- per-node logs: `node-0.log`, `node-1.log`, ...
- RTT files: `homa_w4-*.rtts`, `dctcp_w4-*.rtts`, `unloaded_w4-*.rtts`
- reports under `reports/`, especially:
  - `vs_tcp_<workload>.pdf`
  - `short_cdf_<workload>.pdf`
  - `cperf.log`

Validation status:
- validated end-to-end after the wrapper fix

For the 10-node wrapper:
- `run_baselines.sh` now defaults to the all-nodes cp_vs_tcp layout (`--servers 0`)
- pass `--servers 1` to use the dedicated node-0 server and node-1..node-9 clients layout

### `run_cp_basic_5nodes.sh`

Purpose:
- run `util/cp_basic` on a 5-node cluster
- gather one-number summary comparisons for Homa, TCP, and DCTCP

Inputs:
- mostly environment driven
- notable tunables:
  - `RUN_SECONDS`
  - `LINK_MBPS`
  - `HOMA_MAX_NIC_QUEUE_NS`
  - `HOMA_RTT_BYTES`
  - `HOMA_GRANT_INCREMENT`
  - `HOMA_MAX_GSO_SIZE`
  - `DCTCP`

Main phases:
- prepare `node0`
- authorize `node0` key on peers
- push runtime files to all nodes
- load Homa on all nodes
- explicitly refresh Homa runtime on all nodes
- run:
  - `./cp_basic -n 5 -s <seconds> --dctcp true|false`
- fetch results back to `experiments/results/`

What `cp_basic` measures:
- Homa RTT latency with 100-byte messages
- Homa single-message throughput with 500 KB messages
- Homa client RPC throughput
- Homa client throughput
- Homa server RPC throughput
- Homa server throughput
- then the same for TCP
- then the same for DCTCP if enabled

Primary outputs:
- per-experiment `.metrics` files
- per-node logs
- `reports/cperf.log`
- summary printed directly to stdout by `cp_basic`

Validation status:
- validated end-to-end after the wrapper fix

For the 10-node wrapper:
- `run_cp_basic.sh` now defaults to keeping cp_node servers active on all nodes (`--servers 0`)
- pass `--servers 1` to use the dedicated node-0 server and node-1..node-9 clients layout

### `run_cp_transport_basic.sh`

Purpose:
- run the `cp_basic`-style transport comparison at 25 Gbps link settings
- compare:
  - Homa
  - DCTCP
  - DCTCP + TFO
  - DCTCP + TFO + Connection Pooling
  - DCTCP + TFO + HTTP/2 Multiplexing
  - DCTCP + TFO + Staggered Scheduling
  - DCTCP + TFO + Load-Aware Session Scheduling

Inputs:
- mostly environment driven
- notable tunables:
  - `RUN_SECONDS` (default `5`)
  - `LINK_MBPS` (default `25000`)
  - `LOCAL_RESULTS_DIR`
  - `LOG_ROOT`

Main phases:
- sync updated `cp_node.cc`, `cperf.py`, and `cp_transport_basic` to `node0`
- clean-rebuild `util/` on `node0`
- explicitly install rebuilt `cp_node`, `homa_prio`, and Python helpers onto every worker
- refresh Homa and reset `net.ipv4.tcp_fastopen=0` before the benchmark
- run:
  - `./cp_transport_basic -n <num_nodes> -s <seconds> -l <logdir>`
- fetch the remote log directory back to `experiments/results/`

Primary outputs:
- fetched timestamped directory:
  - `experiments/results/cp_transport_basic_<timestamp>/`
- per-node Homa metrics snapshots for Homa runs:
  - `<experiment>-<node>.metrics`
- per-experiment TCP/IP counter reports for TCP-family runs:
  - `reports/<experiment>.tcp_counters`
- per-node qdisc snapshots for TCP-family runs:
  - `<experiment>-<node>.qdisc`
- plus, depending on manual fetch/debug history, some raw files may also appear in `experiments/results/`

Validation status:
- validated end-to-end after the transport wrapper fix
- note that an earlier completed run hit a summary-print `KeyError` after all phases finished; `util/cp_transport_basic` was patched so missing parsed fields now print `n/a` instead of crashing

### `run_cp_transport_vs_dctcp.sh`

Purpose:
- run the `cp_vs_tcp`-style transport comparison for a workload such as `w4`
- compare:
  - Homa
  - DCTCP
  - DCTCP + TFO
  - DCTCP + TFO + Connection Pooling
  - DCTCP + TFO + HTTP/2 Multiplexing
  - DCTCP + TFO + Staggered Scheduling
  - DCTCP + TFO + Load-Aware Session Scheduling

Inputs:
- environment driven:
  - `WORKLOAD` (default `w4`)
  - `GBPS` (default `20`)
  - `RUN_SECONDS` (default `10`)
  - `LINK_MBPS` (default `25000`)
  - `LOCAL_RESULTS_DIR`
  - `LOG_ROOT`

Main phases:
- sync updated `cp_node.cc`, `cperf.py`, and `cp_transport_vs_dctcp` to `node0`
- clean-rebuild `util/` on `node0`
- explicitly install rebuilt worker binaries on every node
- refresh Homa and reset `net.ipv4.tcp_fastopen=0` before the benchmark
- run:
  - `./cp_transport_vs_dctcp -n <num_nodes> --servers <count> -w <workload> -b <gbps> -s <seconds> -l <logdir>`
- fetch the remote log directory back to `experiments/results/`

Primary outputs:
- `reports/cperf.log`
- `reports/vs_tcp_<workload>.pdf`
- `reports/vs_tcp_<workload>_p50.pdf`
- `reports/vs_tcp_<workload>_p99.pdf`
- `reports/short_cdf_<workload>.pdf`
- RTT samples for slowdown/CDF generation:
  - `<experiment>-<node>.rtts`
- per-node Homa metrics snapshots for Homa runs:
  - `<experiment>-<node>.metrics`
- per-experiment TCP/IP counter reports for TCP-family runs:
  - `reports/<experiment>.tcp_counters`
- per-node qdisc snapshots for TCP-family runs:
  - `<experiment>-<node>.qdisc`
- digest files:
  - `homa_<workload>.data`
  - `dctcp_<workload>.data`
  - `dctcp_tfo_<workload>.data`
  - `dctcp_tfo_pool_<workload>.data`

Validation status:
- validated end-to-end after the transport wrapper fix

For the 10-node wrapper:
- `run_cp_transport_vs_dctcp.sh` now defaults to the all-nodes layout (`--servers 0`)
- pass `--servers 1` to use the dedicated node-0 server and node-1..node-9 clients layout
- plot-only regeneration was also validated after patching the reporting path

### `run_cp_vs_tcp_10nodes.sh`

Purpose:
- reference 10-node version of the `cp_vs_tcp` wrapper

Why it matters:
- this script was the stable baseline used to debug the 5-node wrapper
- when in doubt about intended behavior, compare the 5-node wrapper to this file first

Key difference from the 5-node wrapper:
- 10-node uses the exact same provisioning model but with nodes `0..9`
- the fixed 5-node wrapper now intentionally mirrors this structure

### `analyze_cp_vs_tcp_runs.py`

Purpose:
- combine multiple completed `cp_vs_tcp` runs for a single workload
- produce pooled CDF and slowdown summaries

Inputs:
- one or more `cp_vs_tcp_<workload>_*` directories
- each must contain RTT files and `reports/cperf.log`

Outputs:
- combined slowdown data
- combined short-message CDF data
- summary text
- optional PDFs if `matplotlib` is available

When to use it:
- use it after collecting several repeated `cp_vs_tcp` runs
- do not use it to bootstrap the cluster
- it is post-processing only

## File and Path Conventions

### Remote paths on `node0`

Expected:
- repo: `~/HomaModule`
- compatibility symlink: `~/homaModule`
- helper binaries: `~/bin`

Important files on each node:
- `~/bin/homa.ko`
- `~/bin/cp_node`
- `~/bin/homa_prio`

Installed system-wide by the wrapper:
- `/usr/bin/cp_node`
- `/usr/bin/homa_prio`
- `/usr/bin/*.py` from `util/`

### Local output paths

Default local destination:
- `experiments/results/`

Typical fetched directories:
- `experiments/results/cp_basic_<timestamp>/`
- `experiments/results/cp_vs_tcp_<workload>_<timestamp>/`

Important report files:
- `reports/cperf.log`
- `reports/vs_tcp_<workload>.pdf`
- `reports/short_cdf_<workload>.pdf`
- `reports/<experiment>.tcp_counters`

## Metrics Coverage

The wrappers plus `util/cperf.py` currently capture:
- slowdown plots and short-message RTT CDFs from raw `*.rtts` files for `cp_vs_tcp` and `cp_transport_vs_dctcp`
- RTT latency and throughput/RPC-rate summaries from `node-*.log` parsing for `cp_basic` and `cp_transport_basic`
- Homa kernel metrics snapshots via `metrics.py`, which include canaries such as `resent_packets`, `peer_timeouts`, `server_rpc_discards`, `data_xmit_errors`, and related transport-health counters
- TCP/IP kernel counters via `nstat`, including retransmissions, TCP timeouts, Fast Open success/failure, receive/drop counters, and ECN counters such as `TcpExtTCPDeliveredCE` and `IpExtInCEPkts`
- qdisc snapshots via `tc -s qdisc show` for each TCP-family experiment

The wrappers do not currently produce:
- a single merged summary file that combines RTT, throughput, Homa metrics, TCP counters, and qdisc data across all experiments
- parsed packet-drop or queue-depth summaries from the raw qdisc text
- NIC-level hardware drop counters from `ethtool -S`

## Preconditions Before Running

Before using the wrappers, make sure:
- `ssh_setup/ssh_setup_5nodes.sh` or `ssh_setup/ssh_setup_10nodes.sh` has been run
- local SSH aliases `node0`, `node1`, ... work from the workstation
- `node0` can SSH non-interactively to each peer
- the remote repo exists at `~/HomaModule` on `node0`
- `node0` has sudo privileges
- all test nodes accept `node0`'s SSH key

If a node was power-cycled, rerunning the benchmark wrapper is usually enough because the wrapper now:
- repairs peer authorization
- repopulates `/etc/hosts`
- recopies runtime files
- reloads Homa immediately before running the experiment

## Common Failure Modes and Meaning

### `Address already in use`

Meaning:
- stale `cp_node` server is still bound from a previous run

Current mitigation:
- the wrappers now kill stale `cp_node` and `homa_prio` processes before the benchmark begins
- the transport wrappers also kill stale `cp_transport_basic` / `cp_transport_vs_dctcp` on `node0`

### `Couldn't find unloaded_<workload> RTT data`

Meaning:
- the unloaded phase failed before producing RTT files
- this is a downstream symptom, not the root cause

Next step:
- inspect the corresponding `node-*.log` for the first real failure

### `couldn't look up address for node-1`

Meaning:
- `/etc/hosts` or SSH alias setup does not provide `node-<id>` names

Current mitigation:
- wrappers rewrite `/etc/hosts` entries on every node from generated private-IP mappings

### `couldn't open Homa socket: Protocol not supported`

Meaning:
- Homa is not loaded on that node at the instant `cp_node` tries to create a Homa socket

Typical causes:
- `homa.ko` missing
- `insmod` not run successfully
- node rebooted after earlier setup
- wrapper state drift between initial provisioning and actual benchmark start

Current mitigation:
- explicit final runtime refresh just before launching the benchmark

### `MSG_FASTOPEN send failed ... Operation now in progress`

Meaning:
- the old TCP Fast Open client path used `MSG_FASTOPEN` in a nonblocking flow and treated `EINPROGRESS` as fatal

Fix:
- `util/cp_node.cc` now uses `TCP_FASTOPEN_CONNECT` for the TFO client path instead

### Worker nodes ignore new TCP flags such as `--tcp-fastopen`

Meaning:
- worker nodes are still running an old `/usr/bin/cp_node`

Fix:
- the transport wrappers now explicitly install the rebuilt `cp_node` and `homa_prio` binaries on every worker before the run

## How the Benchmarks Actually Work

### `cp_vs_tcp`

`util/cp_vs_tcp` runs three experiment classes for each workload:
- `unloaded_<workload>`
- `homa_<workload>`
- `tcp_<workload>` and/or `dctcp_<workload>`

For the 5-node scripts here, the usual mode is:
- one server node
- four client nodes

Then it generates:
- slowdown plots from RTT digests
- short-message RTT CDFs

### `cp_transport_vs_dctcp`

`util/cp_transport_vs_dctcp` is the transport-comparison analogue of `cp_vs_tcp`. For each workload it runs:

- `unloaded_<workload>`
- `homa_<workload>`
- `dctcp_<workload>`
- `dctcp_tfo_<workload>`
- `dctcp_tfo_pool_<workload>`
- `dctcp_tfo_http2_<workload>`
- `dctcp_tfo_staggered_<workload>`
- `dctcp_tfo_load_aware_<workload>`

Then it generates:

- combined slowdown plot
- P50-only slowdown plot
- P99-only slowdown plot
- short-message RTT CDF

### `cp_basic`

`util/cp_basic` is a summary benchmark. It is not just one workload; it runs a sequence:
- low-load 100B latency
- single-message 500 KB throughput
- client-side RPC rate
- client-side throughput
- server-side RPC rate
- server-side throughput

That sequence is run for:
- Homa
- TCP
- DCTCP

The benchmark prints:
- aggregate averages
- the per-run samples in parentheses

If you need a paper-style Table 2 summary:
- use the printed per-run samples
- take minimum for latency
- take maximum for throughput / RPC rate

### `cp_transport_basic`

`util/cp_transport_basic` is the transport-comparison analogue of `cp_basic`. It runs the same summary sequence as `cp_basic`, but for:

- Homa
- DCTCP
- DCTCP + TFO
- DCTCP + TFO + Connection Pooling
- DCTCP + TFO + HTTP/2 Multiplexing
- DCTCP + TFO + Staggered Scheduling
- DCTCP + TFO + Load-Aware Session Scheduling

New transport-variant semantics:
- `DCTCP + TFO + HTTP/2 Multiplexing` approximates a single multiplexed session by using one TCP client port with pooled/TFO-enabled connections per server.
- `DCTCP + TFO + Staggered Scheduling` adds a fixed microsecond-scale client-start offset and applies temporary `tc netem ... loss <p>% ecn` shaping while the variant runs.
- `DCTCP + TFO + Load-Aware Session Scheduling` keeps TFO and pooling but chooses the least-backed-up server session for each new request.

## Recommended Operator Workflow

For 5 nodes:

1. Run `CLOUDLAB_USER=ARY ssh_setup/ssh_setup_5nodes.sh` if cluster state is new or nodes were reprovisioned.
2. For the original baseline, run `experiments/run_cp_vs_tcp_5nodes.sh --workload w4 --gbps 20 --dctcp true --tcp false`
3. For the original baseline summary benchmark, run `experiments/run_cp_basic_5nodes.sh`
4. For the transport comparison summary benchmark, run `experiments/run_cp_transport_basic.sh`
5. For the transport comparison slowdown/CDF benchmark, run `WORKLOAD=w4 GBPS=20 experiments/run_cp_transport_vs_dctcp.sh`
6. Read fetched results under `experiments/results/`
7. If you want a pooled figure across several repetitions of the original baseline, use `analyze_cp_vs_tcp_runs.py`

Practical note:
- `ssh_setup_5nodes.sh` is the step that made `node0 -> node-1..node-4` SSH and `node-<id>` host resolution work cleanly
- if a node was reprovisioned or `/etc/hosts` drifted, rerun the setup script before debugging the wrapper itself

## Current Known Good Results

Validated wrapper runs:
- `cp_vs_tcp_5nodes`: fetched successfully during validation to `/tmp/cp_vs_tcp_wrapper_verify/cp_vs_tcp_w4_20260401184448`
- `cp_basic_5nodes`: fetched successfully to `experiments/results/cp_basic_20260401184601`
- `cp_transport_basic_5nodes`: completed and fetched as `experiments/results/cp_transport_basic_20260401205535`
- `cp_transport_vs_dctcp_5nodes`: completed with reports under `experiments/results/cp_transport_w4_20260401210039/reports`

Paper-style summary markdown saved at:
- `experiments/results/cp_basic_table.md`

Transport-comparison notes:
- the generated `w4` plots currently exist at:
  - `experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4.pdf`
  - `experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4_p50.pdf`
  - `experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4_p99.pdf`
  - `experiments/results/cp_transport_w4_20260401210039/reports/short_cdf_w4.pdf`
- in the saved artifact set, `Homa` and `DCTCP + TFO + Connection Pooling` produced valid loaded `w4` datasets
- plain `DCTCP` and plain `DCTCP + TFO` are present but under-sampled in that archived run and should be treated as incomplete for loaded-phase conclusions

## Editing Guidance

If you change these wrappers:
- preserve `node-<id>` addressing for all cluster-internal operations
- do not reintroduce special `node0` provisioning logic unless there is a hard requirement
- keep the final explicit Homa refresh step
- keep the explicit worker binary install step; do not assume workers already have the new `cp_node`
- avoid relying on leftover cluster state from earlier runs
- validate with a real cluster run, not just `bash -n`

If you need to debug future failures:
- inspect `reports/cperf.log`
- inspect `node-*.log`
- verify `lsmod | grep '^homa'`
- verify `sysctl net.homa.link_mbps`
- verify `ssh node0 'ssh node-1 hostname'`
- verify `cp_node` can bind a Homa port manually on the target node
