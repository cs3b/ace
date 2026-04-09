# Goal 4 — JSON Output

## Goal

Run `ace-search --json --type content "class Search" "$ACE_E2E_SOURCE_ROOT/ace-search/lib"`
and capture structured output evidence proving JSON mode behavior for content search.

## Workspace

Save artifacts to `results/tc/04/`.

Capture:
- `results/tc/04/json-search.stdout`, `.stderr`, `.exit`

Optional capture:
- `results/tc/04/summary.md`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/04/`.
- Do not write outside the sandbox.
- Search path must remain `$ACE_E2E_SOURCE_ROOT/ace-search/lib` for deterministic matches.
