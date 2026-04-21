# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) | DCTCP + Connection Pooling (pool 16) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 2,556.66 | 13,623.54 | 19,511.59 | 16,761.35 | 15,101.53 |
| RTT p99 (us) | 1,040,898.94 | 104,124.12 | 226,414.95 | 275,782.27 | 290,560.12 |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 53,212.00 | 283,051.00 | 193,458.00 | 191,080.00 | 207,750.00 |
| Retrans segs | 9,501 | 40,072 | 29,400 | 28,111 | 30,577 |
| Qdisc drops | 3,528 | 9,583 | 16,126 | 23,922 | 34,677 |
| CE packets | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 | 0 | 0 | 0 |
