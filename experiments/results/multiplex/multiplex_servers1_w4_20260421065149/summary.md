# multiplexing comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + HTTP/2 |
| --- | ---: | ---: |
| RTT p50 (us) | 538.88 | 592.15 |
| RTT p99 (us) | 7,585.04 | 108,788.03 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 318,007.00 | 384,668.00 |
| Retrans segs | 12,770 | 18,923 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 |
