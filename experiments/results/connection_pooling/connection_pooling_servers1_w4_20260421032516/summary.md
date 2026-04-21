# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) | DCTCP + Connection Pooling (pool 16) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 92,048.63 | 9,911.39 | 7,070.21 | 8,727.54 | 8,233.57 |
| RTT p99 (us) | 651,211.17 | 1,426,043.02 | 2,045,062.84 | 1,976,817.12 | 2,118,070.45 |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 45,997.00 | 85,719.00 | 88,889.00 | 89,421.00 | 75,744.00 |
| Retrans segs | 18,182 | 8,595 | 13,234 | 13,597 | 17,331 |
| Qdisc drops | 0 | 0 | 0 | 0 | 0 |
| CE packets | 0 | 196 | 105 | 82 | 42 |
| CE/ECT | 0.000% | 0.003% | 0.002% | 0.001% | 0.001% |
| Qdisc ECN marks | 1 | 51 | 90 | 147 | 244 |
