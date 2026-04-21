#!/usr/bin/env python3

import argparse
import math
import re
from pathlib import Path


WORKLOAD_RE = re.compile(r"^(.*)_([^_]+)$")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Generate markdown summaries for fetched DCTCP tuning runs."
    )
    parser.add_argument(
        "run_dir",
        help="Path to a fetched tuning run directory",
    )
    parser.add_argument(
        "--output",
        help="Path to write markdown output",
    )
    parser.add_argument(
        "--title",
        default="DCTCP Tuning Summary",
        help="Markdown heading text",
    )
    return parser.parse_args()


def percentile(sorted_values, pct):
    if not sorted_values:
        return None
    index = math.ceil((pct / 100.0) * len(sorted_values)) - 1
    index = max(0, min(index, len(sorted_values) - 1))
    return sorted_values[index]


def average(values):
    if not values:
        return None
    return sum(values) / len(values)


def logs_dir(run_dir):
    candidate = run_dir / "logs"
    return candidate if candidate.is_dir() else run_dir


def read_rtts(run_dir, experiment):
    values = []
    data_dir = logs_dir(run_dir)
    for path in sorted(data_dir.glob(f"{experiment}-*.rtts")):
        with path.open() as stream:
            for line in stream:
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                fields = stripped.split()
                if len(fields) < 2:
                    continue
                try:
                    values.append(float(fields[1]))
                except ValueError:
                    continue
    values.sort()
    return values


def read_rtts_by_sample(run_dir, experiment):
    samples = {}
    data_dir = logs_dir(run_dir)
    new_style = re.compile(re.escape(experiment) + r"-(\d+)-(\d+)\.rtts$")
    old_style = re.compile(re.escape(experiment) + r"-(\d+)\.rtts$")
    for path in sorted(data_dir.glob(f"{experiment}-*.rtts")):
        sample = 0
        name = path.name
        match = new_style.match(name)
        if match:
            sample = int(match.group(1))
        elif old_style.match(name):
            sample = 0
        samples.setdefault(sample, [])
        with path.open() as stream:
            for line in stream:
                stripped = line.strip()
                if not stripped or stripped.startswith("#"):
                    continue
                fields = stripped.split()
                if len(fields) < 2:
                    continue
                try:
                    samples[sample].append(float(fields[1]))
                except ValueError:
                    continue
    for values in samples.values():
        values.sort()
    return samples


def read_tcp_counters(run_dir, experiment):
    counters = {
        "retrans_segments": None,
        "ce_packets": None,
        "ect_packets": None,
    }
    data_dir = logs_dir(run_dir)
    path = data_dir / "reports" / f"{experiment}.tcp_counters"
    if not path.exists():
        return counters

    with path.open() as stream:
        for line in stream:
            stripped = line.strip()
            if not stripped:
                break
            if stripped.startswith("#"):
                continue
            parts = stripped.split()
            if len(parts) != 2:
                continue
            key, value = parts
            try:
                value = int(value)
            except ValueError:
                continue
            if key == "TcpRetransSegs":
                counters["retrans_segments"] = value
            elif key == "IpExtInCEPkts":
                counters["ce_packets"] = value
            elif key == "IpExtInECT0Pkts":
                counters["ect_packets"] = value
    return counters


def read_tcp_counters_by_sample(run_dir, experiment):
    data_dir = logs_dir(run_dir)
    new_paths = sorted((data_dir / "reports").glob(f"{experiment}-*.tcp_counters"))
    if not new_paths:
        legacy = data_dir / "reports" / f"{experiment}.tcp_counters"
        if legacy.exists():
            new_paths = [legacy]
    samples = {}
    for path in new_paths:
        sample = 0
        match = re.match(re.escape(experiment) + r"-(\d+)\.tcp_counters$", path.name)
        if match:
            sample = int(match.group(1))
        counters = {
            "retrans_segments": 0,
            "ce_packets": 0,
            "ect_packets": 0,
        }
        with path.open() as stream:
            for line in stream:
                stripped = line.strip()
                if not stripped:
                    break
                if stripped.startswith("#"):
                    continue
                parts = stripped.split()
                if len(parts) != 2:
                    continue
                key, value = parts
                try:
                    value = int(value)
                except ValueError:
                    continue
                if key == "TcpRetransSegs":
                    counters["retrans_segments"] = value
                elif key == "IpExtInCEPkts":
                    counters["ce_packets"] = value
                elif key == "IpExtInECT0Pkts":
                    counters["ect_packets"] = value
        samples[sample] = counters
    return samples


