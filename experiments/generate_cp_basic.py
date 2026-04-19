#!/usr/bin/env python3

import argparse
import math
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
        "raw_label": "RTT latency (us)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_1msg_tput",
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "selector": max,
        "raw_label": "single message throughput (Gbps)",
        "table_format": "{:.1f}",
        "raw_format": "{:.1f}",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_client_tput",
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "selector": max,
        "raw_label": "client throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_server_tput",
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "selector": max,
        "raw_label": "server throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "Homa",
        "experiment": "homa_client_rpc_tput",
        "metric": "Client RPC rate (Mops/sec)",
        "source": "client",
        "field": "kops",
        "selector": max,
        "raw_label": "client RPC throughput (Kops/sec)",
        "table_format": "{:.3f}",
        "raw_format": "{:.2f}",
        "table_scale": 1.0 / 1000.0,
    },
    {
        "protocol": "Homa",
        "experiment": "homa_server_rpc_tput",
        "metric": "Server RPC rate (Mops/sec)",
        "source": "server",
        "field": "kops",
        "selector": max,
        "raw_label": "server RPC throughput (Kops/sec)",
        "table_format": "{:.3f}",
        "raw_format": "{:.2f}",
        "table_scale": 1.0 / 1000.0,
    },
    {
        "protocol": "TCP",
        "experiment": "tcp_latency",
        "metric": "100B latency (us)",
        "source": "client",
        "field": "latency",
        "selector": min,
        "raw_label": "RTT latency (us)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "TCP",
        "experiment": "tcp_1msg_tput",
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "selector": max,
        "raw_label": "single message throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "TCP",
        "experiment": "tcp_client_tput",
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "selector": max,
        "raw_label": "client throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "TCP",
        "experiment": "tcp_server_tput",
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "selector": max,
        "raw_label": "server throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "TCP",
        "experiment": "tcp_client_rpc_tput",
        "metric": "Client RPC rate (Mops/sec)",
        "source": "client",
        "field": "kops",
        "selector": max,
        "raw_label": "client RPC throughput (Kops/sec)",
        "table_format": "{:.3f}",
        "raw_format": "{:.2f}",
        "table_scale": 1.0 / 1000.0,
    },
    {
        "protocol": "TCP",
        "experiment": "tcp_server_rpc_tput",
        "metric": "Server RPC rate (Mops/sec)",
        "source": "server",
        "field": "kops",
        "selector": max,
        "raw_label": "server RPC throughput (Kops/sec)",
        "table_format": "{:.3f}",
        "raw_format": "{:.2f}",
        "table_scale": 1.0 / 1000.0,
    },
    {
        "protocol": "DCTCP",
        "experiment": "dctcp_latency",
        "metric": "100B latency (us)",
        "source": "client",
        "field": "latency",
        "selector": min,
        "raw_label": "RTT latency (us)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "DCTCP",
        "experiment": "dctcp_1msg_tput",
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "selector": max,
        "raw_label": "single message throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "DCTCP",
        "experiment": "dctcp_client_tput",
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "selector": max,
        "raw_label": "client throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "DCTCP",
        "experiment": "dctcp_server_tput",
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "selector": max,
        "raw_label": "server throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "protocol": "DCTCP",
        "experiment": "dctcp_client_rpc_tput",
        "metric": "Client RPC rate (Mops/sec)",
        "source": "client",
        "field": "kops",
        "selector": max,
        "raw_label": "client RPC throughput (Kops/sec)",
        "table_format": "{:.3f}",
        "raw_format": "{:.2f}",
        "table_scale": 1.0 / 1000.0,
    },
    {
        "protocol": "DCTCP",
        "experiment": "dctcp_server_rpc_tput",
        "metric": "Server RPC rate (Mops/sec)",
        "source": "server",
        "field": "kops",
        "selector": max,
        "raw_label": "server RPC throughput (Kops/sec)",
        "table_format": "{:.3f}",
        "raw_format": "{:.2f}",
        "table_scale": 1.0 / 1000.0,
    },
]

