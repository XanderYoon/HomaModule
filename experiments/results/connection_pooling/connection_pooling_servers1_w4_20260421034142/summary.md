# connection pooling tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Connection Pooling (pool 1) | DCTCP + Connection Pooling (pool 4) | DCTCP + Connection Pooling (pool 8) | DCTCP + Connection Pooling (pool 16) |
| --- | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 408,792.78 | 18,868.81 | 8,258.53 | 36,251.42 | 81,655.24 |
| RTT p99 (us) | 2,786,947.91 | 4,659,229.86 | 6,693,984.26 | 6,262,559.74 | 6,100,073.39 |
| Runs | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 10,640.00 | 17,563.00 | 21,179.00 | 16,854.00 | 12,580.00 |
| Retrans segs | 4,495 | 2,385 | 5,416 | 6,090 | 4,929 |
| Qdisc drops | 6 | 6 | 8 | 14 | 18 |
| CE packets | 18 | 123 | 43 | 7,901 | 23,393 |
| CE/ECT | 0.002% | 0.009% | 0.002% | 0.763% | 2.431% |
| Qdisc ECN marks | 1,551 | 1,970 | 2,058 | 7,292 | 25,070 |
