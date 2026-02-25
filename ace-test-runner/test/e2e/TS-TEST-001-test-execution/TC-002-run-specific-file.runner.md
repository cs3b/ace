# Goal 2 — Run Specific File

## Goal

Run `ace-test ace-search test/atoms/tool_checker_test.rb` and verify output is
scoped to that file.

## Workspace

Save artifacts to `results/tc/02/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
