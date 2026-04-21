# TFO comparison Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | Homa | DCTCP | DCTCP + TFO |
| --- | ---: | ---: | ---: |
| RTT p50 (us) | 123.89 | 340.04 | 349.49 |
| RTT p99 (us) | 11,419.48 | 17,514.21 | 21,280.04 |
| Runs | 1 | 5 | 5 |
| RTT runs | 1 | 5 | 5 |
| RTT samples/run | 215,011.00 | 325,368.00 | 318,287.40 |
| Retrans segs | N/A | 119,758 | 117,485 |
| Qdisc drops | N/A | 117,567 | 107,578 |
| CE packets | N/A | 0 | 0 |
| CE/ECT | N/A | 0.000% | 0.000% |
| Qdisc ECN marks | N/A | 0 | 0 |
