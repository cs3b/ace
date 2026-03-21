# Goal 1 - Help surface for ace-compressor

## Goal

Run the binary help command and capture command-surface output for operator-facing usage.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` from `ace-compressor --help`

## Constraints

- Use only declared scenario tools.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
