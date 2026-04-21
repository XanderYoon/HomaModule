# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 157.42 | 33,427.29 |
| RTT p99 (us) | 92,253.49 | 274,834.06 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 218,048.00 | 115,478.00 |
| Retrans segs | N/A | 29,356 |
| Qdisc drops | N/A | 0 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
