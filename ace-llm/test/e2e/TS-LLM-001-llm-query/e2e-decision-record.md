# E2E Decision Record - TS-LLM-001 Query and Model Routing

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 basic query | KEEP | Verifies packaged `ace-llm` executable behavior with live provider/auth failure handling and artifact capture in scenario flow. | `test/fast/commands/query_command_test.rb`, `test/fast/molecules/client_registry_test.rb` |
| TC-002 model selection | KEEP | Verifies real CLI `--model` routing/output behavior across live provider execution path beyond deterministic parser-only checks. | `test/fast/commands/query_command_test.rb`, `test/fast/molecules/provider_model_parser_test.rb` |
| TC-003 unknown provider | REMOVE | Deterministic CLI contract behavior; no live provider dependency required. | `test/feat/cli_contract_test.rb` |
| Candidate: fallback chain env/config matrix | SKIP | Already covered deterministically in fallback/query-interface tests; no additional E2E value. | `test/feat/query_interface_fallback_test.rb`, `test/feat/cli_args_threading_test.rb` |
