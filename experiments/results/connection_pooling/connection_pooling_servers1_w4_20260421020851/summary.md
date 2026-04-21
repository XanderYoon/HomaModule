# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) | DCTCP + Connection Pooling (pool 16) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | N/A | N/A | N/A | N/A | N/A |
| RTT p99 (us) | N/A | N/A | N/A | N/A | N/A |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 0 | 0 | 0 | 0 | 0 |
| RTT samples/run | N/A | N/A | N/A | N/A | N/A |
| Retrans segs | 1 | 0 | 0 | 0 | 0 |
| Qdisc drops | 0 | 0 | 0 | 0 | 0 |
| CE packets | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 | 0 | 0 | 0 |
