#!/usr/bin/env python3

import argparse
import math
import re
from collections import defaultdict
from pathlib import Path

try:
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
except Exception:
    plt = None


def read_rtts(files):
    rtts = defaultdict(list)
    total = 0
    for file in files:
        with open(file) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                length_s, rtt_s, *_ = line.split()
                rtts[int(length_s)].append(float(rtt_s))
                total += 1
    return rtts, total


def percentile(values, pct):
    if not values:
        return 0.0
    values = sorted(values)
    index = int(len(values) * pct / 100.0)
    if index >= len(values):
        index = len(values) - 1
    return values[index]


def unloaded_medians(rtts):
    result = {}
    for length, values in rtts.items():
        result[length] = percentile(values, 50)
    return result


def slowdown_digest(exp_rtts, total_messages, unloaded):
    lengths = []
    cum_frac = []
    slow_50 = []
    slow_90 = []
    counts = []
    cumulative = 0
    current_unloaded = unloaded[min(unloaded.keys())]
    for length in sorted(exp_rtts.keys()):
        if length in unloaded:
            current_unloaded = unloaded[length]
        slowdowns = [rtt / current_unloaded for rtt in exp_rtts[length]]
        cumulative += len(slowdowns)
        lengths.append(length)
        cum_frac.append(cumulative / total_messages)
        counts.append(len(slowdowns))
        slow_50.append(percentile(slowdowns, 50))
        slow_90.append(percentile(slowdowns, 90))
    return {
        "lengths": lengths,
        "cum_frac": cum_frac,
        "counts": counts,
        "slow_50": slow_50,
        "slow_90": slow_90,
        "rtts": exp_rtts,
        "total_messages": total_messages,
    }


def short_cdf(exp_rtts, total_messages):
    short = []
    messages_left = total_messages // 10
    longest = 0
    for length in sorted(exp_rtts.keys()):
        if length >= 1500 and short:
            break
        short.extend(exp_rtts[length])
        messages_left -= len(exp_rtts[length])
        longest = length
        if messages_left < 0:
            break
    short = sorted(short)
    total = len(short)
    x = []
    y = []
    remaining = total
    for rtt in short:
        remaining -= 1
        frac = remaining / total
        if x:
            x.append(rtt)
            y.append(y[-1])
        x.append(rtt)
        y.append(frac)
    return x, y, longest


def parse_gbps(log_path, experiment):
    text = log_path.read_text()
    match = re.search(
        rf"Servers for {re.escape(experiment)} experiment: \d+ nodes, ([0-9.]+) Gbps",
        text,
    )
    if not match:
        raise RuntimeError(f"Couldn't find server throughput for {experiment} in {log_path}")
    return float(match.group(1))


def step_points(x, y):
    x_new = []
    y_new = []
    for i, (xv, yv) in enumerate(zip(x, y)):
        if i:
            x_new.append(xv)
            y_new.append(y[i - 1])
        x_new.append(xv)
        y_new.append(yv)
    return x_new, y_new


def write_digest(path, digest):
    with open(path, "w") as f:
        f.write("# length cum_frac samples slow_p50 slow_p90\n")
        for row in zip(
            digest["lengths"],
            digest["cum_frac"],
            digest["counts"],
            digest["slow_50"],
            digest["slow_90"],
        ):
            f.write("%8d %.6f %8d %.4f %.4f\n" % row)


