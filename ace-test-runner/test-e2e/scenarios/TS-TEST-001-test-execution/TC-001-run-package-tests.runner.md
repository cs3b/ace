# Goal 1 — Run Package Tests

## Goal

Run `ace-test "$ACE_E2E_SOURCE_ROOT/ace-search" atoms --report-dir results/tc/01/reports`
and capture output proving tests execute with exit code `0`.

## Workspace

Save artifacts to `results/tc/01/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
- Use the explicit package path rooted at `$PROJECT_ROOT_PATH` (do not rely on in-sandbox package discovery).
