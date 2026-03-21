# Goal 1 - ace-test-e2e Help Command Surface

## Goal

Capture real CLI help output for `ace-test-e2e` and preserve stdout/stderr/exit artifacts.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` from `ace-test-e2e --help`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
