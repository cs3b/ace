# Goal 4 -- JSON Output

## Goal

Run `ace-search --json --type content "Goal" .`
and capture structured output evidence proving JSON mode behavior for a
user-facing content-search workflow.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:

- `results/tc/04/json-search.stdout`, `.stderr`, `.exit`
- `results/tc/04/summary.md` (optional) with high-level payload shape notes

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- Validate JSON contract from documented flags/behavior, not implementation-specific code tokens.
