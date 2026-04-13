# E2E Decision Record - TS-RUNNER-001 CLI Smoke

| TC ID | Decision | E2E-only reason | Unit tests reviewed |
| --- | --- | --- | --- |
| TC-001 `ace-test-e2e --help` command surface | ADD | Verifies packaged executable routing and operator-visible help output via real binary invocation, not class-level command invocation. | `test/fast/commands/cli_test.rb` |
| TC-002 invalid package dry-run error path | ADD | Validates end-user error semantics (message + non-zero exit) at CLI boundary for package discovery failures. | `test/fast/commands/run_test_test.rb`, `test/fast/molecules/test_discoverer_test.rb` |
| TC-003 `ace-test-e2e ace-demo --dry-run` scenario discovery | ADD | Requires real filesystem discovery over monorepo scenario files plus CLI formatting of scenario preview output. | `test/fast/molecules/test_discoverer_test.rb`, `test/fast/molecules/scenario_loader_test.rb` |
| TC-004 `ace-test-e2e-suite --help` command surface | ADD | Confirms suite executable entrypoint wiring and user-facing description through real binary execution. | `test/fast/commands/suite_executable_test.rb`, `test/fast/commands/run_suite_test.rb` |
| Candidate: full provider-backed scenario execution (`ace-test-e2e` without `--dry-run`) | SKIP | Full LLM provider execution is high-cost/infrastructure-dependent and not required for initial smoke coverage; this task targets deterministic CLI/filesystem surfaces first. | `test/fast/organisms/test_orchestrator_test.rb`, `test/fast/molecules/test_executor_test.rb` |
| Candidate: exhaustive tag/include/exclude matrix across all flags | SKIP | Detailed filter matrix is already unit-covered and would create low-value E2E duplication for smoke tier. | `test/fast/commands/run_test_test.rb`, `test/fast/commands/run_suite_test.rb` |
