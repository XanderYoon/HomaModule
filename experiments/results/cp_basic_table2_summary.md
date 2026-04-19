# cp_basic Table 2 Style Summary

Source run: `experiments/results/runs/baseline/cp_basic_20260418151857`

Method:
- This table follows the presentation style of Table 2 in the Homa paper.
- `cp_basic` prints one aggregate average followed by the individual 5-second run values in parentheses.
- To mirror the paper's "best average across five 5-second runs" wording as closely as possible, the table below uses the best per-run value from the printed samples:
  - latency: minimum value
  - throughput and RPC rate: maximum value
- RPC rates are shown in `Mops/sec`, converted from the `Kops/sec` values printed by `cp_basic`.

| Metric | Homa | TCP | DCTCP |
|---|---:|---:|---:|
| 100B latency (us) | 18.02 | 41.45 | 41.94 |
| 500KB throughput (Gbps) | 3.9 | 13.66 | 13.54 |
| Client throughput (Gbps) | 22.35 | 23.03 | 23.13 |
| Server throughput (Gbps) | 22.71 | 23.47 | 23.46 |
| Client RPC rate (Mops/sec) | 0.569 | 0.557 | 0.560 |
| Server RPC rate (Mops/sec) | 1.214 | 1.472 | 1.486 |

## Raw `cp_basic` output used

```text
Homa RTT latency (us): 18.04 (18.05 18.03 18.06 18.04 18.02)
Homa single message throughput (Gbps): 3.5 (3.5 3.9 3.6 3.2 3.2)
Homa client RPC throughput (Kops/sec): 555.98 (553.07 557.47 543.39 569.05 556.92)
Homa server RPC throughput (Kops/sec): 1152.54 (1078.73 1200.87 1127.79 1214.04 1141.25)
Homa client throughput (Gbps): 22.29 (22.31 22.35 22.31 22.26 22.24)
Homa server throughput (Gbps): 22.68 (22.71 22.66 22.68 22.67 22.67)

TCP RTT latency (us): 41.70 (41.89 41.86 41.72 41.60 41.45)
TCP single message throughput (Gbps): 13.64 (13.64 13.66 13.62 13.66 13.62)
TCP client RPC throughput (Kops/sec): 553.24 (551.74 552.81 549.26 555.41 556.97)
TCP server RPC throughput (Kops/sec): 1429.89 (1400.99 1415.10 1400.85 1460.83 1471.67)
TCP client throughput (Gbps): 22.78 (22.45 22.74 22.73 22.96 23.03)
TCP server throughput (Gbps): 23.44 (23.39 23.43 23.44 23.45 23.47)

DCTCP RTT latency (us): 42.01 (41.94 41.97 41.95 42.02 42.15)
DCTCP single message throughput (Gbps): 13.47 (13.46 13.46 13.46 13.44 13.54)
DCTCP client RPC throughput (Kops/sec): 557.52 (556.68 556.90 558.09 560.13 555.81)
DCTCP server RPC throughput (Kops/sec): 1479.46 (1476.59 1477.25 1478.41 1478.68 1486.38)
DCTCP client throughput (Gbps): 23.10 (23.11 23.09 23.13 23.10 23.07)
DCTCP server throughput (Gbps): 23.45 (23.45 23.46 23.46 23.44 23.46)
```

## Paper-style caption text

Table 2 style summary for the 5-node CloudLab setup. The top two rows use a single client issuing back-to-back requests to a single server with 100-byte requests/responses for latency and 500 KB requests/responses for throughput. The remaining rows use multi-threaded clients with multiple concurrent RPCs. Client performance is measured with one client node sending to four server nodes in the available 5-node configuration, and server performance is measured with four client nodes sending to one server node. Throughput counts payload bytes only. RPC rate is measured with 100-byte requests and responses. Each table entry is the best value observed among the 5-second runs reported by `cp_basic`.
