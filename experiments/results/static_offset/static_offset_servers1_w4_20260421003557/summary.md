# static offset tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Static Offset 0 us | DCTCP + Static Offset 5 us | DCTCP + Static Offset 10 us | DCTCP + Static Offset 25 us | DCTCP + Static Offset 50 us |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 2,696.24 | 5,317.53 | 11,857.59 | 294,787.52 | 1,120,790.15 | 1,269,847.03 |
| RTT p99 (us) | 1,040,410.42 | 1,064,975.35 | 1,111,409.06 | 6,127,598.13 | 12,228,412.15 | 10,295,878.40 |
| Runs | 1 | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 53,494.00 | 49,907.00 | 58,873.00 | 9,869.00 | 6,848.00 | 6,143.00 |
| Retrans segs | 8,844 | 11,685 | 15,518 | 8,223 | 2,468 | 2,735 |
| Qdisc drops | 3,523 | 8,014 | 13,271 | 15,586 | 17,088 | 18,356 |
| CE packets | 0 | 0 | 0 | 0 | 0 | 0 |
| CE/ECT | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% | 0.000% |
| Qdisc ECN marks | 0 | 0 | 0 | 0 | 0 | 0 |
