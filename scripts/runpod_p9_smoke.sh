#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

if [[ ! -f .venv/bin/activate ]]; then
    echo "Missing .venv; run scripts/runpod_prepare.sh first." >&2
    exit 1
fi

for data_file in data/2025_Completeness_783.csv data/2025_Connectivity_783.parquet; do
    if [[ ! -s "$data_file" ]]; then
        echo "Required data file is absent or empty: $data_file" >&2
        exit 1
    fi
done

source .venv/bin/activate
python main.py --experiment p9 --pytorch --t_run 0.1 --n_run 1 --run-label runpod_p9_smoke

python - <<'PY'
from pathlib import Path

import pandas as pd

output_path = Path("data/results/runpod_p9_smoke/round_01/pytorch_t0.1s_n1.parquet")
if not output_path.is_file():
    raise SystemExit(f"Missing smoke output: {output_path}")

output = pd.read_parquet(output_path)
if output.empty:
    raise SystemExit(f"Smoke output is empty: {output_path}")
if "flywire_id" not in output or output["flywire_id"].nunique() < 1:
    raise SystemExit("Smoke output has no distinct flywire_id")

print(f"Validated smoke output: {output_path}")
PY
