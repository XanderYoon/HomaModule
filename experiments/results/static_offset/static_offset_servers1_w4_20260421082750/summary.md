# static scheduler comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Static Scheduler (10 us) | DCTCP + Static Scheduler (20 us) | DCTCP + Static Scheduler (30 us) | DCTCP + Static Scheduler (50 us) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 125.82 | 405.45 | 132.20 | 95.24 | 82.17 | 68.03 |
| RTT p99 (us) | 12,825.35 | 20,209.19 | 8,232.90 | 7,238.56 | 7,877.21 | 7,818.54 |
| Runs | 1 | 5 | 5 | 5 | 5 | 5 |
| RTT runs | 1 | 5 | 5 | 5 | 5 | 5 |
| RTT samples/run | 215,587.00 | 314,072.00 | 263,101.00 | 207,244.00 | 174,894.00 | 128,091.00 |
| Retrans segs | N/A | 117,592 | 93,603 | 76,202 | 65,780 | 46,758 |
| Qdisc drops | N/A | 35,393 | 23,266 | 18,964 | 13,767 | 10,754 |
| CE packets | N/A | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 | 0 | 0 | 0 |
