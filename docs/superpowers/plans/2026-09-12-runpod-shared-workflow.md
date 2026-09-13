# RunPod Shared Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a Git-shared Mac/RunPod workflow and a reproducible PyTorch P9 GPU smoke path.

**Architecture:** The GitHub fork is the shared source repository; generated assets remain on persistent RunPod storage. A preparation script establishes the minimal CUDA PyTorch environment, while a separate smoke script performs the first P9 run and validates its recorded spikes.

**Tech Stack:** Git, Bash, Python 3.10+, PyTorch CUDA, pandas, pyarrow, RunPod Linux.

**Spec:** `docs/superpowers/specs/2026-09-12-runpod-shared-workflow-design.md`

## Global Constraints

- Use only the upstream PyTorch backend for the initial GPU smoke path.
- Run `p9` for exactly `0.1` seconds and one trial; retain spike recording.
- Do not alter neural parameters, weights, connectivity, experiment definitions, or duration lists.
- Keep `.venv/`, generated weights, logs, and Parquet output out of Git.
- RunPod pulls only while a simulation is not running.

---

### Task 1: Document and protect the shared repository boundary

**Files:**
- Create: `docs/RUNPOD_WORKFLOW.md`
- Modify: `.gitignore`
- Test: `tests/test_runpod_scripts.sh`

**Interfaces:**
- Consumes: a GitHub fork URL supplied by the user.
- Produces: exact Mac and RunPod remote configuration commands, and an ignore rule for `.venv/`.

- [ ] **Step 1: Write the failing static test**

```bash
grep -Fqx '.venv/' .gitignore
test -f docs/RUNPOD_WORKFLOW.md
grep -Fq 'git pull --ff-only' docs/RUNPOD_WORKFLOW.md
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test_runpod_scripts.sh`

Expected: failure because the workflow document and `.venv/` ignore rule do not exist.

- [ ] **Step 3: Add the minimal documentation and ignore rule**

Document `origin` as the user's fork, `upstream` as the original project, a
Mac push → RunPod fast-forward pull sequence, persistent RunPod data policy,
and result-copy command. Append only `.venv/` to `.gitignore`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test_runpod_scripts.sh`

Expected: the static checks for the workflow and ignore rule pass; later
script checks are intentionally not yet present and will be added in Task 2.

- [ ] **Step 5: Commit**

```bash
git add .gitignore docs/RUNPOD_WORKFLOW.md tests/test_runpod_scripts.sh
git commit -m "docs: add shared Mac RunPod workflow"
```

### Task 2: Add the minimal RunPod prepare and smoke commands

**Files:**
- Create: `scripts/runpod_prepare.sh`
- Create: `scripts/runpod_p9_smoke.sh`
- Modify: `tests/test_runpod_scripts.sh`

**Interfaces:**
- Consumes: a cloned repository containing `data/2025_Completeness_783.csv`
  and `data/2025_Connectivity_783.parquet`, an NVIDIA GPU, and `python3`.
- Produces: `.venv/` with CUDA-capable PyTorch and, on success, the P9 output
  at `data/results/runpod_p9_smoke/round_01/pytorch_t0.1s_n1.parquet`.

- [ ] **Step 1: Extend the failing static test**

```bash
grep -Fq 'nvidia-smi' scripts/runpod_prepare.sh
grep -Fq 'torch.cuda.is_available()' scripts/runpod_prepare.sh
grep -Fq -- '--experiment p9' scripts/runpod_p9_smoke.sh
grep -Fq -- '--pytorch' scripts/runpod_p9_smoke.sh
grep -Fq 'read_parquet' scripts/runpod_p9_smoke.sh
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test_runpod_scripts.sh`

Expected: failure because the two scripts do not exist.

- [ ] **Step 3: Write the minimal scripts**

`runpod_prepare.sh` must use `set -euo pipefail`, check `nvidia-smi`, create
`.venv`, install `torch numpy==1.26.4 pandas pyarrow scipy tqdm joblib
matplotlib`, verify CUDA in Python, and reject absent or empty data files.

`runpod_p9_smoke.sh` must use `set -euo pipefail`, require `.venv`, require
the data files, run only the requested 0.1-second PyTorch P9 command with
`--run-label runpod_p9_smoke`, then use pandas to require a nonempty Parquet
file and at least one distinct `flywire_id`.

- [ ] **Step 4: Run static and syntax verification**

Run: `bash tests/test_runpod_scripts.sh && bash -n scripts/runpod_prepare.sh scripts/runpod_p9_smoke.sh`

Expected: all checks pass. A GPU execution is deferred until the user has a
running RunPod RTX 4090.

- [ ] **Step 5: Commit**

```bash
git add scripts/runpod_prepare.sh scripts/runpod_p9_smoke.sh tests/test_runpod_scripts.sh
git commit -m "test: add RunPod PyTorch P9 smoke path"
```
