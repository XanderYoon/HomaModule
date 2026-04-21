# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) | DCTCP + Connection Pooling (pool 16) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 64,671.61 | 19,918.58 | 7,984.94 | 8,623.73 | 3,964.64 |
| RTT p99 (us) | 533,763.00 | 719,795.00 | 1,664,151.88 | 2,043,066.92 | 2,608,621.93 |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 64,336.00 | 154,101.00 | 112,422.00 | 132,669.00 | 70,824.00 |
| Retrans segs | 22,797 | 9,631 | 11,048 | 14,038 | 11,192 |
| Qdisc drops | 0 | 0 | 0 | 0 | 0 |
| CE packets | 0 | 1,336 | 767 | 669 | 0 |
| CE/ECT | 0.000% | 0.014% | 0.011% | 0.008% | 0.000% |
| Qdisc ECN marks | 274 | 504 | 842 | 1,219 | 1,342 |
