# Homa vs DCTCP vs static scheduler + load-aware comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Static Scheduler + Load-Aware |
| --- | ---: | ---: | ---: |
| RTT p50 (us) | 126.36 | 346.13 | 96.34 |
| RTT p99 (us) | 12,699.79 | 16,901.12 | 8,300.66 |
| Runs | 5 | 5 | 5 |
| RTT runs | 5 | 5 | 5 |
| RTT samples/run | 215,450.00 | 328,943.20 | 217,513.60 |
| Retrans segs | N/A | 120,734 | 79,829 |
| Qdisc drops | N/A | 125,547 | 57,812 |
| CE packets | N/A | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 |
