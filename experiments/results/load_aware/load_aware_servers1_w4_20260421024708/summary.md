# load-aware tuning Summary

Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment.
TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available.

## w4

Latency percentiles below are averages across repeated runs.
| Metric | DCTCP | DCTCP + Load-Aware |
| --- | ---: | ---: |
| RTT p50 (us) | 30,322.00 | 3,103.34 |
| RTT p99 (us) | 271,015.84 | 1,042,470.81 |
| Runs | 5 | 5 |
| RTT runs | 1 | 1 |
| RTT samples/run | 53,463.00 | 61,181.00 |
| Retrans segs | 26,309 | 32,846 |
