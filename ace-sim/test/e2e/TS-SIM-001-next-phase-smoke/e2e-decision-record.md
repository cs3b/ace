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
| TC-002-preset-contract | KEEP (narrow) | Validates default preset chain contract with contract-level artifact checks (not brittle tree assertions). | No |
| TC-003-run-chain-artifacts | KEEP (rewrite) | Validates override routing and one-step synthesis with real success/failure evidence only (no synthetic placeholders). | No |
| TC-005-validate-task-preset | KEEP | Validates shipped `validate-task` preset plan/work chain contract and synthesis metadata. | No |

## Decisions
- `REMOVE`: `TC-004-full-chain-synthesis`, `TC-006-synthesis-provider-guard` (noise/overlap reduced for smoke scope)
- `MODIFY`: `TC-002-preset-contract`, `TC-003-run-chain-artifacts` to prefer public contract and real final-state evidence
- `CONSOLIDATE`: none
- `ADD`: new scenario `TS-SIM-002-public-contracts` for dry-run public contract coverage

## Resulting Structure
- Keep scenario `TS-SIM-001-next-phase-smoke` with 4 TCs (`001`, `002`, `003`, `005`).
- Add scenario `TS-SIM-002-public-contracts` for dry-run public contract verification.
- Maintain scenario-only E2E coverage under `test/e2e/` and keep deterministic guard checks in `test/fast/`.
