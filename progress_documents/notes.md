# Experiment Notes

## 2026-04-01 Transport Debugging Update

This update captures the latest debugging pass for the 5-node `w4` / `20 Gbps`
transport comparison, including code fixes and the results-layout cleanup.

### Code fixes made

- Fixed TCP client epoll dispatch in
  [util/cp_node.cc](/NAS/School/CS8803/HomaModule/util/cp_node.cc):
  client-side epoll events were being looked up by socket fd instead of the
  stored connection id.
- Fixed the non-pooled TCP receive path in
  [util/cp_node.cc](/NAS/School/CS8803/HomaModule/util/cp_node.cc):
  non-pooled clients were closing a connection after any readable event, even
  if a full response had not yet arrived.
- Updated
  [util/cp_transport_vs_dctcp](/NAS/School/CS8803/HomaModule/util/cp_transport_vs_dctcp)
  so the non-pooled `DCTCP` and `DCTCP + TFO` variants can be given longer run
  times without changing the pooled variants.
- Updated
  [util/cperf.py](/NAS/School/CS8803/HomaModule/util/cperf.py)
  so slowdown digesting uses sample-sized buckets instead of exact-length-only
  buckets for very sparse datasets.

### Latest canonical run

- latest fetched transport run:
  - [experiments/results/runs/transport/cp_transport_w4_20260401221330](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport/cp_transport_w4_20260401221330)
- latest transport reports:
  - [experiments/results/runs/transport/cp_transport_w4_20260401221330/reports](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport/cp_transport_w4_20260401221330/reports)

### Current interpretation

- `Homa` still looks healthy for the saved `w4` configuration.
- `DCTCP + TFO + Connection Pooling`, `HTTP/2`, `Staggered`, and
  `Load-Aware` all complete enough traffic to generate dense RTT datasets and
  stable slowdown curves.
- Plain `DCTCP` and plain `DCTCP + TFO` remain fundamentally weak in the
  current non-pooled transport path for this setup. The issue is no longer just
  charting noise:
  - clients repeatedly sit at `Outstanding client RPCs: 200`
  - server throughput stays far below the pooled variants
  - the resulting slowdown curves remain sparse because these modes are not
    completing enough RPCs under load

### Why the load-aware curve looks flat

The load-aware variant is flat mostly because it removes queue imbalance across
 persistent pooled sessions.

- In the latest digest
  [experiments/results/runs/transport/cp_transport_w4_20260401221330/reports/dctcp_tfo_load_aware_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport/cp_transport_w4_20260401221330/reports/dctcp_tfo_load_aware_w4.data),
  the short and medium message buckets stay in a narrow band:
  - `s50` is roughly `18-22`
  - `s99` is roughly `120-140`
- That means slowdown is dominated by a fairly uniform shared queueing regime,
  not by size-specific per-connection head-of-line buildup.
- Connection pooling plus least-backed-up-session selection suppresses most of
  the large step changes that appear in less balanced variants.

### Results layout cleanup

The results tree is now organized so future fetches do not overwrite reports:

- baseline runs go under:
  - [experiments/results/runs/baseline](/NAS/School/CS8803/HomaModule/experiments/results/runs/baseline)
- transport runs go under:
  - [experiments/results/runs/transport](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport)
- `latest` symlinks point to the newest fetched run for each category
- the loose root-level transport artifacts were moved into the latest transport
  run directory above

New wrapper fetches now copy directly into per-run directories instead of
reusing top-level `experiments/results/reports`.

## Scope

This note summarizes the experiment artifacts currently saved in this repository for:

- 10-node baseline reproduction (`cp_basic`, `cp_vs_tcp w4`)
- 5-node baseline/manual runs
- 5-node transport comparison runs for:
  - Homa
  - DCTCP
  - DCTCP + TFO
  - DCTCP + TFO + Connection Pooling
  - DCTCP + TFO + HTTP/2 Multiplexing
  - DCTCP + TFO + Staggered Scheduling
  - DCTCP + TFO + Load-Aware Session Scheduling

All statements below are tied to saved logs, metrics, or generated report files. Where a dataset is incomplete, that is stated explicitly.

## Result Locations

- 10-node `cp_basic` baseline:
  - [experiments/results/cp_basic_20260401192606](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_20260401192606)
  - summary table: [experiments/results/cp_basic_table2_summary.md](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_table2_summary.md)
- 10-node `cp_vs_tcp w4` baseline attempt:
  - [experiments/results/cp_vs_tcp_w4_20260401192723](/NAS/School/CS8803/HomaModule/experiments/results/cp_vs_tcp_w4_20260401192723)
