# E2E Decision Record - TS-COMP-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface | KEEP | Validates packaged executable wiring and CLI command-surface rendering via real `ace-compressor --help` invocation. | `test/fast/commands/compress_test.rb` |
| TC-002 exact stdio and stats | MODIFY | Retain smoke contract, refresh evidence/verification wording after fast/feat migration and recent compression-runner changes. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/compression_runner_test.rb` |
| TC-003 per-source output directory | KEEP | Verifies multi-input ordering and on-disk output emission in per-source mode using real file writes and path generation. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/compression_runner_test.rb` |
| TC-004 compact refusal contract | MODIFY | Retain refusal contract and refresh post-migration evidence mapping after compact refusal-path updates. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/compact_compressor_test.rb` |
| Candidate: exact-mode parsing details for tables/examples/modality records | SKIP | Detailed record-shape parsing is already covered by command/unit tests and would make smoke E2E redundant. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/exact_compressor_test.rb` |
| Candidate: benchmark table formatting matrix | SKIP | Formatting matrix breadth is better covered in command-level tests; smoke E2E keeps one representative integration flow. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/benchmark_runner_test.rb` |
