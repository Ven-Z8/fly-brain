#!/usr/bin/env bash

set -euo pipefail

grep -Fq '.venv/' .gitignore
test -f docs/RUNPOD_WORKFLOW.md
grep -Fq 'git pull --ff-only' docs/RUNPOD_WORKFLOW.md
grep -Fq 'nvidia-smi' scripts/runpod_prepare.sh
grep -Fq 'torch.cuda.is_available()' scripts/runpod_prepare.sh
grep -Fq -- '--experiment p9' scripts/runpod_p9_smoke.sh
grep -Fq -- '--pytorch' scripts/runpod_p9_smoke.sh
grep -Fq 'read_parquet' scripts/runpod_p9_smoke.sh
