# cp_basic Summary

Source run: `experiments/results/basic/cp_basic_20260421011057`

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
| 100B latency (us) | 14.80 | 25.71 | 24.27 |
| 500KB throughput (Gbps) | 9.5 | 18.62 | 17.96 |
| Client throughput (Gbps) | 22.71 | 23.17 | 23.20 |
| Server throughput (Gbps) | 22.70 | 23.29 | 23.26 |
| Client RPC rate (Mops/sec) | 1.601 | 0.604 | 0.603 |
| Server RPC rate (Mops/sec) | 1.217 | 1.015 | 1.043 |

## Raw `cp_basic` output used

```text
Homa RTT latency (us): 14.86 (14.80 14.91)
Homa single message throughput (Gbps): 9.3 (9.5 9.0)
Homa client throughput (Gbps): 22.67 (22.71 22.63 22.68)
Homa server throughput (Gbps): 22.66 (22.63 22.70)
Homa client RPC throughput (Kops/sec): 1544.68 (1488.48 1600.89)
Homa server RPC throughput (Kops/sec): 1212.86 (1208.68 1217.04)

TCP RTT latency (us): 26.01 (25.71 26.30)
TCP single message throughput (Gbps): 18.35 (18.08 18.62)
TCP client throughput (Gbps): 23.14 (23.11 23.17)
TCP server throughput (Gbps): 23.27 (23.26 23.29)
TCP client RPC throughput (Kops/sec): 577.73 (551.49 603.96)
TCP server RPC throughput (Kops/sec): 1010.71 (1006.08 1015.34)

DCTCP RTT latency (us): 24.34 (24.40 24.27)
DCTCP single message throughput (Gbps): 17.12 (16.28 17.96)
DCTCP client throughput (Gbps): 23.19 (23.18 23.20)
DCTCP server throughput (Gbps): 23.26 (23.26 23.26)
DCTCP client RPC throughput (Kops/sec): 592.05 (580.87 603.23)
DCTCP server RPC throughput (Kops/sec): 1039.26 (1042.93 1035.58)
```

## Paper-style caption text

Table 2 style summary for the 5-node CloudLab setup. The top two rows use a single client issuing back-to-back requests to a single server with 100-byte requests/responses for latency and 500 KB requests/responses for throughput. The remaining rows use multi-threaded clients with multiple concurrent RPCs. Client-side metrics are measured with the designated single client node sending to the remaining server-capable nodes. Throughput counts payload bytes only. RPC rate is measured with 100-byte requests and responses. Each table entry is the best value observed among the per-second samples during the timed phase of `cp_basic`.
