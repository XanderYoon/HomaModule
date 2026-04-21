#!/usr/bin/env python3

import argparse
import re
from pathlib import Path


PROTOCOLS = [
    {
        "protocol": "Homa",
        "prefix": "homa",
    },
    {
        "protocol": "DCTCP",
        "prefix": "dctcp",
    },
    {
        "protocol": "DCTCP + Static + Load-Aware",
        "prefix": "dctcp_static_load_aware",
    },
]

METRICS = [
    {
        "suffix": "latency",
        "metric": "100B latency (us)",
        "source": "client",
        "field": "latency",
        "raw_label": "RTT latency (us)",
        "value_format": "{:.2f}",
    },
    {
        "suffix": "1msg_tput",
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "raw_label": "single message throughput (Gbps)",
        "value_format": "{:.2f}",
    },
    {
        "suffix": "client_tput",
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "raw_label": "client throughput (Gbps)",
        "value_format": "{:.2f}",
    },
    {
        "suffix": "server_tput",
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "raw_label": "server throughput (Gbps)",
        "value_format": "{:.2f}",
    },
    {
        "suffix": "client_rpc_tput",
        "metric": "Client RPC rate (Mops/sec)",
        "source": "client",
        "field": "kops_to_mops",
        "raw_label": "client RPC throughput (Kops/sec)",
        "value_format": "{:.3f}",
    },
    {
        "suffix": "server_rpc_tput",
        "metric": "Server RPC rate (Mops/sec)",
        "source": "server",
        "field": "kops_to_mops",
        "raw_label": "server RPC throughput (Kops/sec)",
        "value_format": "{:.3f}",
    },
]

START_RE = re.compile(r"Starting (\S+) experiment")
END_RE = re.compile(r"Ending (\S+) experiment")
CLIENT_RE = re.compile(
    r"Clients:\s+([0-9.]+) Kops/sec,\s+([0-9.]+) Gbps, RTT \(us\) P50 ([0-9.]+)"
)
SERVER_RE = re.compile(r"Servers:\s+([0-9.]+) Kops/sec,\s+([0-9.]+) Gbps")
NUM_NODES_RE = re.compile(r"--num_nodes: ([^, ]+)")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate markdown for the final cp_basic-style Homa vs DCTCP run."
    )
    parser.add_argument(
        "run_dir",
        nargs="?",
        default="experiments/results/final_basic/latest",
        help="Path to a fetched final-basic run directory",
    )
    parser.add_argument(
        "--output",
        default="experiments/results/dctcp_final_basic_summary.md",
        help="Output markdown path",
    )
    parser.add_argument(
        "--title",
        default="DCTCP Final Basic Summary",
        help="Markdown document title",
    )
    return parser.parse_args()


def resolve_run_dir(run_arg: str) -> Path:
    run_dir = Path(run_arg)
    if run_dir.name == "latest":
        resolved = run_dir.resolve()
        if resolved.exists():
            return resolved
        parent = run_dir.parent.resolve()
        candidates = sorted(parent.glob("dctcp_final_basic_*"))
        if candidates:
            return candidates[-1].resolve()
    return run_dir.resolve()


def logs_dir(run_dir: Path) -> Path:
    candidate = run_dir / "logs"
    return candidate if candidate.is_dir() else run_dir


def parse_num_nodes(run_dir: Path):
    cperf_log = logs_dir(run_dir) / "reports" / "cperf.log"
    if not cperf_log.exists():
        return None
    text = cperf_log.read_text()
    match = NUM_NODES_RE.search(text)
    if not match:
        return None
    try:
        return int(float(match.group(1)))
    except ValueError:
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
                    "kops_to_mops": float(client.group(1)) / 1000.0,
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
                    "kops_to_mops": float(server.group(1)) / 1000.0,
                }
            )
    return samples


def find_node_for_source(node_samples, experiment: str, source: str) -> str:
    for node_name, samples in sorted(node_samples.items()):
        if samples.get(experiment, {}).get(source):
            return node_name
    raise RuntimeError("could not find %s samples for %s" % (
            source, experiment))


def mean(values):
    return sum(values) / len(values)


def format_samples(values, fmt: str) -> str:
    return " ".join(fmt.format(value) for value in values)


def build_caption(num_nodes):
    if num_nodes is None:
        topology = "cluster"
    else:
        topology = "%d-node cluster" % (num_nodes)
    return (
        "cp_basic-style summary for the final Homa vs DCTCP comparison on the "
        "%s. The rows report averages of the per-second samples recorded during "
        "the timed portion of each experiment. The combined DCTCP variant uses "
        "application-layer static scheduling plus load-aware balancing, with no "
        "TFO, connection pooling, or multiplexing."
    ) % (topology)


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
    num_nodes = parse_num_nodes(run_dir)

    client_node = find_node_for_source(node_samples, "homa_latency", "client")
    server_node = find_node_for_source(node_samples, "homa_server_rpc_tput", "server")

    table_rows = {}
    raw_lines = []
    protocol_order = [entry["protocol"] for entry in PROTOCOLS]

    for protocol in PROTOCOLS:
        for metric in METRICS:
            experiment = "%s_%s" % (protocol["prefix"], metric["suffix"])
            node_name = client_node if metric["source"] == "client" else server_node
            sample_rows = node_samples[node_name].get(experiment, {}).get(
                    metric["source"], [])
            if not sample_rows:
                raise SystemExit("missing %s samples for %s in %s" % (
                        metric["source"], experiment, node_name))
            values = [row[metric["field"]] for row in sample_rows]
            average = mean(values)
            table_rows.setdefault(metric["metric"], {})[protocol["protocol"]] = (
                    metric["value_format"].format(average))
            raw_lines.append(
                "%s %s: %s (%s)" % (
                    protocol["protocol"],
                    metric["raw_label"],
                    metric["value_format"].format(average),
                    format_samples(values, metric["value_format"]),
                )
            )

    output = Path(args.output).resolve()
    rel_run_dir = run_dir.relative_to(Path.cwd())

    lines = [
        "# %s" % (args.title),
        "",
        "Source run: `%s`" % (rel_run_dir),
        "",
        "Method:",
        "- This summary is generated automatically from the fetched `node-*.log` files.",
        "- Each table entry is the average of the per-second samples recorded during the timed experiment window.",
        "- RPC rates are shown in `Mops/sec`, converted from `Kops/sec`.",
        "",
        "| Metric | Homa | DCTCP | DCTCP + Static + Load-Aware |",
        "|---|---:|---:|---:|",
    ]

    for metric in [entry["metric"] for entry in METRICS]:
        row = table_rows[metric]
        lines.append(
            "| %s | %s | %s | %s |" % (
                metric,
                row["Homa"],
                row["DCTCP"],
                row["DCTCP + Static + Load-Aware"],
            )
        )

    lines.extend(
        [
            "",
            "## Raw Output Used",
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
            "## Caption",
            "",
            build_caption(num_nodes),
            "",
        ]
    )

    output.write_text("\n".join(lines))
    print("wrote %s" % (output))


if __name__ == "__main__":
    main()
