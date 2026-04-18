# E2E Decision Record - TS-LLM-002 Provider Discovery

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 list-providers-public-surface | KEEP | Validates user-facing provider discovery output and setup hints from the real packaged CLI path, including active/inactive provider presentation. | `test/feat/cli_contract_test.rb`, `test/fast/commands/query_command_test.rb` |
| Candidate: provider config parsing matrix | REMOVE | Deterministic parser/config behavior is already covered by fast/feat tests; no live E2E value. | `test/feat/query_interface_fallback_test.rb` |