- 5-node manual `cp_basic` baseline:
  - [experiments/results/cp_basic_manual_](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_)
- 5-node transport comparison, `w4`:
  - reports: [experiments/results/cp_transport_w4_20260401210039/reports](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports)
  - raw fetched logs/metrics for this run also landed in [experiments/results](/NAS/School/CS8803/HomaModule/experiments/results)

## Update: Expanded Transport Variant Results

The results tree has since been reorganized. The most relevant locations for the new transport-variant work are:

- results layout note:
  - [experiments/results/README.md](/NAS/School/CS8803/HomaModule/experiments/results/README.md)
- earlier complete fetched transport directory:
  - [experiments/results/runs/transport/cp_transport_w4_20260401210039](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport/cp_transport_w4_20260401210039)
- expanded transport artifact snapshot containing the newly added variants:
  - [experiments/results/legacy_root_snapshot](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot)
  - [experiments/results/legacy_root_snapshot/reports](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports)
- baseline and manual run directories are now grouped under:
  - [experiments/results/runs/baseline](/NAS/School/CS8803/HomaModule/experiments/results/runs/baseline)
- summary markdown is now under:
  - [experiments/results/summaries/cp_basic_table2_summary.md](/NAS/School/CS8803/HomaModule/experiments/results/summaries/cp_basic_table2_summary.md)

### New variants exercised

The expanded transport comparison added:

- DCTCP + TFO + HTTP/2 Multiplexing
- DCTCP + TFO + Staggered Scheduling
- DCTCP + TFO + Load-Aware Session Scheduling

The RTT-based `w4` comparison for these variants completed and generated all expected comparison figures:

- [experiments/results/legacy_root_snapshot/reports/vs_tcp_w4.pdf](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/vs_tcp_w4.pdf)
- [experiments/results/legacy_root_snapshot/reports/vs_tcp_w4_p50.pdf](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/vs_tcp_w4_p50.pdf)
- [experiments/results/legacy_root_snapshot/reports/vs_tcp_w4_p99.pdf](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/vs_tcp_w4_p99.pdf)
- [experiments/results/legacy_root_snapshot/reports/short_cdf_w4.pdf](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/short_cdf_w4.pdf)

The new digest/data files are present here:

- [experiments/results/legacy_root_snapshot/reports/dctcp_tfo_http2_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/dctcp_tfo_http2_w4.data)
- [experiments/results/legacy_root_snapshot/reports/dctcp_tfo_staggered_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/dctcp_tfo_staggered_w4.data)
- [experiments/results/legacy_root_snapshot/reports/dctcp_tfo_load_aware_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/dctcp_tfo_load_aware_w4.data)
- [experiments/results/legacy_root_snapshot/reports/dctcp_tfo_http2_w4_cdf.data](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/dctcp_tfo_http2_w4_cdf.data)
- [experiments/results/legacy_root_snapshot/reports/dctcp_tfo_staggered_w4_cdf.data](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/dctcp_tfo_staggered_w4_cdf.data)
- [experiments/results/legacy_root_snapshot/reports/dctcp_tfo_load_aware_w4_cdf.data](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/dctcp_tfo_load_aware_w4_cdf.data)

The raw RTT files for the new variants were fetched successfully:

- HTTP/2-style multiplexing:
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-1.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-1.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-2.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-2.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-3.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-3.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-4.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_http2_w4-4.rtts)
- staggered scheduling:
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-1.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-1.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-2.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-2.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-3.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-3.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-4.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_staggered_w4-4.rtts)
- load-aware scheduling:
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-1.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-1.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-2.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-2.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-3.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-3.rtts)
  - [experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-4.rtts](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/dctcp_tfo_load_aware_w4-4.rtts)

### What the saved logs show

The expanded `cp_transport_vs_dctcp` run completed the full RTT collection and plotting path. The evidence is in [experiments/results/legacy_root_snapshot/reports/cperf.log](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/cperf.log), which contains:

- `Digest finished for dctcp_tfo_http2_w4`
- `Digest finished for dctcp_tfo_staggered_w4`
- `Digest finished for dctcp_tfo_load_aware_w4`
- `Generating slowdown plot for w4`
- `Generating short message CDF for w4`

The same saved log also records two caveats:

