# E2E Decision Record - TS-GIT-001 Git Operations

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 git status | KEEP | Validates repository-wide status rendering with real git state and branch tracking signals. | `test/fast/commands/status_test.rb`, `test/fast/organisms/repo_status_loader_test.rb`, `test/feat/cli_routing_test.rb` |
| TC-002 git diff | KEEP | Exercises real diff generation and filtering against actual repository content and output artifacts. | `test/fast/commands/diff_test.rb`, `test/fast/organisms/diff_orchestrator_test.rb` |
| TC-003 branch info | KEEP | Confirms live branch/tracking resolution behavior that depends on real git repository context. | `test/fast/commands/branch_test.rb`, `test/fast/molecules/branch_reader_test.rb` |
| TC-004 PR summary | KEEP | Verifies CLI-level PR metadata flow and output contract beyond isolated parser/molecule checks. | `test/fast/commands/pr_test.rb`, `test/fast/molecules/pr_metadata_fetcher_test.rb` |
| TC-005 diff output path security | KEEP | Guards end-to-end command behavior for output path handling and filesystem interaction boundaries. | `test/fast/commands/diff_test.rb`, `test/feat/cli_routing_test.rb` |
| TC-006 status json no-pr | KEEP | Confirms JSON mode output and `--no-pr` behavior through real command invocation contracts. | `test/fast/commands/status_test.rb`, `test/feat/cli_routing_test.rb` |