START_RE = re.compile(r"Starting (\S+) experiment")
END_RE = re.compile(r"Ending (\S+) experiment")
CLIENT_RE = re.compile(
    r"Clients:\s+([0-9.]+) Kops/sec,\s+([0-9.]+) Gbps, RTT \(us\) P50 ([0-9.]+)"
)
SERVER_RE = re.compile(r"Servers:\s+([0-9.]+) Kops/sec,\s+([0-9.]+) Gbps")
NUM_SERVERS_RE = re.compile(r"--num_servers: ([^, ]+)")
NUM_NODES_RE = re.compile(r"--num_nodes: ([^, ]+)")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate cp_basic Table 2 style markdown from a fetched run."
    )
    parser.add_argument(
        "run_dir",
        nargs="?",
        default="experiments/results/runs/baseline/latest",
        help="Path to a fetched cp_basic run directory (default: baseline/latest)",
    )
    parser.add_argument(
        "--output",
        default="experiments/results/cp_basic_table.md",
        help="Output markdown path",
    )
    return parser.parse_args()


def resolve_run_dir(run_arg: str) -> Path:
    run_dir = Path(run_arg)
    if run_dir.name == "latest":
        resolved = run_dir.resolve()
        if resolved.exists() and resolved.name.startswith("cp_basic"):
            return resolved
        parent = resolved.parent if resolved.exists() else run_dir.parent.resolve()
        candidates = sorted(parent.glob("cp_basic*"))
        if candidates:
            return candidates[-1].resolve()
    return run_dir.resolve()


def parse_num_servers(run_dir: Path) -> int | None:
    cperf_log = run_dir / "reports" / "cperf.log"
    if not cperf_log.exists():
        return None
    text = cperf_log.read_text()
    match = NUM_SERVERS_RE.search(text)
    if match:
        try:
            return int(float(match.group(1)))
        except ValueError:
            return None
    return None


def parse_num_nodes(run_dir: Path) -> int | None:
    cperf_log = run_dir / "reports" / "cperf.log"
    if not cperf_log.exists():
        return None
    text = cperf_log.read_text()
    match = NUM_NODES_RE.search(text)
    if match:
        try:
            return int(float(match.group(1)))
        except ValueError:
            return None
    return None


def parse_node_log(path: Path):
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


def find_node_for_source(node_samples, experiment: str, source: str) -> str:
    for node_name, samples in sorted(node_samples.items()):
        if samples.get(experiment, {}).get(source):
            return node_name
    raise RuntimeError(f"could not find {source} samples for {experiment}")


def mean(values):
    return sum(values) / len(values)


def format_samples(values, fmt: str) -> str:
    return " ".join(fmt.format(value) for value in values)


def describe_topology(num_nodes: int | None, num_servers: int | None) -> str:
    node_text = f"{num_nodes}-node" if num_nodes is not None else "cluster"
    if num_servers is None:
        return f"{node_text} CloudLab setup"
    if num_servers <= 0:
        return f"{node_text} CloudLab all-nodes setup (`--servers 0`)"
    return f"{node_text} CloudLab dedicated-server setup (`--servers {num_servers}`)"


def build_caption(num_nodes: int | None, num_servers: int | None) -> str:
    topology = describe_topology(num_nodes, num_servers)
    if num_servers is not None and num_servers > 0:
        server_count = (num_nodes - 1) if num_nodes is not None else "the remaining"
        client_desc = (
            "Client performance is measured with a single client node spreading "
            f"requests across {server_count} server nodes, and server performance "
            "is measured with the remaining client nodes all issuing requests to "
            "a single server node."
        )
    else:
        client_desc = (
            "Client-side metrics are measured with the designated single client node "
            "sending to the remaining server-capable nodes."
        )
    return (
        f"Table 2 style summary for the {topology}. The top two rows use a single "
        "client issuing back-to-back requests to a single server with 100-byte "
        "requests/responses for latency and 500 KB requests/responses for throughput. "
        "The remaining rows use multi-threaded clients with multiple concurrent RPCs. "
        f"{client_desc} Throughput "
        "counts payload bytes only. RPC rate is measured with 100-byte requests and "
        "responses. Each table entry is the best value observed among the per-second "
        "samples during the timed phase of `cp_basic`."
    )


