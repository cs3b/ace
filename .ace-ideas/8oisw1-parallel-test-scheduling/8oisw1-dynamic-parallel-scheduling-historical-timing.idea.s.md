---
title: Dynamic Parallel Test Scheduling based on Historical Timing
filename_suggestion: feat-test-parallel-timing
enhanced_at: 2026-01-19 19:15:36.000000000 +00:00
location: active
llm_model: gflash
source: taskflow:v.0.9.0
id: 8oisw1
status: pending
tags: []
created_at: '2026-01-19 19:15:35'
---

# Dynamic Parallel Test Scheduling based on Historical Timing

## Problem
Test suite execution time in the ACE mono-repo is often dominated by a few large packages (e.g., `ace-git-secrets`, `ace-bundle`, `ace-taskflow`). When running tests in parallel, simple file or package splitting leads to uneven worker loads, resulting in suboptimal wall clock time. The current test execution summary confirms significant duration differences between packages (e.g., 9.07s vs 0.14s).

## Solution
Implement a dynamic test scheduling mechanism within the `ace-test` ecosystem that uses historical execution timing data to balance the workload across parallel workers. This ensures that the total estimated duration assigned to each worker is roughly equal, effectively queuing the 'slowest packages' across the available resources.

## Implementation Approach
1. **Timing Data Collection (ace-test-support)**: Introduce a `TimingRecorder` (Molecule) within `ace-test-support` to capture and persist the execution duration of each test file or package. This data will be stored in a standardized location, likely `.cache/ace-test/timing.json`, adhering to the Prompt Caching Pattern structure for consistency.
2. **Dynamic Scheduler (ace-test)**: Implement a `DynamicScheduler` (Organism) in `ace-test`. This scheduler reads the historical timing data and uses a bin-packing or greedy algorithm to distribute the test workload across the configured number of parallel workers, optimizing for minimum total wall clock time.
3. **Configuration Cascade**: Allow developers and agents to configure the parallel strategy (`duration_based` vs `file_count`) and the number of workers via the standard Configuration Cascade (ADR-022) in `.ace/test/config.yml`.
4. **CLI Integration**: Update the `ace-test run` command to accept a `--workers N` option and use the configured strategy.

## Considerations
- **Cache Reliability**: The timing cache must be robust and handle missing data gracefully (falling back to file count if timing data is unavailable).
- **Agent Integration**: Ensure the `ace-test` CLI output remains deterministic and parseable, allowing agents (like those using `ace-test-e2e-runner`) to automatically leverage the performance gains without complex setup.
- **Configuration Summary**: Use `Ace::Core::Atoms::ConfigSummary.display` to clearly show the active parallel strategy and worker count when `ace-test run` is executed.

## Benefits
- **Reduced Wall Clock Time**: Significantly speeds up the execution of the full mono-repo test suite, improving developer productivity and CI/CD feedback loops.
- **Agent Efficiency**: Provides a performance optimization that agents can utilize automatically, making agentic coding faster and cheaper.
- **Deterministic Performance**: Offers a configurable, measurable way to manage test suite performance.

---

## Original Idea

```
ace-test-suite - we should have option to update how do we run tests by using 70% que on the slowest packages - maybe automatic in .cache, and also suggesting to update the config file for ace-test-suite

═════════════════════════════════════════════════════════════════
  FINAL RESULTS
═════════════════════════════════════════════════════════════════
ace-support-core   ✅ 221 tests, 601 assertions, 0 failures  3.32s
ace-support-config ✅ 211 tests, 405 assertions, 0 failures  4.40s
ace-support-fs     ✅  69 tests, 123 assertions, 0 failures  0.39s
ace-test-runner    ✅ 165 tests, 411 assertions, 0 failures  3.87s
ace-bundle         ✅ 285 tests, 775 assertions, 0 failures  7.31s
ace-support-nav    ✅  72 tests, 220 assertions, 0 failures  3.92s
ace-taskflow       ✅ 1172 tests, 2889 assertions, 0 failures  6.54s
ace-support-timestamp ✅ 109 tests, 268 assertions, 0 failures  0.54s
ace-git-commit     ✅ 155 tests, 289 assertions, 0 failures  2.02s
ace-llm            ✅ 269 tests, 621 assertions, 0 failures  3.30s
ace-llm-providers-cli ✅  96 tests, 249 assertions, 0 failures  3.26s
ace-support-models ✅ 213 tests, 497 assertions, 0 failures  2.93s
ace-search         ✅ 118 tests, 257 assertions, 0 failures  2.53s
ace-docs           ✅ 193 tests, 547 assertions, 0 failures  3.58s
ace-git-worktree   ✅ 297 tests, 659 assertions, 0 failures  6.21s
ace-lint           ✅  36 tests, 137 assertions, 0 failures  0.52s
ace-review         ✅ 390 tests, 1079 assertions, 0 failures  4.72s
ace-git            ✅ 426 tests, 934 assertions, 0 failures  7.22s
ace-git-secrets    ✅ 162 tests, 424 assertions, 0 failures  9.07s
ace-handbook       ✅   1 tests,   3 assertions, 0 failures  0.22s
ace-integration-claude ✅   1 tests,   3 assertions, 0 failures  0.14s
ace-prompt-prep    ✅ 275 tests, 729 assertions, 0 failures  6.99s
ace-support-markdown ✅  43 tests, 269 assertions, 0 failures  2.78s
ace-support-mac-clipboard ✅   5 tests,  14 assertions, 0 failures  0.33s
ace-support-test-helpers ✅  65 tests, 186 assertions, 0 failures  0.45s

═════════════════════════════════════════════════════════════════
⚠️ ALL TESTS PASSED (with 46 skipped)

Packages:  25/25 passed, 0 failed
Tests:     5049 total, 5003 passed, 0 failed, 46 skipped
Assertions: 12589/12589 passed, 0 failed
Duration:  10.55s (wall time)

Packages with skips:
  - ace-bundle: 2 skipped
  - ace-taskflow: 14 skipped
  - ace-llm-providers-cli: 10 skipped
  - ace-search: 14 skipped
  - ace-git-worktree: 5 skipped
  - ace-prompt-prep: 1 skipped
═════════════════════════════════════════════════════════════════
```