def read_qdisc_drops(run_dir, experiment):
    drops = 0
    found = False
    sent_re = re.compile(r"Sent\s+\d+\s+bytes\s+(\d+)\s+pkt\s+\(dropped\s+(\d+)")
    ecn_re = re.compile(r"ecn_mark\s+(\d+)")
    ecn_marks = 0

    data_dir = logs_dir(run_dir)
    for path in sorted(data_dir.glob(f"{experiment}-*.qdisc")):
        found = True
        with path.open() as stream:
            for line in stream:
                sent_match = sent_re.search(line)
                if sent_match:
                    drops += int(sent_match.group(2))
                ecn_match = ecn_re.search(line)
                if ecn_match:
                    ecn_marks += int(ecn_match.group(1))
    return {
        "drops": drops if found else None,
        "ecn_marks": ecn_marks if found else None,
    }


def read_qdisc_drops_by_sample(run_dir, experiment):
    sent_re = re.compile(r"Sent\s+\d+\s+bytes\s+(\d+)\s+pkt\s+\(dropped\s+(\d+)")
    ecn_re = re.compile(r"ecn_mark\s+(\d+)")
    data_dir = logs_dir(run_dir)
    new_style = re.compile(re.escape(experiment) + r"-(\d+)-(\d+)\.qdisc$")
    old_style = re.compile(re.escape(experiment) + r"-(\d+)\.qdisc$")
    samples = {}
    for path in sorted(data_dir.glob(f"{experiment}-*.qdisc")):
        sample = 0
        name = path.name
        match = new_style.match(name)
        if match:
            sample = int(match.group(1))
        elif old_style.match(name):
            sample = 0
        stats = samples.setdefault(sample, {"drops": 0, "ecn_marks": 0})
        with path.open() as stream:
            for line in stream:
                sent_match = sent_re.search(line)
                if sent_match:
                    stats["drops"] += int(sent_match.group(2))
                ecn_match = ecn_re.search(line)
                if ecn_match:
                    stats["ecn_marks"] += int(ecn_match.group(1))
    return samples


def split_experiment_name(experiment):
    match = WORKLOAD_RE.match(experiment)
    if not match:
        return experiment, "unknown"
    return match.group(1), match.group(2)


def humanize_variant(variant_name):
    if variant_name == "homa":
        return "Homa"
    if variant_name == "unloaded":
        return "Homa best case"

    text = variant_name
    text = text.replace("dctcp", "DCTCP")
    text = text.replace("_tfo", " + TFO")
    text = text.replace("_pool", " + Connection Pooling")
    text = text.replace("_multiplex", " + Multiplexing")
    text = text.replace("_load_aware", " + Load-Aware")
    text = text.replace("_staggered", " + Staggered Scheduling")
    text = text.replace("_static", " + Static Scheduler")
    text = text.replace("_", " ")
    text = re.sub(r"\bp(\d+)\b", r"(\1 conns)", text)
    text = re.sub(r"\bs(\d+)\b", r"(\1 sessions)", text)
    text = re.sub(r"\bo(\d+)\b", r"(\1 us)", text)
    return " ".join(text.split())


def sort_key(row):
    variant = row["variant"]
    rank = 10
    if variant == "homa":
        rank = 0
    elif variant == "dctcp":
        rank = 1
    elif variant == "dctcp_tfo":
        rank = 2
    pool_match = re.match(r"dctcp_pool_p(\d+)$", variant)
    if pool_match:
        return (rank, "dctcp_pool", int(pool_match.group(1)))
    session_match = re.match(r"dctcp_multiplex_s(\d+)$", variant)
    if session_match:
        return (rank, "dctcp_multiplex", int(session_match.group(1)))
    offset_match = re.match(r"dctcp_static_o(\d+)$", variant)
    if offset_match:
        return (rank, "dctcp_static", int(offset_match.group(1)))
    return (rank, variant, 0)


def format_float(value):
    if value is None:
        return "N/A"
    return f"{value:,.2f}"


def format_int(value):
    if value is None:
        return "N/A"
    return f"{int(round(value)):,}"


def format_percent(numerator, denominator):
    if numerator is None or denominator in (None, 0):
        return "N/A"
    return f"{(100.0 * numerator / denominator):.3f}%"