def main():
    args = parse_args()
    run_dir = resolve_run_dir(args.run_dir)
    if not run_dir.exists():
        raise SystemExit(f"run directory not found: {run_dir}")

    node_logs = sorted(run_dir.glob("node-*.log"))
    if not node_logs:
        raise SystemExit(f"no node logs found in {run_dir}")

    node_samples = {path.stem: parse_node_log(path) for path in node_logs}
    num_servers = parse_num_servers(run_dir)
    num_nodes = parse_num_nodes(run_dir)

    client_node = find_node_for_source(node_samples, "homa_latency", "client")
    server_node = find_node_for_source(node_samples, "homa_server_rpc_tput", "server")

    table_rows = {}
    raw_lines = []
    protocol_order = ["Homa", "TCP", "DCTCP"]

    for entry in EXPERIMENTS:
        node_name = client_node if entry["source"] == "client" else server_node
        sample_rows = node_samples[node_name].get(entry["experiment"], {}).get(entry["source"], [])
        if not sample_rows:
            raise SystemExit(
                f"missing {entry['source']} samples for {entry['experiment']} in {node_name}"
            )
        values = [row[entry["field"]] for row in sample_rows]
        best_value = entry["selector"](values)
        table_value = best_value * entry.get("table_scale", 1.0)
        table_rows.setdefault(entry["metric"], {})[entry["protocol"]] = entry["table_format"].format(
            table_value
        )
        raw_lines.append(
            f"{entry['protocol']} {entry['raw_label']}: "
            f"{entry['raw_format'].format(mean(values))} "
            f"({format_samples(values, entry['raw_format'])})"
        )

    output = Path(args.output).resolve()
    rel_run_dir = run_dir.relative_to(Path.cwd())
    caption = build_caption(num_nodes, num_servers)

    lines = [
        "# cp_basic Table 2 Style Summary",
        "",
        f"Source run: `{rel_run_dir}`",
        "",
        "Method:",
        "- This table follows the presentation style of Table 2 in the Homa paper.",
        "- The summary is generated automatically from the fetched `node-*.log` files in the selected `cp_basic` run.",
        "- Each row uses the per-second samples recorded during the timed experiment window only.",
        "- To mirror the paper's \"best average across five 5-second runs\" wording as closely as possible, the table below uses the best per-sample value:",
        "  - latency: minimum value",
        "  - throughput and RPC rate: maximum value",
        "- RPC rates are shown in `Mops/sec`, converted from the `Kops/sec` samples.",
        "",
        "| Metric | Homa | TCP | DCTCP |",
        "|---|---:|---:|---:|",
    ]

    metric_order = [
        "100B latency (us)",
        "500KB throughput (Gbps)",
        "Client throughput (Gbps)",
        "Server throughput (Gbps)",
        "Client RPC rate (Mops/sec)",
        "Server RPC rate (Mops/sec)",
    ]
    for metric in metric_order:
        row = table_rows[metric]
        lines.append(
            f"| {metric} | {row['Homa']} | {row['TCP']} | {row['DCTCP']} |"
        )

    lines.extend(
        [
            "",
            "## Raw `cp_basic` output used",
            "",
            "```text",
        ]
    )

    for protocol in protocol_order:
        protocol_lines = [line for line in raw_lines if line.startswith(protocol + " ")]
        if lines[-1] != "```text":
            lines.append("")
        lines.extend(protocol_lines)

    lines.extend(
        [
            "```",
            "",
            "## Paper-style caption text",
            "",
            caption,
            "",
        ]
    )

    output.write_text("\n".join(lines))
    print(f"wrote {output}")


if __name__ == "__main__":
    main()
