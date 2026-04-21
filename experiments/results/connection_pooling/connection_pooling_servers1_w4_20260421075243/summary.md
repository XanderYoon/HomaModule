# connection pooling comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Connection Pooling (2 conns) | DCTCP + Connection Pooling (4 conns) | DCTCP + Connection Pooling (8 conns) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 126.94 | 339.06 | 337.43 | 308.33 | 341.20 |
| RTT p99 (us) | 13,259.96 | 15,848.79 | 17,227.21 | 17,469.72 | 21,898.26 |
| Runs | 1 | 5 | 5 | 5 | 5 |
| RTT runs | 1 | 5 | 5 | 5 | 5 |
| RTT samples/run | 217,110.00 | 327,479.80 | 322,111.80 | 326,919.40 | 337,144.40 |
| Retrans segs | N/A | 115,374 | 127,426 | 121,238 | 129,593 |
| Qdisc drops | N/A | 107,550 | 131,304 | 154,533 | 202,793 |
| CE packets | N/A | 0 | 0 | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 | 0 | 0 |
