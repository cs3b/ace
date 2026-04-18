# Goal 3 - Public Shell Helper Coverage (`ace-test-e2e-sh`)

## Goal

Use `ace-test-e2e-sh` against the generated report path to prove public shell-helper
surface behavior on valid sandbox paths.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/sh_ls.stdout`, `.stderr`, `.exit` from:
  `ace-test-e2e-sh .ace-local/test-e2e/runner-002-report ls`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
