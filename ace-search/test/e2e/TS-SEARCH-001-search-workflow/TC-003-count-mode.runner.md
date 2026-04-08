# Goal 3 — Count Mode

## Goal

Run `ace-search --type content --files-with-matches "test" "$ACE_E2E_SOURCE_ROOT/ace-search"`
and `ace-search --type content --count "def" "$ACE_E2E_SOURCE_ROOT/ace-search/test"`,
then capture count-style output summary.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/files-with-matches.stdout`, `.stderr`, `.exit`
- `results/tc/03/count.stdout`, `.stderr`, `.exit`
- `results/tc/03/summary.md` (optional) with observed count semantics

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Use explicit search paths rooted at `$PROJECT_ROOT_PATH` so count behavior is
  measured against stable repo content rather than the transient sandbox root.
