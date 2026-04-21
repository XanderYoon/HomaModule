# static offset tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Static Offset 0 us | DCTCP + Static Offset 5 us | DCTCP + Static Offset 10 us | DCTCP + Static Offset 25 us | DCTCP + Static Offset 50 us |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| RTT p50 (us) | 97,253.82 | 175,535.38 | 284,149.02 | 486,813.45 | 594,972.01 | 610,654.44 |
| RTT p99 (us) | 765,164.81 | 1,261,614.80 | 1,918,723.55 | 3,268,258.24 | 4,178,548.93 | 3,946,535.38 |
| Runs | 1 | 1 | 1 | 1 | 1 | 1 |
| RTT runs | 1 | 1 | 1 | 1 | 1 | 1 |
| RTT samples/run | 41,048.00 | 25,067.00 | 16,925.00 | 10,387.00 | 7,074.00 | 9,251.00 |
| Retrans segs | 17,906 | 15,513 | 9,381 | 4,464 | 3,349 | 4,082 |
| Qdisc drops | 6 | 6 | 6 | 6 | 6 | 6 |
| CE packets | 47 | 18 | 50 | 46 | 7 | 12 |
| CE/ECT | 0.001% | 0.001% | 0.003% | 0.006% | 0.001% | 0.002% |
| Qdisc ECN marks | 1,371 | 1,385 | 1,410 | 1,427 | 1,440 | 1,456 |
