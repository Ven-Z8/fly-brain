# Shared Mac and RunPod workflow

Use your GitHub fork as the shared source repository.  In these commands,
replace `<YOUR_GITHUB_FORK_URL>` with the clone URL of your fork (for example,
`https://github.com/your-account/fly-brain.git`).  `origin` is your fork;
`upstream` is the original `eonsystemspbc/fly-brain` project.

## Configure the Mac checkout

Run this once from the existing Mac checkout:

```bash
git remote set-url origin <YOUR_GITHUB_FORK_URL>
git remote add upstream https://github.com/eonsystemspbc/fly-brain.git
git fetch upstream
```

If `upstream` already exists, replace the `git remote add` command with:

```bash
git remote set-url upstream https://github.com/eonsystemspbc/fly-brain.git
```

When you want to update the fork from the original project, first make sure
the working tree is clean, then fast-forward your local branch and push it:

```bash
git pull --ff-only upstream main
git push origin main
```

## Push source changes from the Mac

Author and commit source changes on the Mac.  Push the reviewed commit to your
fork before using it on RunPod:

```bash
git status
git add <files>
git commit -m "describe the change"
git push origin main
```

## Configure and update RunPod

Clone your fork onto RunPod persistent storage, then add the original project
as `upstream`:

```bash
cd /workspace
git clone <YOUR_GITHUB_FORK_URL> fly-brain
cd fly-brain
git remote add upstream https://github.com/eonsystemspbc/fly-brain.git
```

Only pull when no simulation is running.  Update the RunPod checkout with a
fast-forward-only pull, so local changes never get merged implicitly:

```bash
cd /workspace/fly-brain
git pull --ff-only origin main
```

RunPod is a consumer of the fork: do not commit generated artifacts or make
unreviewed source edits there.  Make code changes on the Mac, push them to
`origin`, and then use the fast-forward pull above on RunPod.

## Persistent RunPod data boundary

Keep the repository and all runtime assets on RunPod persistent storage.  Git
tracks source, documentation, small scripts, and the required input files
`data/2025_Completeness_783.csv`, `data/2025_Connectivity_783.parquet`, and
`data/benchmark-results.csv`.  The benchmark results CSV may show modifications
after runs.  The RunPod checkout owns `.venv/`, CUDA and PyTorch installations,
generated sparse weights, logs, and generated Parquet results; do not add those
runtime artifacts to Git.

## Prepare and smoke-test RunPod

From the RunPod repository root, first prepare the CUDA-capable PyTorch
environment and validate the two required data files:

```bash
./scripts/runpod_prepare.sh
```

Then run the isolated P9 PyTorch smoke check:

```bash
./scripts/runpod_p9_smoke.sh
```

The smoke script creates its own label, `runpod_p9_smoke_<UTC timestamp>_<pid>`,
and validates only the new output at
`data/results/runpod_p9_smoke_<UTC timestamp>_<pid>/round_01/pytorch_t0.1s_n1.parquet`.
Copy the label printed by the script when retrieving the result.

## Copy a result back to the Mac

From the Mac, copy a completed result directory with `rsync` (substitute the
RunPod SSH host and port shown by RunPod):

```bash
rsync -avP -e 'ssh -p <RUNPOD_SSH_PORT>' \
  root@<RUNPOD_SSH_HOST>:/workspace/fly-brain/data/results/<RUN_LABEL>/ \
  ./data/results/<RUN_LABEL>/
```
