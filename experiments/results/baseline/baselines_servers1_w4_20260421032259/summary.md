# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 129.82 | 46,471.04 |
| RTT p99 (us) | 13,539.52 | 377,075.90 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 215,505.00 | 88,314.00 |
| Retrans segs | N/A | 25,145 |
| Qdisc drops | N/A | 0 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
