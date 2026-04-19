# cp_basic Table 2 Style Summary

Source run: `experiments/results/runs/baseline/cp_basic_servers1_20260419154152`

Method:
- This table follows the presentation style of Table 2 in the Homa paper.
- The summary is generated automatically from the fetched `node-*.log` files in the selected `cp_basic` run.
- Each row uses the per-second samples recorded during the timed experiment window only.
- To mirror the paper's "best average across five 5-second runs" wording as closely as possible, the table below uses the best per-sample value:
  - latency: minimum value
  - throughput and RPC rate: maximum value
- RPC rates are shown in `Mops/sec`, converted from the `Kops/sec` samples.

| Metric | Homa | TCP | DCTCP |
|---|---:|---:|---:|
| 100B latency (us) | 17.89 | 37.18 | 40.01 |
| 500KB throughput (Gbps) | 3.9 | 13.44 | 13.16 |
| Client throughput (Gbps) | 21.80 | 22.92 | 23.14 |
| Server throughput (Gbps) | 22.65 | 23.46 | 23.48 |
| Client RPC rate (Mops/sec) | 0.543 | 0.561 | 0.555 |
| Server RPC rate (Mops/sec) | 1.294 | 1.474 | 1.473 |

## Raw `cp_basic` output used

```text
Homa RTT latency (us): 17.90 (17.90 17.89 17.91 17.91 17.89)
Homa single message throughput (Gbps): 3.7 (3.9 3.8 3.9 3.3 3.4)
Homa client throughput (Gbps): 21.44 (21.51 21.58 21.80 21.22 21.11)
Homa server throughput (Gbps): 22.61 (22.65 22.63 22.62 22.63 22.52)
Homa client RPC throughput (Kops/sec): 524.26 (520.47 517.23 519.82 520.39 543.39)
Homa server RPC throughput (Kops/sec): 1215.58 (1137.75 1195.48 1206.22 1244.69 1293.75)

TCP RTT latency (us): 39.28 (40.82 40.33 39.09 38.98 37.18)
TCP single message throughput (Gbps): 13.31 (13.26 13.44 13.26 13.26 13.32)
TCP client throughput (Gbps): 22.79 (22.52 22.79 22.83 22.92 22.91)
TCP server throughput (Gbps): 23.44 (23.43 23.41 23.46 23.46 23.46)
TCP client RPC throughput (Kops/sec): 556.83 (552.88 556.46 556.65 560.75 557.41)
TCP server RPC throughput (Kops/sec): 1470.09 (1469.73 1473.35 1468.13 1465.69 1473.55)

DCTCP RTT latency (us): 40.50 (41.26 40.56 40.48 40.01 40.17)
DCTCP single message throughput (Gbps): 13.10 (13.12 13.08 13.10 13.16 13.06)
DCTCP client throughput (Gbps): 23.07 (22.95 23.04 23.11 23.10 23.14)
DCTCP server throughput (Gbps): 23.46 (23.45 23.45 23.46 23.48 23.46)
DCTCP client RPC throughput (Kops/sec): 553.42 (555.23 553.26 554.44 551.60 552.56)
DCTCP server RPC throughput (Kops/sec): 1465.65 (1468.41 1455.18 1464.17 1473.23 1467.24)
```

## Paper-style caption text

Table 2 style summary for the 10-node CloudLab dedicated-server setup (`--servers 1`). The top two rows use a single client issuing back-to-back requests to a single server with 100-byte requests/responses for latency and 500 KB requests/responses for throughput. The remaining rows use multi-threaded clients with multiple concurrent RPCs. Client performance is measured with a single client node spreading requests across 9 server nodes, and server performance is measured with the remaining client nodes all issuing requests to a single server node. Throughput counts payload bytes only. RPC rate is measured with 100-byte requests and responses. Each table entry is the best value observed among the per-second samples during the timed phase of `cp_basic`.