- the textual summary path still hit a post-run `KeyError: 'client_gbps'` after the experiments finished, so this artifact set should be treated as a successful RTT/figure run rather than a fully clean summary run
- the staggered variant emitted `RTNETLINK answers: No such device` during the temporary `tc netem` setup, so the packet-loss/ECN injection path still needs follow-up even though RTT artifacts were produced

### Preliminary summary-style numbers for the new variants

The saved summary-style transport output in [experiments/results/legacy_root_snapshot/reports/cperf.log](/NAS/School/CS8803/HomaModule/experiments/results/legacy_root_snapshot/reports/cperf.log) includes useful client-side numbers for the new variants:

- `DCTCP + TFO + HTTP/2 Multiplexing`
  - RTT latency: `25.78 us`
  - single-message throughput: `18.12 Gbps`
  - client RPC throughput: `248.91 Kops/sec`
  - client throughput: `23.44 Gbps`
- `DCTCP + TFO + Staggered Scheduling`
  - RTT latency: `27.40 us`
  - single-message throughput: `18.91 Gbps`
  - client RPC throughput: `705.11 Kops/sec`
  - client throughput: `23.18 Gbps`
- `DCTCP + TFO + Load-Aware Session Scheduling`
  - RTT latency: `26.28 us`
  - single-message throughput: `19.16 Gbps`
  - client RPC throughput: `773.86 Kops/sec`
  - client throughput: `23.24 Gbps`

Interpretation:

- the HTTP/2-style multiplexed configuration preserved strong throughput but reduced client RPC throughput substantially relative to pooled multi-session TCP
- the load-aware configuration produced the strongest client RPC throughput among the new variants
- the staggered configuration is promising in the saved RTT dataset, but its explicit `tc netem` setup path still needs cleanup before it should be treated as a fully clean result

## 10-Node Baseline Reproduction

### `cp_basic`

The cleanest baseline summary is already captured in [experiments/results/cp_basic_table2_summary.md](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_table2_summary.md). The best-per-run values reported there are:

| Metric | Homa | TCP | DCTCP |
|---|---:|---:|---:|
| 100B latency (us) | 22.29 | 27.80 | 26.51 |
| 500KB throughput (Gbps) | 6.0 | 19.36 | 19.46 |
| Client throughput (Gbps) | 18.95 | 23.19 | 23.18 |
| Server throughput (Gbps) | 18.33 | 23.11 | 23.14 |
| Client RPC rate (Mops/sec) | 1.367 | 0.653 | 0.642 |
| Server RPC rate (Mops/sec) | 0.824 | 1.004 | 0.996 |

Important interpretation:

- Homa wins the small-message RPC-rate metric by a large margin.
- TCP and DCTCP are much better for the 500 KB single-message throughput point in this setup.
- Client/server bulk throughput is similar for TCP and DCTCP and higher than Homa in this baseline.

### Congestion / drops / retransmission evidence in baseline `cp_basic`

The 10-node baseline summary directory does not include full TCP/DCTCP per-node metrics, but the saved Homa metrics do show congestion-related control activity. Examples:

- [experiments/results/cp_basic_20260401192606/reports/homa_latency.metrics](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_20260401192606/reports/homa_latency.metrics) shows `packets_sent_NEED_ACK`.
- The broader saved Homa metrics in [experiments/results](/NAS/School/CS8803/HomaModule/experiments/results) and the 5-node manual baseline show:
  - `BUSY` packets
  - `NEED_ACK` packets
  - `resent_packets`
  - `resent_packets_used`
  - `ack_overflows`

These are direct indicators of receiver pressure, retransmission activity, or explicit acknowledgement pressure for Homa. I did not find explicit ECN mark counters in the saved baseline TCP/DCTCP artifacts.

### `cp_vs_tcp w4`

The archived 10-node `w4` run in [experiments/results/cp_vs_tcp_w4_20260401192723](/NAS/School/CS8803/HomaModule/experiments/results/cp_vs_tcp_w4_20260401192723) is not a clean completed dataset.

The failure is explicit in [experiments/results/cp_vs_tcp_w4_20260401192723/reports/cperf.log](/NAS/School/CS8803/HomaModule/experiments/results/cp_vs_tcp_w4_20260401192723/reports/cperf.log) and [experiments/results/cp_vs_tcp_w4_20260401192723/node-7.log](/NAS/School/CS8803/HomaModule/experiments/results/cp_vs_tcp_w4_20260401192723/node-7.log):

- `FATAL: error in homa_recv: Connection timed out`
- the run aborted during the loaded Homa phase

Conclusion:

