# Goal 1 — Run Full Suite

## Goal

Run `ace-test-suite --group foundation` (or a small available group) and
capture output showing aggregate multi-package execution.

## Workspace

Save artifacts to `results/tc/01/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
