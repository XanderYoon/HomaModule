# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 123.67 | 456.93 |
| RTT p99 (us) | 11,790.15 | 9,257.35 |
| Runs | 5 | 5 |
| RTT runs | 5 | 5 |
| RTT samples/run | 215,406.80 | 310,248.40 |
| Retrans segs | N/A | 28,238 |
| Qdisc drops | N/A | 16,311 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
