# E2E Decision Record - TS-MODELS-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface for both binaries | ADD | Verifies packaged executable wiring and command-surface exposure via real process invocation for both entrypoints. | `test/commands/models_commands_test.rb`, `test/commands/providers_commands_test.rb` |
| TC-002 cache clear lifecycle | ADD | Requires real CLI execution against filesystem-backed cache paths and confirms side-effect deletion behavior end-to-end. | `test/commands/cache_commands_test.rb`, `test/integration/cli_integration_test.rb` |
| TC-003 providers list/show with seeded cache | ADD | Confirms user-visible output and exit semantics from real `ace-llm-providers` invocations using on-disk cache data. | `test/commands/providers_commands_test.rb`, `test/integration/cli_integration_test.rb` |
| TC-004 invalid filter error semantics | ADD | Validates CLI-level stderr and exit-code contract for invalid filter input in real command execution context. | `test/integration/cli_integration_test.rb`, `test/commands/models_commands_test.rb` |
| Candidate: every `ace-models search` output formatting permutation | SKIP | Output-format matrix is command/unit territory; smoke E2E keeps one representative error path only. | `test/commands/models_commands_test.rb` |
| Candidate: provider sync remote fetch and commit behavior | SKIP | Network-dependent and commit-path internals are already covered by integration/organism tests; not needed for initial smoke scope. | `test/integration/cli_integration_test.rb`, `test/organisms/provider_sync_orchestrator_test.rb` |
