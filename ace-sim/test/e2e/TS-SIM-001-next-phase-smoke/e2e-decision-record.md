# E2E Decision Record: TS-SIM-001-next-phase-smoke

## Context
- Package: `ace-sim`
- Workflow stages applied:
  - `ace-bundle wfi://e2e/review`
  - `ace-bundle wfi://e2e/plan-changes`
  - `ace-bundle wfi://e2e/rewrite`
- Deterministic tests were relocated to `test/fast/*`, so E2E remains workflow-focused.

## Coverage Matrix (Current Scenario)
| TC | Classification | Reason | Deterministic Replacement Needed |
|---|---|---|---|
| TC-001-help-survey | KEEP | Validates real CLI help surface and option visibility on the binary entrypoints. | No |
| TC-002-preset-contract | KEEP | Validates full default preset chain behavior and run artifact contract in a real run directory. | No |
| TC-003-run-chain-artifacts | KEEP | Validates CLI override routing and one-step synthesis behavior with provider-aware fallback path. | No |
| TC-004-full-chain-synthesis | KEEP | Validates full-chain aggregation into final synthesis inputs and recorded outcome behavior. | No |
| TC-005-validate-task-preset | KEEP | Validates shipped `validate-task` preset plan/work chain contract and synthesis metadata. | No |
| TC-006-synthesis-provider-guard | KEEP | Validates user-facing CLI guard behavior for invalid synthesis option combinations. | No |

## Decisions
- `REMOVE`: none
- `MODIFY`: scenario wording only (`unit tests` -> `fast deterministic tests`) to align with current model
- `CONSOLIDATE`: none
- `ADD`: none

## Resulting Structure
- Keep single scenario `TS-SIM-001-next-phase-smoke` with 6 TCs.
- Maintain scenario-only E2E coverage under `test/e2e/`.
- Keep deterministic assertions outside E2E in `test/fast/`.
