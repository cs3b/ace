# E2E Decision Record - TS-HANDBOOK-002 Sync Behavior

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 sync-provider-projection | KEEP | Confirms real CLI `sync` invocation, projection side effects, and user-visible summary output in one end-to-end flow. | `test/fast/cli/commands/sync_test.rb`, `test/fast/organisms/provider_syncer_test.rb` |
| TC-002 status-unknown-provider-error | KEEP | Confirms public error semantics (`Unknown provider`, non-zero exit) from actual CLI execution rather than in-process unit stubs. | `test/fast/cli/commands/status_test.rb`, `test/fast/organisms/status_collector_test.rb` |
