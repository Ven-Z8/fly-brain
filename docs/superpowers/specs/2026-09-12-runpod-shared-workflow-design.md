# RunPod Shared Workflow Design

## Goal

Use one GitHub fork as the source-code common ground between a Mac development
checkout and a persistent RunPod GPU checkout, then make the first PyTorch P9
smoke run repeatable without committing environment files, connectome caches,
or spike outputs.

## Repository topology

The user's GitHub fork is `origin` on both machines. The original
`eonsystemspbc/fly-brain` repository is `upstream` on the Mac and RunPod.
Changes are authored and committed on the Mac, pushed to `origin`, then pulled
on RunPod with `git pull --ff-only`. RunPod does not commit generated artifacts
or make unreviewed source edits.

## RunPod runtime boundary

RunPod persistent storage owns the virtual environment, CUDA installation,
PyTorch wheels, generated sparse weights, logs, and generated Parquet outputs.
Git tracks source, documentation, small scripts, and the required input files
`data/2025_Completeness_783.csv`, `data/2025_Connectivity_783.parquet`, and
`data/benchmark-results.csv`; the results CSV may be modified by benchmark
runs. The already ignored `data/results/` and weight-cache paths remain local;
`.venv/` is added to the ignore rules.

## Components

- `docs/RUNPOD_WORKFLOW.md` tells the user how to create the GitHub fork,
  configure `origin` and `upstream`, clone on RunPod, pull safely, and copy a
  result back to the Mac.
- `scripts/runpod_prepare.sh` is idempotent inside a completed clone. It
  creates `.venv`, installs only the PyTorch-path dependencies, and verifies
  the NVIDIA GPU, CUDA-enabled PyTorch, and two required FlyWire data files.
- `scripts/runpod_p9_smoke.sh` requires that prepared environment, clears an
  inherited spike-I/O disable flag, verifies CUDA immediately before invoking
  the benchmark, runs only `p9` on the PyTorch backend for 0.1 seconds, and
  uses a timestamp-and-process-unique label to reject a missing or empty new
  spike Parquet file.
- `tests/test_runpod_scripts.sh` statically verifies that the scripts retain
  these safety gates and do not invoke unsupported backends.

## Constraints

- The Mac is never asked to use CUDA.
- The initial run uses only `--pytorch`, `--experiment p9`, `--t_run 0.1`, and
  `--n_run 1`.
- Spike recording stays enabled.
- No connectome, neuron model, synaptic weight, experiment, or 0.5-second
  duration change is made in this setup. The 0.5-second change is conditional
  on a verified 0.1-second GPU run.
- `git pull` must happen only while no simulation is running.

## Acceptance criteria

On a RunPod RTX 4090, `./scripts/runpod_prepare.sh` exits successfully only
after CUDA PyTorch and both data files are present. Then
`./scripts/runpod_p9_smoke.sh` writes a nonempty
`data/results/runpod_p9_smoke_<UTC timestamp>_<pid>/round_01/pytorch_t0.1s_n1.parquet`
with at least one active `flywire_id`; it validates that invocation's unique
path rather than an existing result.