- `cp_basic` reproduced successfully enough to generate a usable baseline summary.
- the archived 10-node `cp_vs_tcp w4` run should be treated as failed/incomplete, not as a valid comparison dataset.

## 5-Node Manual Baseline (`cp_basic_manual_`)

The 5-node manual baseline in [experiments/results/cp_basic_manual_](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_) is useful mainly for qualitative congestion evidence.

### Congestion evidence

Across the saved node logs:

- `Lag due to overload` repeatedly reaches about `100%`
- `Outstanding client RPCs` is frequently high
- `Backed-up sends` appears during heavier phases

Representative examples:

- [experiments/results/cp_basic_manual_/node-0.log](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_/node-0.log)
  - `Lag due to overload: 100.0%`
  - `Outstanding client RPCs: 198`
  - `Backed-up sends: 97/5691 (1.7%)`
- [experiments/results/cp_basic_manual_/node-3.log](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_/node-3.log)
  - repeated `Lag due to overload: 99.9%-100.3%`
  - `Outstanding client RPCs` in the `42-45` range for heavy phases

### Homa transport-control evidence

The Homa metrics in this directory show concrete stress signals:

- [experiments/results/cp_basic_manual_/homa_client_tput-0.metrics](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_/homa_client_tput-0.metrics)
  - `packets_rcvd_BUSY 281`
  - `packets_rcvd_NEED_ACK 2944`
- [experiments/results/cp_basic_manual_/homa_server_tput-0.metrics](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_/homa_server_tput-0.metrics)
  - `packets_sent_BUSY 4`
  - `resent_packets_used 29`
- [experiments/results/cp_basic_manual_/homa_server_rpc_tput-2.metrics](/NAS/School/CS8803/HomaModule/experiments/results/cp_basic_manual_/homa_server_rpc_tput-2.metrics)
  - `ack_overflows 72`

I did not find explicit ECN counters in these saved baseline logs.

## 5-Node Transport Comparison: `w4`

### Report files

These are the main chart/report outputs for the successful 5-node transport comparison:

- combined slowdown: [experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4.pdf](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4.pdf)
- slowdown P50 only: [experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4_p50.pdf](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4_p50.pdf)
- slowdown P99 only: [experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4_p99.pdf](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/vs_tcp_w4_p99.pdf)
- short-message CDF: [experiments/results/cp_transport_w4_20260401210039/reports/short_cdf_w4.pdf](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/short_cdf_w4.pdf)

Underlying digests:

- [experiments/results/cp_transport_w4_20260401210039/reports/homa_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/homa_w4.data)
- [experiments/results/cp_transport_w4_20260401210039/reports/dctcp_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/dctcp_w4.data)
- [experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_w4.data)
- [experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_pool_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_pool_w4.data)

### Throughput and latency summary

Recovered from [experiments/results/cp_transport_w4_20260401210039/reports/cperf.log](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/cperf.log) and the raw node logs in [experiments/results](/NAS/School/CS8803/HomaModule/experiments/results).

#### Homa

- Client average per node: `4.77 Gbps`, `9.8 Kops/sec`
- Server average: `19.24 Gbps`, `39.5 Kops/sec`
- Overall average per node: `7.66 Gbps`, `15.8 Kops/sec`
- From raw client logs, average loaded client RTTs were roughly:
  - `P50 208.62 us`
  - `P99 544827.80 us`
  - `P99.9 609908.24 us`

Sources:

- [experiments/results/cp_transport_w4_20260401210039/reports/cperf.log](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/cperf.log)
- [experiments/results/node-1.log](/NAS/School/CS8803/HomaModule/experiments/results/node-1.log)
- [experiments/results/node-2.log](/NAS/School/CS8803/HomaModule/experiments/results/node-2.log)
- [experiments/results/node-3.log](/NAS/School/CS8803/HomaModule/experiments/results/node-3.log)
- [experiments/results/node-4.log](/NAS/School/CS8803/HomaModule/experiments/results/node-4.log)

#### DCTCP

This saved dataset is incomplete and should not be treated as a valid loaded run.

Evidence:

- [experiments/results/cp_transport_w4_20260401210039/reports/dctcp_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/dctcp_w4.data) contains only `58` total digested samples.
- raw client logs show `Outstanding client RPCs: 200` pinned for the phase, with no valid periodic `Clients:` lines saved for the loaded run.

Conclusion:

- There is enough data to draw a curve fragment in the digest, but not enough to claim a trustworthy loaded throughput/latency summary.

#### DCTCP + TFO

