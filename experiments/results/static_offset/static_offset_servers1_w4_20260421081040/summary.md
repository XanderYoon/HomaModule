# static scheduler comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Static Scheduler (2 us) | DCTCP + Static Scheduler (5 us) | DCTCP + Static Scheduler (10 us) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 123.16 | 387.08 | 263.72 | 189.81 | 135.50 |
| RTT p99 (us) | 12,441.71 | 43,220.62 | 14,511.55 | 10,676.51 | 8,999.61 |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 213,800.00 | 347,318.00 | 311,101.00 | 281,646.00 | 265,074.00 |
| Retrans segs | N/A | 122,496 | 113,307 | 105,810 | 97,822 |
| Qdisc drops | N/A | 42,757 | 32,637 | 28,159 | 23,912 |
| CE packets | N/A | 0 | 0 | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 | 0 | 0 |
