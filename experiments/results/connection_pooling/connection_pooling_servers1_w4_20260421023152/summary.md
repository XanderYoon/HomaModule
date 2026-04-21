# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) |
| --- | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 36,211.28 | 10,689.41 | 7,804.02 | 7,230.32 |
| RTT p99 (us) | 271,385.89 | 167,654.37 | 234,404.54 | 250,055.04 |
| Runs | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 |
| RTT samples/run | 114,962.00 | 278,461.00 | 294,286.00 | 300,037.00 |
| Retrans segs | 22,237 | 40,467 | 80,706 | 86,166 |
| Qdisc drops | 10 | 10 | 10 | 10 |
| CE packets | 56 | 138 | 67 | 45 |
| CE/ECT | 0.000% | 0.001% | 0.000% | 0.000% |
| Qdisc ECN marks | 281 | 299 | 349 | 391 |