def collect_rows(run_dir):
    data_dir = logs_dir(run_dir)
    experiments = set()
    experiments.update(
        path.name.split("-", 1)[0]
        for path in data_dir.glob("*.rtts")
    )
    reports_dir = data_dir / "reports"
    if reports_dir.is_dir():
        experiments.update(
            path.name.split("-", 1)[0]
            for path in reports_dir.glob("*.tcp_counters")
        )
    experiments.update(
        path.name.split("-", 1)[0]
        for path in data_dir.glob("*.qdisc")
    )
    experiments = sorted(experiments)
    rows_by_workload = {}
    for experiment in experiments:
        variant_name, workload = split_experiment_name(experiment)
        if variant_name == "unloaded":
            continue
        rtts_by_sample = read_rtts_by_sample(run_dir, experiment)
        counter_samples = read_tcp_counters_by_sample(run_dir, experiment)
        qdisc_samples = read_qdisc_drops_by_sample(run_dir, experiment)
        p50_values = [percentile(values, 50) for values in rtts_by_sample.values()
                if values]
        p99_values = [percentile(values, 99) for values in rtts_by_sample.values()
                if values]
        sample_counts = [len(values) for values in rtts_by_sample.values() if values]
        rows_by_workload.setdefault(workload, []).append({
            "experiment": experiment,
            "variant": variant_name,
            "label": humanize_variant(variant_name),
            "runs": max(len(rtts_by_sample), len(counter_samples), len(qdisc_samples)),
            "rtt_runs": len([values for values in rtts_by_sample.values() if values]),
            "samples": average(sample_counts),
            "p50": average([value for value in p50_values if value is not None]),
            "p99": average([value for value in p99_values if value is not None]),
            "retrans_segments": average([
                counters["retrans_segments"] for counters in counter_samples.values()
            ]),
            "qdisc_drops": average([
                stats["drops"] for stats in qdisc_samples.values()
            ]),
            "ce_packets": average([
                counters["ce_packets"] for counters in counter_samples.values()
            ]),
            "ect_packets": average([
                counters["ect_packets"] for counters in counter_samples.values()
            ]),
            "qdisc_ecn_marks": average([
                stats["ecn_marks"] for stats in qdisc_samples.values()
            ]),
        })
    for workload in rows_by_workload:
        rows_by_workload[workload].sort(key=sort_key)
    return rows_by_workload


def render_summary(title, rows_by_workload):
    lines = [f"# {title}", ""]
    if not rows_by_workload:
        lines.append("No fetched RTT, qdisc, or TCP counter files were found, so no summary could be generated.")
        return "\n".join(lines) + "\n"

    lines.append(
        "Latency percentiles are averaged across whatever RTT samples were successfully fetched for each experiment."
    )
    lines.append(
        "TCP counters and qdisc drops are averaged across whatever repeated-run artifacts were available."
    )
    lines.append("")
    for workload in sorted(rows_by_workload):
        rows = rows_by_workload[workload]
        labels = [row["label"] for row in rows]
        lines.append(f"## {workload}")
        lines.append("")
        lines.append(
            "Latency percentiles below are averages across repeated runs."
        )
        lines.append(
            "| Metric | " + " | ".join(labels) + " |"
        )
        lines.append("| --- | " + " | ".join(["---:"] * len(labels)) + " |")

        metric_rows = [
            ("RTT p50 (us)", lambda row: format_float(row["p50"])),
            ("RTT p99 (us)", lambda row: format_float(row["p99"])),
            ("Runs", lambda row: format_int(row["runs"])),
            ("RTT runs", lambda row: format_int(row["rtt_runs"])),
            ("RTT samples/run", lambda row: format_float(row["samples"])),
            ("Retrans segs", lambda row: format_int(row["retrans_segments"])),
            ("Qdisc drops", lambda row: format_int(row["qdisc_drops"])),
            ("CE packets", lambda row: format_int(row["ce_packets"])),
            ("CE/ECT", lambda row: format_percent(row["ce_packets"], row["ect_packets"])),
            ("Qdisc ECN marks", lambda row: format_int(row["qdisc_ecn_marks"])),
        ]
        for metric_label, formatter in metric_rows:
            lines.append(
                "| {metric} | {values} |".format(
                    metric=metric_label,
                    values=" | ".join(formatter(row) for row in rows),
                )
            )
        lines.append("")
    return "\n".join(lines)


def main():
    args = parse_args()
    run_dir = Path(args.run_dir).resolve()
    output_path = Path(args.output).resolve() if args.output else run_dir / "summary.md"
    rows_by_workload = collect_rows(run_dir)
    markdown = render_summary(args.title, rows_by_workload)
    output_path.write_text(markdown)


if __name__ == "__main__":
    main()
