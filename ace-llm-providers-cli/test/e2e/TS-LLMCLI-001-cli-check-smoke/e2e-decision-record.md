# E2E Decision Record - TS-LLMCLI-001 CLI Check Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface | ADD | Verifies packaged executable wiring and user-visible help contract from a real shell command path. | `test/edge/cli_execution_edge_test.rb`, `test/llm_providers_cli_test.rb` |
| TC-002 no-tools deterministic path | ADD | Validates full binary behavior under real PATH constraints (availability summary + process exit code) not captured by unit-level method stubs. | `test/molecules/claude_code_client_test.rb`, `test/molecules/codex_client_test.rb` |
| TC-003 stubbed-tools deterministic path | ADD | Confirms end-to-end available/authenticated summary rendering and success exit semantics through filesystem-backed provider stubs. | `test/atoms/session_finders/claude_session_finder_test.rb`, `test/atoms/session_finders/codex_session_finder_test.rb` |
| Candidate: exhaustive provider output formatting permutations | SKIP | High combinatorial surface better covered by unit tests for formatter/parser internals; smoke scope keeps representative CLI-level assertions only. | `test/edge/cli_execution_edge_test.rb` |
| Candidate: real external provider authentication/network flows | SKIP | Depends on live external provider state and credentials; unsuitable for deterministic smoke E2E. | `test/molecules/claude_oai_client_test.rb`, `test/molecules/codex_oai_client_test.rb` |
