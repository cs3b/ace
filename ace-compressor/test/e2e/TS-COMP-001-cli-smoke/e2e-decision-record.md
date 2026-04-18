# E2E Decision Record - TS-COMP-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 help surface | KEEP | Validates packaged executable wiring and CLI command-surface rendering via real `ace-compressor --help` invocation. | `test/fast/commands/compress_test.rb` |
| TC-002 exact stdio and stats | MODIFY | Retain smoke contract while limiting checks to integration-visible output semantics (mode/header, output path, source count). | `test/fast/commands/compress_test.rb`, `test/fast/organisms/compression_runner_test.rb` |
| TC-003 per-source output directory | KEEP | Verifies multi-input ordering and on-disk output emission in per-source mode using real file writes and path generation. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/compression_runner_test.rb` |
| TC-004 compact refusal contract | MODIFY | Keep refusal/guidance assertions but remove brittle verbatim fixture recipe dependency in favor of behavior-driven rule-heavy input shape. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/compact_compressor_test.rb` |
| TC-005 agent mode smoke | ADD | Covers documented `--mode agent` user workflow through packaged CLI and output contract. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/agent_compressor_test.rb` |
| TC-006 benchmark smoke | ADD | Covers documented `benchmark` workflow across exact/compact/agent modes with real CLI invocation. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/benchmark_runner_test.rb` |
| Candidate: exact-mode parsing details for tables/examples/modality records | SKIP | Detailed record-shape parsing is already covered by command/unit tests and would make smoke E2E redundant. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/exact_compressor_test.rb` |
| Candidate: benchmark formatting matrix breadth | SKIP | Full matrix formatting permutations belong in command-level tests; E2E keeps one representative benchmark invocation. | `test/fast/commands/compress_test.rb`, `test/fast/organisms/benchmark_runner_test.rb` |
