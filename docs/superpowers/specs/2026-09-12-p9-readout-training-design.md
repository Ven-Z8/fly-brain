# P9 Readout Training Design

## Status

Design proposal only. No training code is included in this change.

## Goal and scope

Add the first trainable task on top of the validated FlyWire v783 PyTorch
simulation without changing the connectome or neuron parameters. The v1 task is
a controlled P9 cue-to-action problem: each episode stimulates either the P9
left or P9 right neuron at the existing 100 Hz rate, and a trainable two-class
readout predicts the cued action. This measures whether the frozen network
produces separable activity and gives us a safe first learning loop; it is not
yet a closed-loop walking simulation.

The FlyWire recurrent weights, LIF parameters, and input P9 neurons remain
frozen. Only a small `torch.nn.Linear(N, 2)` readout is optimized, where `N` is
the number of neurons in the v783 completeness table.

## Episode and data flow

1. Sample a deterministic episode label (`left` or `right`) from a seeded task
   generator.
2. Build a `[batch, N]` rate tensor with 100 Hz on the selected P9 index and
   zero elsewhere.
3. Reset the frozen `TorchModel` state and simulate one 100 ms episode at the
   existing 0.1 ms timestep on CUDA.
4. Accumulate per-neuron spike counts on-device; no per-spike Parquet output is
   written during training.
5. Normalize the count vector, pass it through the trainable readout, compute
   cross-entropy, and update only readout parameters.
6. Record loss, accuracy, reward (1 for a correct action, 0 otherwise), and
   seed/run metadata.

Training, validation, and test labels are generated from independent seed
streams. Batches use the existing model batch dimension so multiple episodes
run concurrently on the GPU. A fresh model state is required for every batch
to prevent leakage between episodes.

## Components and interfaces

- `code/train_p9_readout.py`: CLI, episode batching, readout optimization,
  evaluation, checkpointing, and metrics.
- Existing `code/run_pytorch.py`: reused for `get_hash_tables`, `get_weights`,
  and `TorchModel`; its recurrent weights and neuron parameters are not edited.
- `scripts/runpod_train_p9_readout.sh`: checks `.venv`, CUDA, both v783 data
  files, creates the results directory, and invokes the training CLI.
- `tests/test_p9_readout_training.py`: CPU-only unit tests for label encoding,
  deterministic episode generation, frozen-weight invariants, and checkpoint
  round-tripping.

The CLI should expose `--train-episodes`, `--val-episodes`, `--test-episodes`,
`--batch-size`, `--epochs`, `--lr`, `--episode-ms`, `--seed`, and
`--run-label`. Defaults should be conservative for the 24 GB RTX 4090 (1,000
training episodes, 200 validation episodes, 200 test episodes, 32 episodes per
GPU batch, 10 epochs, 1e-3 learning rate, and a 100 ms episode).

## Artifacts and reproducibility

Write all training outputs under:

`data/results/training/p9_readout/<run-label>/`

The directory contains:

- `config.json`: CLI arguments, git commit, data paths, CUDA device, and seed;
- `metrics.csv`: epoch-level train/validation loss, accuracy, and reward;
- `checkpoint.pt`: readout state, optimizer state, epoch, and config;
- `test_metrics.json`: held-out accuracy, loss, reward, and confusion matrix.

Checkpoint writes must be atomic (temporary file followed by rename). A resume
option may be added after the first end-to-end run; v1 always starts from a
fresh readout so results are easy to reproduce.

## Acceptance criteria

- The task generator maps exactly one of the two known P9 IDs to each episode
  and rejects missing IDs.
- The recurrent weight tensor and all `TorchModel` parameters are unchanged
  before and after training; only the readout receives gradients.
- CPU unit tests pass without loading the 97 MB connectivity file.
- The RunPod smoke training completes with finite metrics and all four output
  artifacts present.
- Held-out accuracy and reward are reported against the 50% binary-chance
  baseline; the run is not called a learned behavior unless it exceeds a
  predeclared threshold on the held-out set.

## Non-goals and next phase

V1 does not add STDP, surrogate-gradient backpropagation through spikes,
synaptic plasticity, sensory image/odor encoding, body mechanics, or a walking
environment. It must not silently claim that P9 readout classification is
forward walking.

After v1 is stable, v2 can add a selected-circuit reward-modulated plasticity
experiment with an explicit motor readout and environment. Full-connectome
plasticity should wait until memory use, stability, and biological assumptions
are measured.
