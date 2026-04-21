# TFO comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + TFO |
| --- | ---: | ---: |
| RTT p50 (us) | 2,651.83 | 41,588.99 |
| RTT p99 (us) | 1,046,203.77 | 1,346,402.60 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 46,037.00 | 68,534.00 |
| Retrans segs | 8,494 | 71,487 |
| Qdisc drops | 39,682 | 47,906 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 |
