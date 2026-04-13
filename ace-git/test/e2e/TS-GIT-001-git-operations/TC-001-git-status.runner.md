# Goal 1 — Git Status

## Goal

Run `ace-git status --no-pr` and capture output against the current sandbox
working tree state.

## Workspace

Save artifacts to `results/tc/01/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
- Bootstrap a real branch context first: create one tracked file, run `git add -A`, and commit once so later `branch` and `diff` goals run against an initialized repository.
- Capture bootstrap command artifacts as:
  - `results/tc/01/bootstrap.stdout`
  - `results/tc/01/bootstrap.stderr`
  - `results/tc/01/bootstrap.exit`
