# Goal 1 — Run Package Tests

## Goal

Run `ace-test "$PROJECT_ROOT_PATH/ace-search" atoms --report-dir results/tc/01/reports`
and capture end-state evidence proving the package+target run completed successfully.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/command.txt` - exact `ace-test` invocation used
- `results/tc/01/report-files.txt` - file inventory from `results/tc/01/reports`
- Raw command captures (`*.stdout`, `*.stderr`, `*.exit`) for the run command

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
- Use the explicit package path rooted at `$PROJECT_ROOT_PATH` (do not rely on in-sandbox package discovery).
