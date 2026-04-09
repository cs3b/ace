# Goal 3 — Branch Info

## Goal

Run `ace-git branch` and capture output showing current branch context in the
sandbox repository.

## Workspace

Save artifacts to `results/tc/03/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Run this goal in the same initialized repository from Goal 1 (with at least one commit on a named branch).
- If branch info fails due to missing branch initialization, perform one bootstrap commit and re-run `ace-git branch` once, capturing both attempts.
