# Goal 1 - Help surface for both binaries

## Goal

Run lightweight CLI entry checks and capture command-surface behavior for
`ace-models` and `ace-llm-providers`.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/models-help.stdout`, `.stderr`, `.exit` from `ace-models --help`
- `results/tc/01/providers-help.stdout`, `.stderr`, `.exit` from `ace-llm-providers --help`

## Constraints

- Use only declared scenario tools.
- Capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
