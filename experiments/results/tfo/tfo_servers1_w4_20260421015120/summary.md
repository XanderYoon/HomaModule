# TFO comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + TFO |
| --- | ---: | ---: |
| RTT p50 (us) | 30,358.41 | 17,622.71 |
| RTT p99 (us) | 271,016.59 | 2,737,499.59 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 121,875.00 | 47,186.00 |
| Retrans segs | 25,313 | 58,657 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 15 |
