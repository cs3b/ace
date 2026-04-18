# Goal 1 - Real Package Scenario Run Produces Report Tree

## Goal

Run a real (non-dry-run) `ace-test-e2e` execution against a fixture package
scenario and capture command/report artifacts.

## Workspace

Save artifacts to `results/tc/01/`.

Capture:
- `results/tc/01/real_run.stdout`, `.stderr`, `.exit` from:
  `ace-test-e2e ace-demo TS-DEMO-001 --provider glite --verify --report-dir .ace-local/test-e2e/runner-002-report`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/01/`.
- Do not write outside the sandbox.
