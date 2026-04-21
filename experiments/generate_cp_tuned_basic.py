#!/usr/bin/env python3

import argparse
import re
from pathlib import Path


EXPERIMENTS = [
    {
        "protocol": "Homa",
        "experiment": "homa_latency",
        "metric": "100B latency (us)",
        "source": "client",
        "field": "latency",
        "selector": min,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "RTT latency (us)",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_1msg_tput",
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "selector": max,
        "table_format": "{:.1f}",
        "raw_format": "{:.1f}",
        "raw_label": "single message throughput (Gbps)",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_client_tput",
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "selector": max,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "client throughput (Gbps)",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_server_tput",
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "selector": max,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "server throughput (Gbps)",
    },
    {
        "protocol": "Tuned DCTCP",
        "experiment": "tuned_dctcp_latency",
        "metric": "100B latency (us)",
        "source": "client",
        "field": "latency",
        "selector": min,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "RTT latency (us)",
    },
    {
        "protocol": "Tuned DCTCP",
        "experiment": "tuned_dctcp_1msg_tput",
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "selector": max,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "single message throughput (Gbps)",
    },
    {
        "protocol": "Tuned DCTCP",
        "experiment": "tuned_dctcp_client_tput",
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "selector": max,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "client throughput (Gbps)",
    },
    {
        "protocol": "Tuned DCTCP",
        "experiment": "tuned_dctcp_server_tput",
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "selector": max,
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
        "raw_label": "server throughput (Gbps)",
    },
]

START_RE = re.compile(r"Starting (\S+) experiment")
END_RE = re.compile(r"Ending (\S+) experiment")
CLIENT_RE = re.compile(
    r"Clients:\s+([0-9.]+) Kops/sec,\s+([0-9.]+) Gbps, RTT \(us\) P50 ([0-9.]+)"
)
SERVER_RE = re.compile(r"Servers:\s+([0-9.]+) Kops/sec,\s+([0-9.]+) Gbps")
NUM_NODES_RE = re.compile(r"--num_nodes: ([^, ]+)")
HTTP2_RE = re.compile(r"--http2_sessions: ([^, ]+)")
POOL_RE = re.compile(r"--pool_size: ([^, ]+)")
TFO_RE = re.compile(r"--tfo: ([^, ]+)")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate markdown summaries for fetched cp_tuned_basic runs."
    )
    parser.add_argument(
        "run_dir",
        nargs="?",
        default="experiments/results/tuned_basic/latest",
        help="Path to a fetched cp_tuned_basic run directory",
    )
    parser.add_argument(
        "--output",
        default="experiments/results/cp_tuned_basic_table.md",
        help="Output markdown path",
    )
    parser.add_argument(
        "--title",
        default="cp_tuned_basic Summary",
        help="Markdown document title",
    )
    return parser.parse_args()


def resolve_run_dir(run_arg):
    run_dir = Path(run_arg)
    if run_dir.name == "latest":
        resolved = run_dir.resolve()
        if resolved.exists() and resolved.name.startswith("cp_tuned_basic"):
            return resolved
        parent = resolved.parent if resolved.exists() else run_dir.parent.resolve()
        candidates = sorted(parent.glob("cp_tuned_basic*"))
        if candidates:
            return candidates[-1].resolve()
    return run_dir.resolve()


def logs_dir(run_dir):
    candidate = run_dir / "logs"
    return candidate if candidate.is_dir() else run_dir


def parse_node_log(path):
    samples = {}
    current = None
    for line in path.read_text().splitlines():
        start = START_RE.search(line)
        if start:
            current = start.group(1)
            samples.setdefault(current, {"client": [], "server": []})
            continue
        end = END_RE.search(line)
        if end and current == end.group(1):
            current = None
            continue
        if current is None:
            continue
        client = CLIENT_RE.search(line)
        if client:
            samples[current]["client"].append(
                {
                    "kops": float(client.group(1)),
                    "gbps": float(client.group(2)),
                    "gbps_x2": 2.0 * float(client.group(2)),
                    "latency": float(client.group(3)),
                }
            )
            continue
        server = SERVER_RE.search(line)
        if server:
            samples[current]["server"].append(
                {
                    "kops": float(server.group(1)),
                    "gbps": float(server.group(2)),
                    "gbps_x2": 2.0 * float(server.group(2)),
                }
            )
    return samples


def mean(values):
    return sum(values) / len(values)


def format_samples(values, fmt):
    return " ".join(fmt.format(value) for value in values)


