# static scheduler comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Static Scheduler (5 us) | DCTCP + Static Scheduler (10 us) | DCTCP + Static Scheduler (15 us) | DCTCP + Static Scheduler (20 us) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 128.31 | 343.49 | 188.38 | 136.11 | 110.68 | 96.21 |
| RTT p99 (us) | 12,143.30 | 15,861.49 | 10,524.27 | 8,995.80 | 8,153.42 | 8,066.93 |
| Runs | 1 | 5 | 5 | 5 | 5 | 5 |
| RTT runs | 1 | 5 | 5 | 5 | 5 | 5 |
| RTT samples/run | 216,758.00 | 319,717.80 | 281,886.00 | 256,589.40 | 235,274.80 | 212,670.80 |
| Retrans segs | N/A | 116,242 | 103,620 | 94,243 | 86,506 | 77,680 |
| Qdisc drops | N/A | 113,223 | 93,539 | 81,056 | 65,525 | 58,046 |
| CE packets | N/A | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 | 0 | 0 | 0 |
