# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) |
| --- | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 31,096.23 | 10,783.09 | 8,213.37 | 7,764.80 |
| RTT p99 (us) | 273,769.16 | 160,932.20 | 221,973.78 | 248,143.64 |
| Runs | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 |
| RTT samples/run | 114,930.00 | 299,291.00 | 332,255.00 | 298,469.00 |
| Retrans segs | 29,387 | 69,289 | 83,260 | 80,499 |
| Qdisc drops | 0 | 0 | 0 | 0 |
| CE packets | 0 | 31 | 39 | 48 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 12 | 52 | 88 |