def find_node_for_source(node_samples, experiment, source):
    for node_name, samples in sorted(node_samples.items()):
        if samples.get(experiment, {}).get(source):
            return node_name
    raise RuntimeError("could not find %s samples for %s" % (source, experiment))


def read_cperf_option(run_dir, pattern):
    cperf_log = logs_dir(run_dir) / "reports" / "cperf.log"
    if not cperf_log.exists():
        return None
    match = pattern.search(cperf_log.read_text())
    if not match:
        return None
    return match.group(1)


def build_caption(num_nodes, http2_sessions, pool_size, tfo):
    tfo_text = "enabled" if str(tfo).lower() == "true" else "disabled"
    return (
        "cp_basic-style summary for Homa versus tuned DCTCP on a "
        "%s-node CloudLab setup. The tuned DCTCP side uses HTTP/2 "
        "multiplexing with %s sessions, connection pooling with pool size %s, "
        "and TCP Fast Open %s. The top two rows use a single client issuing "
        "back-to-back requests to a single server with 100-byte "
        "requests/responses for latency and 500 KB requests/responses for "
        "throughput. The remaining rows measure large-message throughput for "
        "single-client and single-server cases. Each table entry is the best "
        "value observed among the per-second samples during the timed phase."
        % (num_nodes or "unknown", http2_sessions or "unknown",
        pool_size or "unknown", tfo_text)
    )


def main():
    args = parse_args()
    run_dir = resolve_run_dir(args.run_dir)
    if not run_dir.exists():
        raise SystemExit("run directory not found: %s" % (run_dir))

    data_dir = logs_dir(run_dir)
    node_logs = sorted(data_dir.glob("node-*.log"))
    if not node_logs:
        raise SystemExit("no node logs found in %s" % (run_dir))

    node_samples = {path.stem: parse_node_log(path) for path in node_logs}
    client_node = find_node_for_source(node_samples, "homa_latency", "client")
    server_node = find_node_for_source(node_samples, "homa_server_tput", "server")

    table_rows = {}
    raw_lines = []
    for entry in EXPERIMENTS:
        node_name = client_node if entry["source"] == "client" else server_node
        sample_rows = node_samples[node_name].get(entry["experiment"], {}).get(entry["source"], [])
        if not sample_rows:
            raise SystemExit(
                "missing %s samples for %s in %s"
                % (entry["source"], entry["experiment"], node_name)
            )
        values = [row[entry["field"]] for row in sample_rows]
        table_rows.setdefault(entry["metric"], {})[entry["protocol"]] = (
            entry["table_format"].format(entry["selector"](values))
        )
        raw_lines.append(
            "%s %s: %s (%s)" % (
                entry["protocol"],
                entry["raw_label"],
                entry["raw_format"].format(mean(values)),
                format_samples(values, entry["raw_format"]),
            )
        )

    num_nodes = read_cperf_option(run_dir, NUM_NODES_RE)
    http2_sessions = read_cperf_option(run_dir, HTTP2_RE)
    pool_size = read_cperf_option(run_dir, POOL_RE)
    tfo = read_cperf_option(run_dir, TFO_RE)

    output = Path(args.output).resolve()
    rel_run_dir = run_dir.relative_to(Path.cwd())
    lines = [
        "# %s" % (args.title),
        "",
        "Source run: `%s`" % (rel_run_dir),
        "",
        "Method:",
        "- This table mirrors the cp_basic presentation style but compares Homa against a single tuned DCTCP configuration.",
        "- The tuned DCTCP variant uses HTTP/2-style multiplexing and TCP connection pooling.",
        "- Each row uses the best per-second value recorded during the timed experiment window.",
        "- For latency that means the minimum sample; for throughput it means the maximum sample.",
        "",
        "| Metric | Homa | Tuned DCTCP |",
        "|---|---:|---:|",
    ]

    metric_order = [
        "100B latency (us)",
        "500KB throughput (Gbps)",
        "Client throughput (Gbps)",
        "Server throughput (Gbps)",
    ]
    for metric in metric_order:
        row = table_rows[metric]
        lines.append("| %s | %s | %s |" % (
            metric, row["Homa"], row["Tuned DCTCP"]))

    lines.extend([
        "",
        "## Raw output used",
        "",
        "```text",
    ])
    lines.extend(raw_lines)
    lines.extend([
        "```",
        "",
        "## Caption",
        "",
        build_caption(num_nodes, http2_sessions, pool_size, tfo),
        "",
    ])

    output.write_text("\n".join(lines))
    print("wrote %s" % (output))


if __name__ == "__main__":
    main()
