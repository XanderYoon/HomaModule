# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 125.67 | 375.53 |
| RTT p99 (us) | 11,863.37 | 16,383.45 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 217,185.00 | 309,138.00 |
| Retrans segs | N/A | 120,779 |
| Qdisc drops | N/A | 29,953 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
