#!/usr/bin/env bash

set -euo pipefail

grep -Fqx '.venv/' .gitignore
test -f docs/RUNPOD_WORKFLOW.md
grep -Fq 'git pull --ff-only' docs/RUNPOD_WORKFLOW.md
