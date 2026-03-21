# Goal 1 — Content Search

## Goal

Run `ace-search "ruby"` against sandbox files and capture matched-line output
proving content-search mode behavior.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/content-search.stdout`, `.stderr`, `.exit`
- `results/tc/01/summary.md` (optional) with concise command/evidence notes

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