This saved dataset is also incomplete and should not be treated as a valid loaded run.

Evidence:

- [experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_w4.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_w4.data) contains only `70` total digested samples.
- raw client logs again show `Outstanding client RPCs: 200` pinned throughout the phase, with no valid loaded `Clients:` throughput lines persisted.

Conclusion:

- The run did not produce a trustworthy loaded-phase dataset for plain `DCTCP + TFO`.

#### DCTCP + TFO + Connection Pooling

This is the successful TCP-family result in the 5-node transport comparison.

- Raw loaded client average across nodes:
  - `5.05 Gbps` per client node
  - `10.27 Kops/sec` per client node
  - `P50 507.71 us`
  - `P99 31182.69 us`
  - `P99.9 77587.80 us`
- Raw loaded server average:
  - `20.02 Gbps`
  - `40.93 Kops/sec`

Sources:

- [experiments/results/node-0.log](/NAS/School/CS8803/HomaModule/experiments/results/node-0.log)
- [experiments/results/node-1.log](/NAS/School/CS8803/HomaModule/experiments/results/node-1.log)
- [experiments/results/node-2.log](/NAS/School/CS8803/HomaModule/experiments/results/node-2.log)
- [experiments/results/node-3.log](/NAS/School/CS8803/HomaModule/experiments/results/node-3.log)
- [experiments/results/node-4.log](/NAS/School/CS8803/HomaModule/experiments/results/node-4.log)

### Short-message CDF observations

Directly from the CDF data files:

- Homa short-message CDF extends down into the `24-39 us` range:
  - [experiments/results/cp_transport_w4_20260401210039/reports/homa_w4_cdf.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/homa_w4_cdf.data)
- DCTCP + TFO + Pooling short-message CDF starts around `30.5 us` and then rises through the `30-45 us` region:
  - [experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_pool_w4_cdf.data](/NAS/School/CS8803/HomaModule/experiments/results/cp_transport_w4_20260401210039/reports/dctcp_tfo_pool_w4_cdf.data)
- The saved DCTCP and DCTCP+TFO short-message CDFs are based on very small sample counts and should not be overinterpreted:
  - DCTCP: `58` total samples
  - DCTCP+TFO: `70` total samples

### Slowdown observations

The slowdown plots should be interpreted with the data-quality caveat above.

Reliable comparison:

- Homa vs DCTCP+TFO+Pooling

Not reliable as loaded-run conclusions:

- Homa vs plain DCTCP
- Homa vs plain DCTCP+TFO

Reason:

- the latter two datasets are incomplete and under-sampled in the saved artifacts

### Congestion / queueing / overload evidence for the 5-node `w4` transport run

#### Homa

The Homa `w4` run clearly experienced queue growth and overload under load.

From raw client logs:

- average outstanding RPCs: `158.55`
- maximum outstanding RPCs: `198`
- average `Lag due to overload`: `8.42%`
- maximum `Lag due to overload`: `16.2%`

Representative lines:

- [experiments/results/node-3.log](/NAS/School/CS8803/HomaModule/experiments/results/node-3.log)
  - `Lag due to overload: 16.2%`
  - `Outstanding client RPCs: 198`
- [experiments/results/node-1.log](/NAS/School/CS8803/HomaModule/experiments/results/node-1.log)
  - `Outstanding client RPCs: 131`
- [experiments/results/node-4.log](/NAS/School/CS8803/HomaModule/experiments/results/node-4.log)
  - `Outstanding client RPCs: 195`

From saved Homa metrics:

- [experiments/results/homa_w4-0.metrics](/NAS/School/CS8803/HomaModule/experiments/results/homa_w4-0.metrics)
  - `packets_sent_BUSY 3997`
  - `packets_sent_NEED_ACK 25889`
  - `packets_rcvd_BUSY 3966`
  - `resent_packets_used 1427`
- [experiments/results/homa_w4-1.metrics](/NAS/School/CS8803/HomaModule/experiments/results/homa_w4-1.metrics)
  - `ack_overflows 2280`
- [experiments/results/homa_w4-2.metrics](/NAS/School/CS8803/HomaModule/experiments/results/homa_w4-2.metrics)
  - `resent_packets 421`
  - `ack_overflows 875`
- [experiments/results/homa_w4-3.metrics](/NAS/School/CS8803/HomaModule/experiments/results/homa_w4-3.metrics)
  - `packets_sent_BUSY 987`
  - `packets_rcvd_BUSY 1056`
  - `resent_packets 393`

Interpretation:

