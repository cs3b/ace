# Analysis and pre-change baseline

Root author worktree: `/Users/mc/Ps/ace/.ace-wt/codex-test-execution-verdict`, base `345bd0cd5` (subsequently fast-forwarded for spec-only clarification). No source changes at baseline.

## Root cause and implementation responsibility

`SequentialTargetExecutor#build_aggregated_result` replaces actual target execution success with parsed assertion counters. Separately, `TestOrchestrator#build_result` drops execution success, and `Models::TestResult#success?` considers only failed/error counts. Fix the execution verdict at these owner boundaries and expose it in terminal/report output without inventing completed failed test cases. Keep raw stderr and existing actual assertion counts. Consumers must use this authoritative combined outcome, not text matching.

Before source changes, add deterministic regression cases proving failed process/timeout with zero parsed failures remains failed through aggregation, final model, saved JSON and real CLI. Pin all modes named in the spec; keep Ctrl-C exit 130 distinct from child execution failure. A successful log containing timeout must remain successful.

## Existing package baseline

`bin/ace-test ace-test-runner all`, receipt `test-runner/8x42mm`: 244 tests, 707 assertions, 3 failures, zero errors, exit 1. All three failures occur before this repair:

- Hermetic suite subprocess fixture launches the package executable without its complete dependency surface: `cannot load such file -- ace/core`.
- Two ProcessMonitor command expectations still expect the executable first; current production intentionally launches `RbConfig.ruby -rbundler/setup EXE` for checkout dependencies.

These must not be attributed to the new verdict propagation. If fixture repair is necessary for package acceptance, preserve the workspace dependency contract and prove actual subprocess behavior rather than weakening isolation or reverting the production launcher.

## Readiness review

First independent Sol review `review-8x42l3`: approve with minor changes; requested deterministic mode coverage and explicit operator interruption artifact behavior. Clarification committed `7a9191782`; second review pending. This record is not task/source acceptance.

## Initial regression checkpoint (not acceptance)

Readiness second round `review-8x42ni` approved as-is, zero findings; root promoted the task and began source repair. Component regressions failed before repair (`8x42pq`: 4 tests, 3 failures and one missing-new-API error), then model/aggregation tests passed (`8x42q4`: 15 tests, 38 assertions). Actual CLI disposable fixture `8x42qo` ran a passing first target followed by a process exiting 9 after a green-looking summary: CLI exit 1, terminal execution diagnostic, saved summary `success: false` with original parsed counts. This is an initial path only; full pinned mode/timeout/SIGINT matrix and final review remain open.
