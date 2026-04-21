# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 120.62 | 2,687.41 |
| RTT p99 (us) | 9,911.72 | 1,041,557.61 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 216,692.00 | 55,042.00 |
| Retrans segs | N/A | 9,854 |
| Qdisc drops | N/A | 3,824 |
| CE packets | N/A | 0 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 0 |
