# Results Layout

`experiments/results` is now treated as an index, not a dumping ground.

## Layout

- `runs/baseline/`
  - immutable fetched run directories for `cp_basic` and `cp_vs_tcp`
- `runs/transport/`
  - immutable fetched run directories for transport-comparison benchmarks
- `runs/baseline/latest`
  - symlink to the most recently fetched baseline run
- `runs/transport/latest`
  - symlink to the most recently fetched transport run
- `summaries/`
  - hand-written summaries and rollups
- `legacy_root_snapshot/`
  - older artifacts from before the cleanup

## Conventions

- Every fetched benchmark run gets its own directory under `runs/...`.
- Each run keeps its own raw RTT files, node logs, metrics, and `reports/`.
- Top-level `experiments/results/reports` is no longer used for new runs.
- New wrapper fetches do not overwrite older charts or digests.

## Current Run Pointers

- latest transport run:
  - [runs/transport/latest](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport/latest)
- latest baseline run:
  - [runs/baseline/latest](/NAS/School/CS8803/HomaModule/experiments/results/runs/baseline/latest)

## Migration Note

The loose root-level transport artifacts from the recent `w4` work were moved into:

- [runs/transport/cp_transport_w4_20260401221330](/NAS/School/CS8803/HomaModule/experiments/results/runs/transport/cp_transport_w4_20260401221330)

That directory should be treated as the canonical location for the latest fetched `w4` transport reports and logs.
