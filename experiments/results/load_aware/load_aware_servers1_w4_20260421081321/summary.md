# load-aware comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + Load-Aware |
| --- | ---: | ---: | ---: |
| RTT p50 (us) | 123.61 | 342.04 | 332.43 |
| RTT p99 (us) | 11,388.00 | 16,556.68 | 15,940.72 |
| Runs | 1 | 5 | 5 |
| RTT runs | 1 | 5 | 5 |
| RTT samples/run | 214,818.00 | 321,809.80 | 328,372.60 |
| Retrans segs | N/A | 117,057 | 116,826 |
| Qdisc drops | N/A | 106,416 | 112,153 |
| CE packets | N/A | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 |
