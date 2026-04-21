# Tuned baseline Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 81.78 | 3,091.51 |
| RTT p99 (us) | 4,490,977.21 | 1,044,358.70 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 29,400.00 | 51,492.00 |
| Retrans segs | N/A | 9,472 |
| Qdisc drops | N/A | 38,713 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
