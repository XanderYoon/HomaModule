# HTTP/2 tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + HTTP/2 (sessions 1) | DCTCP + HTTP/2 (sessions 2) | DCTCP + HTTP/2 (sessions 4) | DCTCP + HTTP/2 (sessions 8) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 12,236.78 | 30,017.53 | N/A | N/A | N/A |
| RTT p99 (us) | 1,104,827.15 | 468,867.58 | N/A | N/A | N/A |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 0 | 0 | 0 |
| RTT samples/run | 52,788.00 | 124,589.00 | N/A | N/A | N/A |
| Retrans segs | 12,851 | 19,125 | 1 | 0 | 0 |
| Qdisc drops | 22,567 | 30,023 | 30,576 | 30,580 | 30,582 |
| CE packets | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 | 0 | 0 | 0 |
