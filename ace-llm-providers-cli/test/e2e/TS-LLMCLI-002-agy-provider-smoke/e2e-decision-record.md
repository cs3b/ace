# E2E Decision Record: agy provider smoke

Last verified: 2026-08-29
Verified by: assignment 8vswo5 / task 8vs.t.whe

## Coverage decisions

| Goal | Decision | Reason | Related deterministic coverage |
| --- | --- | --- | --- |
| TC-001 fixture-backed success | ADD | Verifies real `ace-llm` routing into the new `agy` provider with deterministic JSON output and no live authentication. | `test/fast/molecules/agy_client_test.rb` |
| TC-002 resume flag passthrough | ADD | Confirms ACE preserves documented Antigravity conversation flags without rewriting them. | `test/fast/molecules/agy_client_test.rb` |
| TC-003 fixture-backed failure | ADD | Verifies non-zero provider execution surfaces a stable failure through the CLI. | `test/fast/molecules/agy_client_test.rb` |
