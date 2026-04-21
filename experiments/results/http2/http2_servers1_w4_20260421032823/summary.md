# HTTP/2 tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP |
| --- | ---: |
| RTT p50 (us) | 87,428.38 |
| RTT p99 (us) | 755,626.15 |
| Runs | 1 |
| RTT runs | 1 |
| RTT samples/run | 43,642.00 |
| Retrans segs | 19,795 |
| Qdisc drops | 0 |
| CE packets | 79 |
| CE/ECT | 0.002% |
| Qdisc ECN marks | 274 |
