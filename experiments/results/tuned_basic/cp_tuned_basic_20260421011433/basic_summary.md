# cp_tuned_basic Summary

Source run: `experiments/results/tuned_basic/cp_tuned_basic_20260421011433`

Method:
- This table mirrors the cp_basic presentation style but compares Homa against a single tuned DCTCP configuration.
- The tuned DCTCP variant uses HTTP/2-style multiplexing and TCP connection pooling.
- Each row uses the best per-second value recorded during the timed experiment window.
- For latency that means the minimum sample; for throughput it means the maximum sample.

| Metric | Homa | Tuned DCTCP |
|---|---:|---:|
| 100B latency (us) | 14.04 | 23.80 |
| 500KB throughput (Gbps) | 8.8 | 18.28 |
| Client throughput (Gbps) | 22.67 | 14.03 |
| Server throughput (Gbps) | 22.70 | 23.38 |

## Raw output used

```text
Homa RTT latency (us): 14.04 (14.05 14.04)
Homa single message throughput (Gbps): 8.7 (8.8 8.6)
Homa client throughput (Gbps): 22.62 (22.57 22.67)
Homa server throughput (Gbps): 22.66 (22.70 22.62)
Tuned DCTCP RTT latency (us): 24.00 (24.19 23.80)
Tuned DCTCP single message throughput (Gbps): 18.26 (18.28 18.24)
Tuned DCTCP client throughput (Gbps): 14.00 (13.98 14.03)
Tuned DCTCP server throughput (Gbps): 23.19 (23.00 23.38)
```

## Caption

cp_basic-style summary for Homa versus tuned DCTCP on a 5-node CloudLab setup. The tuned DCTCP side uses HTTP/2 multiplexing with 4 sessions, connection pooling with pool size 1, and TCP Fast Open disabled. The top two rows use a single client issuing back-to-back requests to a single server with 100-byte requests/responses for latency and 500 KB requests/responses for throughput. The remaining rows measure large-message throughput for single-client and single-server cases. Each table entry is the best value observed among the per-second samples during the timed phase.
