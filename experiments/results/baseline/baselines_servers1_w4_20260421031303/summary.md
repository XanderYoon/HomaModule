# Baselines Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP |
| --- | ---: | ---: |
| RTT p50 (us) | 125.87 | 73,111.57 |
| RTT p99 (us) | 386,250.00 | 1,153,722.61 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 195,819.00 | 47,113.00 |
| Retrans segs | N/A | 21,250 |
| Qdisc drops | N/A | 4 |
| CE packets | N/A | 1 |
| CE/ECT | N/A | 0.000% |
| Qdisc ECN marks | N/A | 5 |
