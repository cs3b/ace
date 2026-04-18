# E2E Decision Record - TS-NAV-001 Resource Navigation

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help survey and actionable discovery | KEEP (rewritten) | Verifies packaged `ace-nav` help/sources surface and produces actionable command guidance used by later goals. | `test/fast/commands/cli_test.rb`, `test/fast/nav_test.rb` |
| TC-002 public resolve journey | KEEP (narrowed) | Confirms real end-to-end guide/workflow resolution through public CLI usage without relying on extension-priority internals. | `test/fast/atoms/extension_inferrer_test.rb`, `test/fast/molecules/protocol_scanner_test.rb` |
| TC-003 discovery-to-listing workflow | KEEP (rewritten) | Validates user-visible listing utility from public CLI commands as a bridge between discovery and create/resolve actions. | `test/fast/molecules/source_registry_test.rb`, `test/fast/organisms/navigation_engine_test.rb` |
| TC-004 error handling | KEEP | Ensures real CLI error output and failure semantics for missing resources in an end-to-end execution context. | `test/fast/commands/cli_test.rb`, `test/feat/task_protocol_test.rb` |
| TC-006 create-from-template public path | ADD | Covers creation outcome (file creation + usability) that requires full command execution and filesystem verification. | `test/fast/commands/cli_test.rb`, `test/fast/organisms/navigation_engine_test.rb` |
| Candidate: extension-priority internals (`TC-005` former cross-protocol focus) | REMOVE from retained E2E surface | Internal inference/priority detail is deterministic and sufficiently covered in fast/feat tests; retained E2E now targets user-visible outcomes. | `test/fast/atoms/extension_inferrer_test.rb`, `test/fast/molecules/protocol_scanner_test.rb` |
| Candidate: parser validation edge combinations | REMOVE | Parser/normalization branches are deterministic and already covered in fast lane atom/model tests. | `test/fast/atoms/uri_parser_test.rb`, `test/fast/models/resource_uri_test.rb` |
