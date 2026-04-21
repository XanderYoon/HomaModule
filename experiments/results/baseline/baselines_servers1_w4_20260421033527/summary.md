# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 132.68 | 95,802.91 |
| RTT p99 (us) | 527,891.42 | 704,775.08 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 209,496.00 | 45,745.00 |
| Retrans segs | N/A | 20,317 |
| Qdisc drops | N/A | 6 |
| CE packets | N/A | 9 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 1,348 |
