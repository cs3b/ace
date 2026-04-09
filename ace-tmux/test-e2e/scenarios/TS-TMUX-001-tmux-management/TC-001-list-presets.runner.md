# Goal 1 — List Presets

## Goal

Run `ace-tmux list sessions` and capture output listing available session
presets.

If one or more presets exist, record a selected preset name in a dedicated
artifact for downstream goals. If no presets exist, record an explicit
empty-state artifact.

## Workspace

Save artifacts to `results/tc/01/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
- Capture command stdout/stderr/exit as raw artifacts.
- Write one of:
  - `selected-preset.txt` containing only the selected preset name, or
  - `no-preset.txt` explaining why no preset was available.
