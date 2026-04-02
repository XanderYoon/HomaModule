# cp_basic Table 2 Style Summary

Source run: `experiments/results/cp_basic_20260401184601`

Method:
- This table follows the presentation style of Table 2 in the Homa paper.
- `cp_basic` prints one aggregate average followed by the individual 5-second run values in parentheses.
- To mirror the paper's "best average across five 5-second runs" wording as closely as possible, the table below uses the best per-run value from the printed samples:
  - latency: minimum value
  - throughput and RPC rate: maximum value
- RPC rates are shown in `Mops/sec`, converted from the `Kops/sec` values printed by `cp_basic`.

| Metric | Homa | TCP | DCTCP |
|---|---:|---:|---:|
| 100B latency (us) | 22.29 | 27.80 | 26.51 |
| 500KB throughput (Gbps) | 6.0 | 19.36 | 19.46 |
| Client throughput (Gbps) | 18.95 | 23.19 | 23.18 |
| Server throughput (Gbps) | 18.33 | 23.11 | 23.14 |
| Client RPC rate (Mops/sec) | 1.367 | 0.653 | 0.642 |
| Server RPC rate (Mops/sec) | 0.824 | 1.004 | 0.996 |

## Raw `cp_basic` output used

```text
Homa RTT latency (us): 22.31 (22.36 22.33 22.30 22.29 22.29)
Homa single message throughput (Gbps): 6.0 (6.0 5.9 6.0 6.0 6.0 6.0)
Homa client RPC throughput (Kops/sec): 1247.58 (1130.26 1311.27 1273.95 1155.63 1366.81)
Homa server RPC throughput (Kops/sec): 811.54 (812.28 804.01 811.27 805.93 824.23)
Homa client throughput (Gbps): 18.71 (18.77 18.64 18.95 18.37 18.84)
Homa server throughput (Gbps): 18.27 (18.29 18.30 18.25 18.33 18.17)

TCP RTT latency (us): 28.07 (27.80 28.24 28.31 27.95)
TCP single message throughput (Gbps): 18.94 (17.70 19.36 19.34 19.36)
TCP client RPC throughput (Kops/sec): 614.12 (594.44 610.44 652.90 608.96 603.86)
TCP server RPC throughput (Kops/sec): 991.51 (958.64 996.48 997.11 1001.15 1004.18)
TCP client throughput (Gbps): 23.16 (23.09 23.16 23.19 23.19)
TCP server throughput (Gbps): 21.12 (13.29 23.00 23.10 23.11 23.11)

DCTCP RTT latency (us): 26.57 (26.54 26.51 26.55 26.69)
DCTCP single message throughput (Gbps): 19.03 (17.76 19.44 19.46 19.44)
DCTCP client RPC throughput (Kops/sec): 628.67 (626.68 641.60 623.56 622.84)
DCTCP server RPC throughput (Kops/sec): 990.09 (979.79 987.29 996.20 991.05 996.14)
DCTCP client throughput (Gbps): 23.17 (23.16 23.16 23.17 23.18)
DCTCP server throughput (Gbps): 21.07 (12.85 23.12 23.11 23.14 23.13)
```

## Paper-style caption text

Table 2 style summary for the 5-node CloudLab setup. The top two rows use a single client issuing back-to-back requests to a single server with 100-byte requests/responses for latency and 500 KB requests/responses for throughput. The remaining rows use multi-threaded clients with multiple concurrent RPCs. Client performance is measured with one client node sending to four server nodes in the available 5-node configuration, and server performance is measured with four client nodes sending to one server node. Throughput counts payload bytes only. RPC rate is measured with 100-byte requests and responses. Each table entry is the best value observed among the 5-second runs reported by `cp_basic`.
