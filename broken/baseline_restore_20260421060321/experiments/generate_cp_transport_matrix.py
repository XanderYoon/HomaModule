#!/usr/bin/env python3

import argparse
import re
from pathlib import Path


METRICS = [
    {
        "metric": "100B latency (us)",
        "source": "client",
        "field": "latency",
        "selector": min,
        "raw_label": "RTT latency (us)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "metric": "500KB throughput (Gbps)",
        "source": "client",
        "field": "gbps_x2",
        "selector": max,
        "raw_label": "single message throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "metric": "Client throughput (Gbps)",
        "source": "client",
        "field": "gbps",
        "selector": max,
        "raw_label": "client throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
        "metric": "Server throughput (Gbps)",
        "source": "server",
        "field": "gbps",
        "selector": max,
        "raw_label": "server throughput (Gbps)",
        "table_format": "{:.2f}",
        "raw_format": "{:.2f}",
    },
    {
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

VARIANT_SORT = [
    "homa",
    "tcp",
    "dctcp",
    "dctcp_tfo",
    "dctcp_pool",
    "dctcp_multiplex",
    "dctcp_static",
    "dctcp_load_aware",
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
        description="Generate a Table 2 style markdown summary for cp_transport_matrix."
    )
    parser.add_argument(
        "run_dir",
        nargs="?",
        default="experiments/results/transport_matrix/latest",
        help="Path to a fetched cp_transport_matrix run directory",
    )
    parser.add_argument(
        "--output",
        default="experiments/results/cp_transport_matrix_table.md",
        help="Output markdown path",
    )
    parser.add_argument(
        "--title",
        default="cp_transport_matrix Table 2 Style Summary",
        help="Markdown document title",
    )
    return parser.parse_args()


def resolve_run_dir(run_arg):
    run_dir = Path(run_arg)
    if run_dir.name == "latest":
        resolved = run_dir.resolve()
        if resolved.exists() and resolved.name.startswith("cp_transport_matrix"):
            return resolved
        parent = resolved.parent if resolved.exists() else run_dir.parent.resolve()
        candidates = sorted(parent.glob("cp_transport_matrix*"))
        if candidates:
            return candidates[-1].resolve()
    return run_dir.resolve()


def logs_dir(run_dir):
    candidate = run_dir / "logs"
    return candidate if candidate.is_dir() else run_dir


def parse_topology_value(run_dir, pattern):
    cperf_log = logs_dir(run_dir) / "reports" / "cperf.log"
    if not cperf_log.exists():
        return None
    text = cperf_log.read_text()
    match = pattern.search(text)
    if not match:
        return None
    try:
        return int(float(match.group(1)))
    except ValueError:
        return None


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


def find_node_for_source(node_samples, experiment, source):
    for node_name, samples in sorted(node_samples.items()):
        if samples.get(experiment, {}).get(source):
            return node_name
    raise RuntimeError("could not find %s samples for %s" % (source, experiment))


def mean(values):
    return sum(values) / len(values)


def format_samples(values, fmt):
    return " ".join(fmt.format(value) for value in values)


def experiment_prefixes(node_samples):
    prefixes = {"homa"}
    suffixes = (
        "_latency",
        "_1msg_tput",
        "_client_tput",
        "_server_tput",
        "_client_rpc_tput",
        "_server_rpc_tput",
    )
    for samples in node_samples.values():
        for experiment in samples.keys():
            for suffix in suffixes:
                if experiment.endswith(suffix):
                    prefixes.add(experiment[: -len(suffix)])
    return prefixes


def variant_group(prefix):
    if prefix == "homa":
        return "homa"
    if prefix == "tcp":
        return "tcp"
    if prefix == "dctcp":
        return "dctcp"
    if prefix.startswith("dctcp_tfo"):
        return "dctcp_tfo"
    if prefix.startswith("dctcp_pool_p"):
        return "dctcp_pool"
    if prefix.startswith("dctcp_multiplex_s"):
        return "dctcp_multiplex"
    if prefix.startswith("dctcp_static_o"):
        return "dctcp_static"
    if prefix.startswith("dctcp_load_aware"):
        return "dctcp_load_aware"
    return prefix


def variant_label(prefix):
    if prefix == "homa":
        return "Homa"
    if prefix == "tcp":
        return "TCP"
    if prefix == "dctcp":
        return "DCTCP"
    if prefix == "dctcp_tfo":
        return "DCTCP + TFO"
    match = re.match(r"dctcp_pool_p(\d+)$", prefix)
    if match:
        return "DCTCP + Pool %s" % (match.group(1))
    match = re.match(r"dctcp_multiplex_s(\d+)$", prefix)
    if match:
        return "DCTCP + HTTP/2 x%s" % (match.group(1))
    match = re.match(r"dctcp_static_o(\d+)$", prefix)
    if match:
        return "DCTCP + Offset %sus" % (match.group(1))
    if prefix == "dctcp_load_aware":
        return "DCTCP + Load-Aware"
    return prefix


def variant_sort_key(prefix):
    group = variant_group(prefix)
    try:
        group_index = VARIANT_SORT.index(group)
    except ValueError:
        group_index = len(VARIANT_SORT)
    numeric = 0
    match = re.search(r"(\d+)$", prefix)
    if match:
        numeric = int(match.group(1))
    return (group_index, numeric, prefix)


def describe_topology(num_nodes, num_servers):
    node_text = "%d-node" % (num_nodes) if num_nodes is not None else "cluster"
    if num_servers is None:
        return "%s CloudLab setup" % (node_text)
    if num_servers <= 0:
        return "%s CloudLab all-nodes setup (`--servers 0`)" % (node_text)
    return "%s CloudLab dedicated-server setup (`--servers %d`)" % (
            node_text, num_servers)


def build_caption(num_nodes, num_servers, variants):
    topology = describe_topology(num_nodes, num_servers)
    return (
        "Table 2 style summary for the %s. The top two rows use a single "
        "client issuing back-to-back requests to a single server with "
        "100-byte requests/responses for latency and 500 KB requests/"
        "responses for throughput. The remaining rows use multi-threaded "
        "clients with multiple concurrent RPCs. Throughput counts payload "
        "bytes only. RPC rate is measured with 100-byte requests and "
        "responses. Each table entry is the best value observed among the "
        "per-second samples during the timed phase. Variants included here: %s."
    ) % (topology, ", ".join(variant_label(prefix) for prefix in variants))


def main():
    args = parse_args()
    run_dir = resolve_run_dir(args.run_dir)
    if not run_dir.exists():
        raise SystemExit("run directory not found: %s" % (run_dir))

    data_dir = logs_dir(run_dir)
    node_logs = sorted(data_dir.glob("node-*.log"))
    if not node_logs:
        raise SystemExit("no node logs found in %s" % (run_dir))

    node_samples = dict((path.stem, parse_node_log(path)) for path in node_logs)
    num_servers = parse_topology_value(run_dir, NUM_SERVERS_RE)
    num_nodes = parse_topology_value(run_dir, NUM_NODES_RE)
    variants = sorted(experiment_prefixes(node_samples), key=variant_sort_key)

    client_node = find_node_for_source(node_samples, "homa_latency", "client")
    server_node = find_node_for_source(node_samples, "homa_server_rpc_tput", "server")

    table_rows = dict((metric["metric"], {}) for metric in METRICS)
    raw_lines = []

    for prefix in variants:
        for metric in METRICS:
            experiment = "%s_%s" % (
                prefix,
                {
                    "100B latency (us)": "latency",
                    "500KB throughput (Gbps)": "1msg_tput",
                    "Client throughput (Gbps)": "client_tput",
                    "Server throughput (Gbps)": "server_tput",
                    "Client RPC rate (Mops/sec)": "client_rpc_tput",
                    "Server RPC rate (Mops/sec)": "server_rpc_tput",
                }[metric["metric"]],
            )
            node_name = client_node if metric["source"] == "client" else server_node
            sample_rows = node_samples[node_name].get(experiment, {}).get(
                    metric["source"], [])
            if not sample_rows:
                table_rows[metric["metric"]][prefix] = "n/a"
                continue
            values = [row[metric["field"]] for row in sample_rows]
            best_value = metric["selector"](values)
            table_value = best_value * metric.get("table_scale", 1.0)
            table_rows[metric["metric"]][prefix] = metric["table_format"].format(
                    table_value)
            raw_lines.append("%s %s: %s (%s)" % (
                    variant_label(prefix),
                    metric["raw_label"],
                    metric["raw_format"].format(mean(values)),
                    format_samples(values, metric["raw_format"])))

    output = Path(args.output).resolve()
    rel_run_dir = run_dir.relative_to(Path.cwd())
    columns = [variant_label(prefix) for prefix in variants]

    lines = [
        "# %s" % (args.title),
        "",
        "Source run: `%s`" % (rel_run_dir),
        "",
        "Method:",
        "- This table follows the presentation style of Table 2 in the Homa paper.",
        "- The summary is generated automatically from the fetched `node-*.log` files in the selected `cp_transport_matrix` run.",
        "- Each row uses the per-second samples recorded during the timed experiment window only.",
        "- Latency uses the minimum per-sample value; throughput and RPC rate use the maximum per-sample value.",
        "- RPC rates are shown in `Mops/sec`, converted from the `Kops/sec` samples.",
        "",
        "| Metric | %s |" % (" | ".join(columns)),
        "|---|%s|" % ("|".join("---:" for _ in columns)),
    ]

    metric_order = [metric["metric"] for metric in METRICS]
    for metric in metric_order:
        row = [table_rows[metric].get(prefix, "n/a") for prefix in variants]
        lines.append("| %s | %s |" % (metric, " | ".join(row)))

    lines.extend([
        "",
        "## Raw Output Used",
        "",
        "```text",
    ])

    for prefix in variants:
        protocol_lines = [
            line for line in raw_lines
            if line.startswith(variant_label(prefix) + " ")
        ]
        if lines[-1] != "```text":
            lines.append("")
        lines.extend(protocol_lines)

    lines.extend([
        "```",
        "",
        "## Paper-style Caption Text",
        "",
        build_caption(num_nodes, num_servers, variants),
        "",
    ])

    output.write_text("\n".join(lines))
    print("wrote %s" % (output))


if __name__ == "__main__":
    main()
