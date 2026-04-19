# Homa Reproduced

Source run: `experiments/results/runs/baseline/cp_basic_20260419164709`

Method:
- This table follows the presentation style of Table 2 in the Homa paper.
- The summary is generated automatically from the fetched `node-*.log` files in the selected `cp_basic` run.
- Each row uses the per-second samples recorded during the timed experiment window only.
- To mirror the paper's "best average across five 5-second runs" wording as closely as possible, the table below uses the best per-sample value:
  - latency: minimum value
  - throughput and RPC rate: maximum value
- RPC rates are shown in `Mops/sec`, converted from the `Kops/sec` samples.

## Paper Table 2 Reference

| Metric | Homa | TCP | DCTCP |
|---|---:|---:|---:|
| 100B latency (us) | 15.1 | 23.4 | 24.1 |
| 500KB throughput (Gbps) | 10.0 | 20.3 | 20.5 |
| Client throughput (Gbps) | 23.8 | 23.9 | 21.4 |
| Server throughput (Gbps) | 23.7 | 23.6 | 22.4 |
| Client RPC rate (Mops/sec) | 1.6 | 1.0 | 1.0 |
| Server RPC rate (Mops/sec) | 1.6 | 1.0 | 1.0 |

## Reproduced Results

| Metric | Homa | TCP | DCTCP |
|---|---:|---:|---:|
| 100B latency (us) | 17.81 | 39.11 | 39.73 |
| 500KB throughput (Gbps) | 3.5 | 13.08 | 14.04 |
| Client throughput (Gbps) | 22.24 | 23.12 | 23.09 |
| Server throughput (Gbps) | 22.72 | 23.47 | 23.48 |
| Client RPC rate (Mops/sec) | 0.568 | 0.561 | 0.555 |
| Server RPC rate (Mops/sec) | 1.306 | 1.482 | 1.481 |

## Raw `cp_basic` output used

```text
Homa RTT latency (us): 17.86 (17.91 17.90 17.86 17.81 17.81)
Homa single message throughput (Gbps): 3.3 (3.2 3.5 3.3 3.2 3.4)
Homa client throughput (Gbps): 22.11 (22.24 22.24 22.01 22.11 21.93)
Homa server throughput (Gbps): 22.68 (22.72 22.65 22.63 22.69 22.69)
Homa client RPC throughput (Kops/sec): 558.49 (556.81 557.19 555.98 554.70 567.75)
Homa server RPC throughput (Kops/sec): 1246.02 (1238.20 1214.25 1229.53 1241.85 1306.28)

TCP RTT latency (us): 39.61 (39.93 39.60 39.63 39.11 39.76)
TCP single message throughput (Gbps): 13.05 (13.02 13.04 13.04 13.08 13.08)
TCP client throughput (Gbps): 22.91 (22.68 22.85 22.83 23.08 23.12)
TCP server throughput (Gbps): 23.45 (23.44 23.43 23.45 23.47 23.46)
TCP client RPC throughput (Kops/sec): 556.90 (551.91 555.27 556.14 560.19 560.99)
TCP server RPC throughput (Kops/sec): 1469.91 (1472.48 1462.72 1455.54 1481.98 1476.85)

DCTCP RTT latency (us): 40.01 (40.29 40.17 40.09 39.75 39.73)
DCTCP single message throughput (Gbps): 14.00 (14.00 13.94 14.04 14.00 14.04)
DCTCP client throughput (Gbps): 23.04 (22.99 23.04 23.03 23.07 23.09)
DCTCP server throughput (Gbps): 23.46 (23.47 23.45 23.45 23.47 23.48)
DCTCP client RPC throughput (Kops/sec): 554.13 (553.26 554.93 552.26 554.68 555.50)
DCTCP server RPC throughput (Kops/sec): 1469.79 (1468.07 1465.78 1471.65 1480.74 1462.71)
```

## Paper-style caption text

Table 2: Basic Homa and TCP performance. The top two lines used a single client thread issuing back-to-back requests to a single server. Latency was measured end-to-end at application level with 100-byte requests and responses; throughput was measured with 500 KB requests and responses. For the remaining measurements each client had multiple threads; each thread issued multiple concurrent RPCs. Client performance was measured with a single client node spreading requests across 9 server nodes; server performance was measured with 9 client nodes all issuing requests to a single server node. Throughput was measured with 500 KB requests and responses and counts only message payloads; RPC rate was measured with 100-byte requests and responses.
