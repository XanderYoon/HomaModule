# static scheduler comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Static Offset |
| --- | ---: | ---: |
| RTT p50 (us) | 589.49 | 184.79 |
| RTT p99 (us) | 7,651.39 | 2,975.01 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 310,583.00 | 248,754.00 |
| Retrans segs | 12,273 | 8,152 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 |
