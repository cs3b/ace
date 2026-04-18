# Goal 2 - Status unknown provider error

## Goal

Run status with an unknown provider ID and capture the public error behavior.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:

- `results/tc/02/status-unknown.stdout`, `.stderr`, `.exit` from `ace-handbook status --provider definitely-not-a-provider`

## Constraints

- Use only declared scenario tools.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
