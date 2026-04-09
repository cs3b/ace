# Goal 3 - Dry-Run Discovers Repo Scenarios

## Goal

Run `ace-test-e2e` in dry-run mode against an existing package from repository root
and capture scenario discovery output.

## Workspace

Save artifacts to `results/tc/03/`.

Capture:
- `results/tc/03/discovery.stdout`, `.stderr`, `.exit` from:
  `cd "$PROJECT_ROOT_PATH" && ace-test-e2e ace-demo --dry-run --tags smoke`

## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
