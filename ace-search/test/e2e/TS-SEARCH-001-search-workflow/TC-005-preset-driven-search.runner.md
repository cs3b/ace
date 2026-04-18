# Goal 5 -- Preset-Driven Search

## Goal

Run `ace-search "TODO" --preset daily-scan` and capture the user-facing preset
experience.

## Workspace

Save artifacts to `results/tc/05/`.

Capture:

- `results/tc/05/preset-search.stdout`, `.stderr`, `.exit`
- `results/tc/05/summary.md` (optional) with concise notes about preset behavior

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/05/`.
- Do not write outside the sandbox.
- This goal validates the public preset entrypoint; do not use internal config probing.
