# connection pooling comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling |
| --- | ---: | ---: |
| RTT p50 (us) | 462.10 | 507.44 |
| RTT p99 (us) | 5,769.20 | 6,307.19 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 308,106.00 | 313,748.00 |
| Retrans segs | 8,334 | 21,003 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 |
