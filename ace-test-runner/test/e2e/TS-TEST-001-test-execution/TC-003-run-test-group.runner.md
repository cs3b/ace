# Goal 3 — Run Test Group

## Goal

Run `ace-test "$PROJECT_ROOT_PATH/ace-search" atoms --report-dir results/tc/03/reports`
and capture output showing group-scoped test execution behavior.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/command.txt` — exact `ace-test` invocation used
- `results/tc/03/report-files.txt` — recursive listing of generated report files under `results/tc/03/reports`
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Use the explicit package path rooted at `$PROJECT_ROOT_PATH` (do not rely on in-sandbox package discovery).
