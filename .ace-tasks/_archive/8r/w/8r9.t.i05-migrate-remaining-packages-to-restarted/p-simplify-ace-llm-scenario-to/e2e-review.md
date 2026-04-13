# E2E Review - ace-llm

Reviewed package: `ace-llm`
Scope: `TS-LLM-001-llm-query`
Workflow: `ace-bundle wfi://e2e/review`

## Coverage Matrix

| Feature | Deterministic Coverage | E2E Coverage | Status | Notes |
| --- | --- | --- | --- | --- |
| Basic query execution through packaged CLI | `test/fast/commands/query_command_test.rb` | `TC-001-basic-query` | Covered | E2E keeps real executable/provider path evidence. |
| Explicit model routing (`--model`) | `test/fast/commands/query_command_test.rb`, `test/fast/molecules/provider_model_parser_test.rb` | `TC-002-model-selection` | Covered | E2E keeps real routing/output behavior. |
| Unknown provider rejection | `test/feat/cli_contract_test.rb` | `TC-003-unknown-provider` (pre-migration) | Overlap | Deterministic CLI contract check; no live provider dependency. |

## Findings

- `TC-003-unknown-provider` does not require E2E cost and overlaps deterministic CLI behavior.
- `TC-001` and `TC-002` retain genuine E2E value (packaged executable + real provider/auth path + artifact capture).
