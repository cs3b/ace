# Goal 1 - Help and Usage Surface

## Goal

Run lightweight CLI entry checks in a clean sandbox and capture command wiring
behavior for `ace-retro`.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` from `ace-retro --help`
- `results/tc/01/create-missing-title.stdout`, `.stderr`, `.exit` from `ace-retro create`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
