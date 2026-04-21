# TFO comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + TFO |
| --- | ---: | ---: |
| RTT p50 (us) | 633.94 | 576.68 |
| RTT p99 (us) | 6,501.56 | 9,190.20 |
| Runs | 1 | 1 |
| RTT runs | 1 | 1 |
| RTT samples/run | 314,896.00 | 305,666.00 |
| Retrans segs | 21,443 | 33,946 |
| Qdisc drops | 0 | 0 |
| CE packets | 0 | 0 |
| CE/ECT | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 |
