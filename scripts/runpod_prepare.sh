#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

command -v nvidia-smi >/dev/null
nvidia-smi

for data_file in data/2025_Completeness_783.csv data/2025_Connectivity_783.parquet; do
    if [[ ! -s "$data_file" ]]; then
        echo "Required data file is absent or empty: $data_file" >&2
        exit 1
    fi
done

# The selected RunPod PyTorch template already provides CUDA-enabled Torch.
# Inheriting system packages avoids downloading a duplicate GPU wheel while
# retaining the pip fallback below for images that do not include it.
python3 -m venv --system-site-packages .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install torch numpy==1.26.4 pandas pyarrow scipy tqdm joblib matplotlib

python - <<'PY'
import torch

if not torch.cuda.is_available():
    raise SystemExit("PyTorch cannot access CUDA")

print(f"PyTorch CUDA is available: {torch.cuda.get_device_name(0)}")
PY
