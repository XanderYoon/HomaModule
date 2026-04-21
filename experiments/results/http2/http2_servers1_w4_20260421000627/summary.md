# HTTP/2 tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + HTTP/2 (sessions 1) | DCTCP + HTTP/2 (sessions 2) | DCTCP + HTTP/2 (sessions 4) | DCTCP + HTTP/2 (sessions 8) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 3,754.03 | 58,921.21 | 15,566.82 | 17,520.38 | 14,303.48 |
| RTT p99 (us) | 1,041,766.95 | 4,163,957.87 | 2,086,576.84 | 1,131,015.32 | 2,102,585.32 |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 64,101.00 | 8,109.00 | 5,030.00 | 7,977.00 | 7,776.00 |
| Retrans segs | 11,947 | 2,679 | 1,539 | 2,255 | 2,150 |
| Qdisc drops | 24,449 | 26,381 | 26,804 | 27,390 | 27,998 |
| CE packets | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 | 0 | 0 | 0 |
