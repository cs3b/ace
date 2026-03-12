# Goal 2 — Run Specific File

## Goal

Run `ace-test "$PROJECT_ROOT_PATH/ace-search" test/atoms/tool_checker_test.rb --report-dir results/tc/02/reports`
and verify output is scoped to that file.

## Workspace

Save artifacts to `results/tc/02/`.

Capture:
- `results/tc/02/command.txt` — exact `ace-test` invocation used
- `results/tc/02/report-files.txt` — recursive listing of generated report files under `results/tc/02/reports`
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- Use the explicit package path rooted at `$PROJECT_ROOT_PATH` (do not rely on in-sandbox package discovery).
