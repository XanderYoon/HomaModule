# load-aware comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Load-Aware |
| --- | ---: | ---: |
| RTT p50 (us) | 504.98 | 557.95 |
| RTT p99 (us) | 7,032.92 | 6,218.31 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 306,433.00 | 305,812.00 |
| Retrans segs | 14,189 | 13,913 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 |
