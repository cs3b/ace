# E2E Decision Record - TS-RUNNER-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 `ace-test-e2e --help` command surface | KEEP | Verifies packaged executable routing and operator-visible help output via real binary invocation. | `test/fast/commands/cli_test.rb` |
| TC-002 invalid package dry-run error path | KEEP | Validates end-user error semantics (message + non-zero exit) at CLI boundary for package discovery failures. | `test/fast/commands/run_test_test.rb`, `test/fast/molecules/test_discoverer_test.rb` |
| TC-003 `ace-test-e2e ace-demo --dry-run` scenario discovery | REWRITE | Keeps discovery-preview value but now uses scenario-local public fixtures (`copy-fixtures`) rather than hidden source-root copy recipes. | `test/fast/molecules/test_discoverer_test.rb`, `test/fast/molecules/scenario_loader_test.rb` |
| TC-004 suite command surface + control-flow (`--only-failures`) | EXPAND | Keeps help-surface contract and adds practical suite control-flow completion evidence. | `test/fast/commands/suite_executable_test.rb`, `test/fast/commands/run_suite_test.rb` |
| Real run + verifier + shell helper public coverage | MOVED | Dedicated in `TS-RUNNER-002-real-exec` to isolate higher-cost, outcome-first validation from smoke-only checks. | `test/fast/molecules/test_executor_test.rb`, `test/fast/molecules/pipeline_report_generator_test.rb`, `test/fast/molecules/report_writer_test.rb` |
