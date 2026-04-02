# Experiment Assets

This directory contains the subset of artifacts from the latest corrected
transport runs that are most useful for figures and evidence.

Source runs:
- `experiments/results/runs/transport/cp_transport_basic_20260401232107`
- `experiments/results/runs/transport/cp_transport_w4_20260401232711`

## Charts

- `charts/vs_tcp_w4_p99.pdf`
  - P99 slowdown comparison for the corrected `w4` transport run.
- `charts/short_cdf_w4.pdf`
  - Short-message RTT CDF for the corrected `w4` transport run.

## Logs

- `logs/cp_transport_w4_20260401232711.cperf.log`
  - Main slowdown/CDF benchmark log.
  - Shows the corrected transport commands:
    - plain `DCTCP` uses `--tcp-no-pooling`
    - `DCTCP + TFO` uses `--tcp-fastopen --tcp-no-pooling`
  - Shows optimization effects via:
    - `Outstanding RPCs for node-1`
    - `Average rate of backed-up RPCs`
  - Shows DCTCP/ECN configuration via:
    - `net.ipv4.tcp_congestion_control = dctcp`
    - `net.ipv4.tcp_ecn = 1`
  - Shows the staggered variant's attempted `tc netem ... loss ... ecn` setup.
- `logs/cp_transport_basic_20260401232107.cperf.log`
  - Summary benchmark log with aggregate throughput and latency numbers.
- `logs/*.node-0.log`
  - Raw node-0 benchmark logs for deeper debugging.

## Metrics

- `metrics/homa_w4.metrics`
  - Best single file for Homa congestion/retransmission evidence.
  - Includes `packets_sent_BUSY`, `packets_sent_NEED_ACK`,
    `packets_rcvd_BUSY`, `resent_packets`, and `resent_packets_used`.
- `metrics/homa_client_tput.metrics`
  - Homa client throughput metrics with `BUSY` and `NEED_ACK` activity.
- `metrics/homa_server_tput.metrics`
  - Homa server throughput metrics with retransmission evidence.
- `metrics/homa_latency.metrics`
  - Baseline Homa latency metrics from the summary run.
- `metrics/unloaded_w4.metrics`
  - Best-case unloaded Homa reference metrics.
- `raw/homa_w4-2.metrics`, `raw/homa_w4-3.metrics`, `raw/homa_w4-4.metrics`
  - Additional per-node Homa metrics from the loaded `w4` run.

## Data

- `data/dctcp_w4.data`
  - Plain DCTCP slowdown digest.
- `data/dctcp_tfo_pool_w4.data`
  - Pooled TFO slowdown digest.
- `data/dctcp_tfo_http2_w4.data`
  - HTTP/2-style multiplexing slowdown digest.
- `data/dctcp_tfo_staggered_w4.data`
  - Staggered scheduling slowdown digest.
- `data/dctcp_tfo_load_aware_w4.data`
  - Load-aware scheduling slowdown digest.
- `data/homa_w4.data`
  - Homa slowdown digest.
- `data/*_cdf.data`
  - Matching short-message CDF datasets for Homa and the successful optimized variants.

## Important Caveat

These assets prove:
- corrected experiment wiring
- congestion and backpressure behavior
- Homa retransmission / `BUSY` / `NEED_ACK` activity
- that the optimized TCP-family variants outperform plain non-pooled DCTCP in this setup

They do not include a direct kernel counter dump of DCTCP ECN marks. The saved
artifacts show that ECN was enabled and, for the staggered variant, that an ECN
capable `tc netem` policy was attempted, but they do not include a separate
`ss`/`nstat`/`ip -s` style mark counter snapshot.
