# Goal 1 - Help and Command Surface

## Goal

Run lightweight CLI entry checks in a clean sandbox and capture command-surface
behavior for `ace-demo`.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` from `ace-demo --help`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