- there is strong evidence of queueing, receiver-pressure feedback, and retransmission activity
- there is no evidence in the saved artifacts of pervasive packet loss causing run failure; the run completed and produced a large valid dataset

#### DCTCP

From raw client logs:

- `Outstanding client RPCs` is pinned at `200` for the entire loaded phase
- no valid saved `Clients:` lines were emitted for the loaded phase

Interpretation:

- the clients appear to have saturated their outstanding-request limit without making forward progress sufficient to generate a valid loaded dataset

#### DCTCP + TFO

From raw client logs:

- `Outstanding client RPCs` is also pinned at `200` for the entire loaded phase
- again, no valid loaded `Clients:` lines were saved

Interpretation:

- enabling TFO alone did not recover the loaded run in this artifact set

#### DCTCP + TFO + Connection Pooling

This run shows much healthier forward progress than plain DCTCP or DCTCP+TFO.

From raw client logs:

- average outstanding RPCs: `8.55`
- maximum outstanding RPCs: `21`
- average backed-up sends: `2.9%`
- maximum backed-up sends: `9.2%`

Representative lines:

- [experiments/results/node-1.log](/NAS/School/CS8803/HomaModule/experiments/results/node-1.log)
  - `Clients: 10.63 Kops/sec, 5.29 Gbps, RTT (us) P50 805.00 P99 68440.28 P99.9 106076.96`
  - `Backed-up sends: 970/10635 (9.1%)`
- [experiments/results/node-3.log](/NAS/School/CS8803/HomaModule/experiments/results/node-3.log)
  - `Clients: 10.26 Kops/sec, 4.87 Gbps, RTT (us) P50 453.55 P99 7920.95 P99.9 29797.41`
  - `Backed-up sends: 198/10323 (1.9%)`
- [experiments/results/node-4.log](/NAS/School/CS8803/HomaModule/experiments/results/node-4.log)
  - `Clients: 10.07 Kops/sec, 4.98 Gbps, RTT (us) P50 453.59 P99 8345.98 P99.9 27712.02`
  - `Backed-up sends: 191/10143 (1.9%)`

Interpretation:

- connection pooling is the only TCP-family mode in this saved run that produced a stable loaded dataset
- its median latency and throughput are much better than the failed unpooled TCP-family runs
- it still shows nontrivial send-side queueing and a noticeably elevated tail relative to its own median

## Packet Drops, ECN Marks, Congestion: What Is and Is Not Observable

### Observable in saved artifacts

- queueing / overload:
  - `Outstanding client RPCs`
  - `Lag due to overload`
  - `Backed-up sends`
- Homa transport pressure:
  - `BUSY`
  - `NEED_ACK`
  - `ack_overflows`
  - `resent_packets`
  - `resent_packets_used`
- explicit timeout/failure:
  - `FATAL: error in homa_recv: Connection timed out` in the failed 10-node `w4` baseline

### Not directly observable in saved artifacts

- explicit ECN mark counters for DCTCP/TCP
- packet-drop counters for the TCP-family experiments

I searched the saved logs and metrics for `ECN`, `ecn`, `mark`, `drop`, and related terms and did not find explicit ECN-mark or packet-drop accounting for the DCTCP/TCP runs. Therefore:

- I can state that congestion/queueing is visible
- I cannot claim a precise ECN-mark count from the saved artifacts
- I cannot claim a precise TCP packet-drop count from the saved artifacts

## Main Conclusions

- The 10-node `cp_basic` baseline was reproduced successfully enough to recover a usable table of Homa vs TCP vs DCTCP.
- The archived 10-node `cp_vs_tcp w4` run is not valid because it failed with Homa receive timeouts on `node-7`.
- In the 5-node transport comparison, the only TCP-family mode that produced a clean loaded dataset was `DCTCP + TFO + Connection Pooling`.
- Relative to Homa in the 5-node `w4` run:
  - Homa had lower median latency in the short-message/CDF view.
  - `DCTCP + TFO + Connection Pooling` achieved slightly higher server throughput in the loaded run (`20.02 Gbps` vs `19.24 Gbps`).
  - Homa showed far more queue buildup in the raw `Outstanding client RPCs` and overload indicators.
  - `DCTCP + TFO + Connection Pooling` still had clear queueing/backpressure, but it remained operational and produced a valid dataset.
- Plain `DCTCP` and plain `DCTCP + TFO` should be treated as failed/incomplete in this saved 5-node `w4` comparison, because their digests only contain `58` and `70` samples.
