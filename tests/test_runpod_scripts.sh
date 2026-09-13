#!/usr/bin/env bash

set -euo pipefail

tr -d '\r' < .gitignore | grep -Fqx '.venv/'
test -f docs/RUNPOD_WORKFLOW.md
grep -Fq 'git pull --ff-only' docs/RUNPOD_WORKFLOW.md
grep -Fq './scripts/runpod_prepare.sh' docs/RUNPOD_WORKFLOW.md
grep -Fq './scripts/runpod_p9_smoke.sh' docs/RUNPOD_WORKFLOW.md
grep -Fq 'runpod_p9_smoke_<UTC timestamp>_<pid>' docs/RUNPOD_WORKFLOW.md
grep -Fq 'data/2025_Completeness_783.csv' docs/RUNPOD_WORKFLOW.md
grep -Fq 'data/benchmark-results.csv' docs/RUNPOD_WORKFLOW.md
grep -Fq 'nvidia-smi' scripts/runpod_prepare.sh
grep -Fq -- 'python3 -m venv --system-site-packages .venv' scripts/runpod_prepare.sh
grep -Fq 'torch.cuda.is_available()' scripts/runpod_prepare.sh
grep -Fq -- '--experiment p9' scripts/runpod_p9_smoke.sh
grep -Fq -- '--pytorch' scripts/runpod_p9_smoke.sh
grep -Fq 'read_parquet' scripts/runpod_p9_smoke.sh
grep -Fq 'runpod_p9_smoke_$(date -u +%Y%m%dT%H%M%SZ)_$$' scripts/runpod_p9_smoke.sh
grep -Fq 'unset FLY_BRAIN_DISABLE_SPIKE_IO' scripts/runpod_p9_smoke.sh
grep -Fq 'if not torch.cuda.is_available():' scripts/runpod_p9_smoke.sh
grep -Fq 'RUN_LABEL="$run_label" python -' scripts/runpod_p9_smoke.sh
grep -Fq 'os.environ["RUN_LABEL"]' scripts/runpod_p9_smoke.sh
grep -Fq 'if output.empty:' scripts/runpod_p9_smoke.sh
grep -Fq '"flywire_id" not in output' scripts/runpod_p9_smoke.sh
grep -Fq 'output["flywire_id"].nunique() < 1' scripts/runpod_p9_smoke.sh
grep -Fqx 'python main.py --experiment p9 --pytorch --t_run 0.1 --n_run 1 --run-label "$run_label"' scripts/runpod_p9_smoke.sh
test "$(grep -Fc 'python main.py' scripts/runpod_p9_smoke.sh)" -eq 1
test "$(grep -Fc 'FLY_BRAIN_DISABLE_SPIKE_IO' scripts/runpod_p9_smoke.sh)" -eq 1
if grep -Eq -- '--(brian2-cpu|brian2cuda-gpu|nestgpu|genn|brian2genn|disable-spike-io)' scripts/runpod_p9_smoke.sh; then
    exit 1
fi
