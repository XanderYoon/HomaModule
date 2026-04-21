# load-aware tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Load-Aware |
| --- | ---: | ---: |
| RTT p50 (us) | 38,907.26 | 114,753.77 |
| RTT p99 (us) | 500,494.89 | 1,278,165.16 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 80,350.00 | 33,827.00 |
| Retrans segs | 18,270 | 16,394 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 23 |
| CE/ECT | 0.000% | 0.001% |
| Qdisc ECN marks | 0 | 3 |
