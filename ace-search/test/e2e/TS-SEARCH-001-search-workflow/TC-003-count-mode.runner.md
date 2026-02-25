# Goal 3 — Count Mode

## Goal

Run `ace-search --type content --files-with-matches "test"` and a
count-oriented command (`rg -c` equivalent via ace-search options if available),
then capture count-style output summary.

## Workspace

Save artifacts to `results/tc/03/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
