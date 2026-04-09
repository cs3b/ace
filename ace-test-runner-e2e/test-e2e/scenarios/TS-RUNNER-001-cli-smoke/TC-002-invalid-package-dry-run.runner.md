# Goal 2 - Invalid Package Dry-Run Error Path

## Goal

Run a dry-run against a nonexistent package and capture user-facing error semantics.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/invalid_pkg.stdout`, `.stderr`, `.exit` from:
  `ace-test-e2e not-a-real-package --dry-run`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
