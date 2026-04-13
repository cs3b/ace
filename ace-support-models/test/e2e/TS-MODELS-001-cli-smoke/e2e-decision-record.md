# E2E Decision Record - TS-MODELS-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface for both binaries | KEEP | Verifies packaged executable wiring and command-surface exposure via real process invocation for both entrypoints. | `test/fast/commands/models_commands_test.rb`, `test/fast/commands/providers_commands_test.rb` |
| TC-002 cache clear lifecycle | KEEP | Requires real CLI execution against filesystem-backed cache paths and confirms side-effect deletion behavior end-to-end. | `test/fast/commands/cache_commands_test.rb`, `test/feat/cli_integration_test.rb` |
| TC-003 providers list/show with seeded cache | KEEP | Confirms user-visible output and exit semantics from real `ace-llm-providers` invocations using on-disk cache data. | `test/fast/commands/providers_commands_test.rb`, `test/feat/cli_integration_test.rb` |
| TC-004 invalid filter error semantics | KEEP | Validates CLI-level stderr and exit-code contract for invalid filter input in real command execution context. | `test/feat/cli_integration_test.rb`, `test/fast/commands/models_commands_test.rb` |
| Candidate: every `ace-models search` output formatting permutation | REMOVE | Output-format matrix is deterministic command territory and is covered by fast command tests. | `test/fast/commands/models_commands_test.rb` |
| Candidate: provider sync remote fetch and commit behavior | REMOVE | Network-dependent and commit-path internals are deterministic orchestration/unit concerns, not smoke E2E scope. | `test/feat/cli_integration_test.rb`, `test/fast/organisms/provider_sync_orchestrator_test.rb` |
