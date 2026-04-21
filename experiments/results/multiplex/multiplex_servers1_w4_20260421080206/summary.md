# multiplexing comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Multiplexing (2 sessions) | DCTCP + Multiplexing (4 sessions) | DCTCP + Multiplexing (8 sessions) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 125.67 | 354.91 | 354.54 | 389.93 | 369.63 |
| RTT p99 (us) | 12,776.00 | 20,193.71 | 102,426.80 | 72,747.33 | 86,937.79 |
| Runs | 1 | 5 | 5 | 5 | 5 |
| RTT runs | 1 | 5 | 5 | 5 | 5 |
| RTT samples/run | 215,486.00 | 327,536.60 | 385,880.20 | 386,599.00 | 380,004.80 |
| Retrans segs | N/A | 118,845 | 125,500 | 128,577 | 125,167 |
| Qdisc drops | N/A | 108,112 | 148,882 | 139,070 | 140,741 |
| CE packets | N/A | 0 | 0 | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 | 0 | 0 |
