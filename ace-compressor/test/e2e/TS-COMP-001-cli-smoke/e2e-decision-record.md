# E2E Decision Record - TS-COMP-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface | ADD | Validates packaged executable wiring and CLI command-surface rendering via real `ace-compressor --help` invocation. | `test/commands/compress_test.rb` |
| TC-002 exact stdio and stats | ADD | Confirms operator-visible output contracts across two formats and real cache/output-path side effects from full CLI execution. | `test/commands/compress_test.rb`, `test/organisms/compression_runner_test.rb` |
| TC-003 per-source output directory | ADD | Verifies multi-input ordering and on-disk output emission in per-source mode using real file writes and path generation. | `test/commands/compress_test.rb`, `test/organisms/compression_runner_test.rb` |
| TC-004 compact refusal contract | ADD | Confirms end-user refusal behavior (`exit 1`, refusal/guidance records, stderr message) for rule-heavy input through the binary interface. | `test/commands/compress_test.rb`, `test/organisms/compact_compressor_test.rb` |
| Candidate: exact-mode parsing details for tables/examples/modality records | SKIP | Detailed record-shape parsing is already covered by command/unit tests and would make smoke E2E redundant. | `test/commands/compress_test.rb`, `test/organisms/exact_compressor_test.rb` |
| Candidate: benchmark table formatting matrix | SKIP | Formatting matrix breadth is better covered in command-level tests; smoke E2E keeps one representative integration flow. | `test/commands/compress_test.rb`, `test/organisms/benchmark_runner_test.rb` |
