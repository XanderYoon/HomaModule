# Experiment Assets

Latest counter-enabled DCTCP transport run:
- `experiments/results/runs/transport/cp_transport_w4_20260401234144`

Key artifacts copied here:
- `charts/vs_tcp_w4_p99_counters_run.pdf`
- `charts/short_cdf_w4_counters_run.pdf`
- `logs/cp_transport_w4_20260401234144.cperf.log`
- `counters/*.tcp_counters`
- `counters/*.qdisc`
- `data/dctcp*_w4.data`
- `dctcp/dctcp*_w4-*.rtts`

Most important new evidence:
- each DCTCP-family experiment now has a `reports/<experiment>.tcp_counters`
  file with before/after kernel counter deltas
- `cperf.log` now prints aggregate per-experiment summaries such as:
  - `IpExtInECT0Pkts`
  - `TcpRetransSegs`
  - `TcpExtTCPLostRetransmit`
  - `TcpExtTCPFastRetrans`
  - `TcpExtTCPTimeouts`
  - TFO-related counters when applicable

Important caveat from the latest run:
- `TcpExtTCPDeliveredCE` and `IpExtInCEPkts` stayed at `0` in this run
- the saved `*.qdisc` files do not show netem-induced drops/marks for the
  staggered case because the `tc` setup is still not clean on this cluster
  (`RTNETLINK answers: No such device` is still present in the log)