def write_cdf(path, x, y, longest):
    with open(path, "w") as f:
        f.write(f"# shortest 10%% CDF, longest message included: {longest}\n")
        f.write("# usec frac_longer\n")
        for xv, yv in zip(x, y):
            f.write(f"{xv:.6f} {yv:.8f}\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--workload", default="w4")
    parser.add_argument("run_dirs", nargs="+")
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    homa_rtts = defaultdict(list)
    dctcp_rtts = defaultdict(list)
    unloaded_rtts = defaultdict(list)
    homa_gbps = []
    dctcp_gbps = []

    for run_dir_s in args.run_dirs:
        run_dir = Path(run_dir_s)
        run_workload = args.workload
        run_homa, _ = read_rtts(run_dir.glob(f"homa_{run_workload}-*.rtts"))
        run_dctcp, _ = read_rtts(run_dir.glob(f"dctcp_{run_workload}-*.rtts"))
        run_unloaded, _ = read_rtts(run_dir.glob(f"unloaded_{run_workload}-*.rtts"))
        for length, values in run_homa.items():
            homa_rtts[length].extend(values)
        for length, values in run_dctcp.items():
            dctcp_rtts[length].extend(values)
        for length, values in run_unloaded.items():
            unloaded_rtts[length].extend(values)
        log_path = run_dir / "reports" / "cperf.log"
        homa_gbps.append(parse_gbps(log_path, f"homa_{run_workload}"))
        dctcp_gbps.append(parse_gbps(log_path, f"dctcp_{run_workload}"))

    unloaded = unloaded_medians(unloaded_rtts)
    homa_total = sum(len(v) for v in homa_rtts.values())
    dctcp_total = sum(len(v) for v in dctcp_rtts.values())
    homa_digest = slowdown_digest(homa_rtts, homa_total, unloaded)
    dctcp_digest = slowdown_digest(dctcp_rtts, dctcp_total, unloaded)

    write_digest(output_dir / f"homa_{args.workload}_slowdown.data", homa_digest)
    write_digest(output_dir / f"dctcp_{args.workload}_slowdown.data", dctcp_digest)

    homa_x, homa_y, homa_longest = short_cdf(homa_rtts, homa_total)
    dctcp_x, dctcp_y, dctcp_longest = short_cdf(dctcp_rtts, dctcp_total)
    unloaded_x, unloaded_y, unloaded_longest = short_cdf(unloaded_rtts, sum(len(v) for v in unloaded_rtts.values()))
    write_cdf(output_dir / f"homa_{args.workload}_short_cdf.data", homa_x, homa_y, homa_longest)
    write_cdf(output_dir / f"dctcp_{args.workload}_short_cdf.data", dctcp_x, dctcp_y, dctcp_longest)
    write_cdf(output_dir / f"unloaded_{args.workload}_short_cdf.data", unloaded_x, unloaded_y, unloaded_longest)

    with open(output_dir / "summary.txt", "w") as f:
        f.write(f"Runs analyzed: {len(args.run_dirs)}\n")
        f.write(
            "Homa server throughput avg (Gbps): %.3f [%s]\n"
            % (sum(homa_gbps) / len(homa_gbps), ", ".join(f"{x:.3f}" for x in homa_gbps))
        )
        f.write(
            "DCTCP server throughput avg (Gbps): %.3f [%s]\n"
            % (sum(dctcp_gbps) / len(dctcp_gbps), ", ".join(f"{x:.3f}" for x in dctcp_gbps))
        )
        f.write(
            "Homa slowdown p50 at 10%% messages: %.4f\n"
            % homa_digest["slow_50"][max(0, math.ceil(len(homa_digest["slow_50"]) * 0.1) - 1)]
        )
        f.write(
            "Homa slowdown p90 at 10%% messages: %.4f\n"
            % homa_digest["slow_90"][max(0, math.ceil(len(homa_digest["slow_90"]) * 0.1) - 1)]
        )
        f.write(
            "DCTCP slowdown p50 at 10%% messages: %.4f\n"
            % dctcp_digest["slow_50"][max(0, math.ceil(len(dctcp_digest["slow_50"]) * 0.1) - 1)]
        )
        f.write(
            "DCTCP slowdown p90 at 10%% messages: %.4f\n"
            % dctcp_digest["slow_90"][max(0, math.ceil(len(dctcp_digest["slow_90"]) * 0.1) - 1)]
        )

    if plt is None:
        return

    fig, ax = plt.subplots(figsize=(6, 4))
    for digest, color, label_prefix in [
        (dctcp_digest, "#7A4412", "DCTCP"),
        (homa_digest, "#1759BB", "Homa"),
    ]:
        x50, y50 = step_points(digest["cum_frac"], digest["slow_50"])
        x90, y90 = step_points(digest["cum_frac"], digest["slow_90"])
        ax.plot(x50, y50, label=f"{label_prefix} P50", color=color, linewidth=1.8)
        ax.plot(x90, y90, label=f"{label_prefix} P90", color=color, linewidth=1.4, linestyle="--")
    ax.set_xlim(0, 1.0)
    ax.set_yscale("log")
    ax.set_xlabel("Cumulative Fraction of Messages")
    ax.set_ylabel("Slowdown")
    ax.set_title(f"{args.workload.upper()} slowdown over 5 runs")
    ax.grid(which="major", axis="y")
    ax.legend(loc="upper right", prop={"size": 9})
    fig.tight_layout()
    fig.savefig(output_dir / f"vs_tcp_{args.workload}_p50_p90.pdf")
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(6, 4))
    ax.plot(dctcp_x, dctcp_y, label="DCTCP", color="#7A4412")
    ax.plot(homa_x, homa_y, label="Homa", color="#1759BB")
    ax.plot(unloaded_x, unloaded_y, label="Homa best case", color="#d62728")
    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_xlabel("RTT (usec)")
    ax.set_ylabel("Fraction Longer")
    ax.set_title(f"{args.workload.upper()} shortest 10% RPCs")
    ax.grid(which="major", axis="both")
    ax.legend(loc="upper right", prop={"size": 9})
    fig.tight_layout()
    fig.savefig(output_dir / f"short_cdf_{args.workload}.pdf")
    plt.close(fig)


if __name__ == "__main__":
    main()
