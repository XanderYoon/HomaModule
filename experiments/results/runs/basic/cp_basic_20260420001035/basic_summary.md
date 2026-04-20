# cp_basic Summary

Source run: `experiments/results/runs/basic/cp_basic_20260420001035`

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
| 100B latency (us) | 14.71 | 22.88 | 22.12 |
| 500KB throughput (Gbps) | 8.2 | 18.68 | 18.72 |
| Client throughput (Gbps) | 22.72 | 23.22 | 23.20 |
| Server throughput (Gbps) | 22.73 | 23.30 | 23.29 |
| Client RPC rate (Mops/sec) | 1.563 | 0.611 | 0.612 |
| Server RPC rate (Mops/sec) | 1.225 | 1.042 | 1.062 |

## Raw `cp_basic` output used

```text
Homa RTT latency (us): 14.73 (14.75 14.71 14.71 14.74 14.72)
Homa single message throughput (Gbps): 7.9 (8.2 7.8 7.9 7.8 7.8)
Homa client throughput (Gbps): 22.67 (22.66 22.71 22.72 22.63 22.64)
Homa server throughput (Gbps): 22.69 (22.58 22.71 22.71 22.73 22.72)
Homa client RPC throughput (Kops/sec): 1531.58 (1497.74 1531.59 1563.30 1532.67 1532.62)
Homa server RPC throughput (Kops/sec): 1222.78 (1215.53 1224.31 1224.36 1224.81 1224.88)

TCP RTT latency (us): 23.63 (24.16 23.95 23.80 23.35 22.88)
TCP single message throughput (Gbps): 18.38 (17.86 18.46 18.54 18.36 18.68)
TCP client throughput (Gbps): 23.19 (23.12 23.21 23.20 23.22 23.18)
TCP server throughput (Gbps): 23.23 (22.98 23.25 23.30 23.28 23.30 23.30)
TCP client RPC throughput (Kops/sec): 599.88 (560.22 607.65 610.68 610.84 610.01)
TCP server RPC throughput (Kops/sec): 1038.46 (1040.04 1033.65 1041.56 1037.26 1039.77)

DCTCP RTT latency (us): 22.27 (22.46 22.30 22.16 22.12 22.33)
DCTCP single message throughput (Gbps): 18.62 (18.64 18.70 18.72 18.70 18.36)
DCTCP client throughput (Gbps): 23.17 (23.08 23.17 23.20 23.18 23.20)
DCTCP server throughput (Gbps): 23.28 (23.26 23.28 23.29 23.28 23.29)
DCTCP client RPC throughput (Kops/sec): 608.20 (602.14 612.12 609.39 609.75 607.59)
DCTCP server RPC throughput (Kops/sec): 1057.11 (1053.33 1060.86 1061.56 1057.55 1052.24)
```

## Paper-style caption text

Table 2 style summary for the 5-node CloudLab setup. The top two rows use a single client issuing back-to-back requests to a single server with 100-byte requests/responses for latency and 500 KB requests/responses for throughput. The remaining rows use multi-threaded clients with multiple concurrent RPCs. Client-side metrics are measured with the designated single client node sending to the remaining server-capable nodes. Throughput counts payload bytes only. RPC rate is measured with 100-byte requests and responses. Each table entry is the best value observed among the per-second samples during the timed phase of `cp_basic`.
