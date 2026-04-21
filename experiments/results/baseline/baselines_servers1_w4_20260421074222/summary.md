# DCTCP Tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 125.22 | 328.73 |
| RTT p99 (us) | 13,169.13 | 15,766.68 |
| Runs | 5 | 5 |
| RTT runs | 5 | 5 |
| RTT samples/run | 215,030.40 | 317,166.20 |
| Retrans segs | N/A | 118,287 |
| Qdisc drops | N/A | 113,300 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
