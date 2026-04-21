# HTTP/2 tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + HTTP/2 (sessions 1) | DCTCP + HTTP/2 (sessions 2) | DCTCP + HTTP/2 (sessions 4) | DCTCP + HTTP/2 (sessions 8) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 2,989.73 | 8,448.23 | N/A | N/A | N/A |
| RTT p99 (us) | 1,039,070.67 | 122,215.36 | N/A | N/A | N/A |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 0 | 0 | 0 |
| RTT samples/run | 62,697.00 | 297,554.00 | N/A | N/A | N/A |
| Retrans segs | 10,819 | 47,334 | 1 | 1 | 6 |
| Qdisc drops | 3,920 | 16,662 | 17,750 | 17,755 | 17,763 |
| CE packets | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 | 0 | 0 | 0 |
