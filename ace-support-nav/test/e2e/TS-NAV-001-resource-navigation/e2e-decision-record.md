# E2E Decision Record - TS-NAV-001 Resource Navigation

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help survey | KEEP | Verifies packaged `ace-nav` help/sources behavior through real command invocation and output artifacts. | `test/fast/commands/cli_test.rb`, `test/fast/nav_test.rb` |
| TC-002 extension inference | KEEP | Confirms end-to-end protocol resolution behavior over real fixture files and CLI invocation flow. | `test/fast/atoms/extension_inferrer_test.rb`, `test/fast/molecules/protocol_scanner_test.rb` |
| TC-003 priority and exact match | KEEP | Validates precedence behavior with actual configured sources and resource files across full navigation pipeline. | `test/fast/molecules/source_registry_test.rb`, `test/fast/organisms/navigation_engine_test.rb` |
| TC-004 error handling | KEEP | Ensures real CLI error output and failure semantics for missing resources in an end-to-end execution context. | `test/fast/commands/cli_test.rb`, `test/feat/task_protocol_test.rb` |
| TC-005 cross protocol inference | KEEP | Covers cross-protocol resolution (`wfi://` and `guide://`) requiring real fixture discovery and CLI wiring. | `test/fast/molecules/protocol_scanner_test.rb`, `test/fast/organisms/navigation_engine_test.rb` |
| Candidate: parser validation edge combinations | REMOVE | Parser/normalization branches are deterministic and already covered in fast lane atom/model tests. | `test/fast/atoms/uri_parser_test.rb`, `test/fast/models/resource_uri_test.rb` |
