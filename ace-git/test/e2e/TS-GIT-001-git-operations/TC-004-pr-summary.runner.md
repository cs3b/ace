# Goal 4 -- PR Summary

## Goal

Run `ace-git pr` and capture direct command behavior for either PR-success or
explicit no-PR-context failure.

## Workspace

Save artifacts to `results/tc/04/`.

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- First attempt must capture `ace-git pr` as:

  - `pr.stdout`
  - `pr.stderr`
  - `pr.exit`

- Do not run cross-command fallbacks for this goal.
