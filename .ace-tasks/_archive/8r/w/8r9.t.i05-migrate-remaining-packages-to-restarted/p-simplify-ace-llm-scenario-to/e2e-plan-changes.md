# E2E Plan Changes - ace-llm

Reviewed package: `ace-llm`
Scope: `TS-LLM-001-llm-query`
Workflow: `ace-bundle wfi://e2e/plan-changes`

## Classification

- `KEEP`: `TC-001-basic-query`
- `KEEP`: `TC-002-model-selection`
- `REMOVE`: `TC-003-unknown-provider`
- `ADD`: `test/feat/cli_contract_test.rb` (deterministic replacement for removed TC)
- `CONSOLIDATE`: none

## Rewrite Actions

1. Remove `TC-003` runner and verifier files.
2. Update `scenario.yml` and runner/verifier wrappers to 2-TC scenario.
3. Add `e2e-decision-record.md` documenting KEEP/REMOVE decisions and reviewed deterministic coverage.
4. Move deterministic coverage to `test/fast` and `test/feat` paths and update references.
