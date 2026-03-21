# E2E Decision Record - TS-HANDBOOK-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface | ADD | Verifies packaged executable wiring and command routing from real shell invocation (`ace-handbook --help`). | `test/cli/commands/status_test.rb`, `test/handbook_test.rb` |
| TC-002 status table output | ADD | Confirms CLI process exit semantics and user-visible table output contract in an end-to-end execution context. | `test/cli/commands/status_test.rb`, `test/organisms/status_collector_test.rb` |
| TC-003 status json output | ADD | Confirms end-to-end JSON format contract through real command invocation, beyond stubbed unit command execution. | `test/cli/commands/status_test.rb`, `test/organisms/status_collector_test.rb` |
| Candidate: sync side-effect mutation matrix across providers | SKIP | Requires broader fixture/setup and is not needed for initial smoke scope; internal sync logic already covered by organism tests. | `test/organisms/provider_syncer_test.rb`, `test/organisms/skill_inventory_test.rb` |
| Candidate: exhaustive status output formatting permutations | SKIP | Formatting matrix is command/unit territory; smoke E2E keeps one table and one JSON representative. | `test/cli/commands/status_test.rb` |
