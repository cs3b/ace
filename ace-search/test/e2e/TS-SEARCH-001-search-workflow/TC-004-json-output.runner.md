# Goal 4 — JSON Output

## Goal

Run `ace-search --json --type content "class Search" "$PROJECT_ROOT_PATH/ace-search/lib"`
and capture structured output evidence proving JSON mode behavior for content search.

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
- Search path must remain `$PROJECT_ROOT_PATH/ace-search/lib` for deterministic matches.
