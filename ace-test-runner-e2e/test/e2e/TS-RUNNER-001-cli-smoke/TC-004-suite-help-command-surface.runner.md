# Goal 4 - ace-test-e2e-suite Help Command Surface

## Goal

Capture real CLI help output for `ace-test-e2e-suite` and preserve stdout/stderr/exit artifacts.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:
- `results/tc/04/suite_help.stdout`, `.stderr`, `.exit` from `ace-test-e2e-suite --help`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
