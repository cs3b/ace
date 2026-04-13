# E2E Decision Record - TS-DOCS-001 Docs Operations

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 discover docs | KEEP | Validates CLI discovery over a real docs corpus and command wiring for package-scoped filesystem traversal. | `test/fast/cli/commands/discover_test.rb`, `test/fast/organisms/document_registry_test.rb` |
| TC-002 validate docs | KEEP | Confirms end-to-end validation behavior and output semantics against real files, beyond isolated validator internals. | `test/fast/cli/commands/validate_test.rb`, `test/fast/organisms/validator_test.rb` |
| TC-003 status check | KEEP | Requires real git/worktree-backed freshness computation and CLI summary rendering in one flow. | `test/fast/cli/commands/status_test.rb`, `test/feat/status_command_integration_test.rb` |
| TC-004 update docs metadata | KEEP | Verifies operator-visible metadata update behavior with actual file mutations and command output contract. | `test/fast/cli/commands/update_test.rb`, `test/fast/molecules/frontmatter_manager_test.rb` |
| Candidate: analyze/analyze-consistency semantic matrix in E2E | SKIP | Deterministic command and organism tests already cover core logic; smoke E2E remains focused on canonical docs operations workflow. | `test/fast/cli/commands/analyze_test.rb`, `test/fast/cli/commands/analyze_consistency_test.rb` |
