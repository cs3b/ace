# Implementation evidence — 8ws.t.lq1.0 (2026-09-29)

Worktree: `.ace-wt/8ws-t-lq1-0-preserve-long-cli-sessions` (branch
`8ws-t-lq1-0-preserve-long-cli-sessions`, base e45679c1e). Commits land as one PR.

## SC1 — Reproduce and record the failure boundary

`sc1-diagnosis-2026-09-29.md` (this folder): the reported "~230s timeout" is
disproven by retained evidence — runner completed at ~231s (deadline was 1800s);
the ERROR came from verifier fallback exhaustion (24.7MB prompt; `zai` missing
`ro` preset) 7s after the verifier started. Hypotheses (230s deadline,
idle-stream drop) explicitly recorded as disproven.

## SC2 — Deterministic fixtures (five outcome classes)

- `ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb`: long silent
  success within deadline (stdout with "timeout" stays a success), actual
  deadline expiry with partial stdout/stderr retained, transport disconnect
  (SIGKILL → transport outcome), nonzero exit mentioning "timeout" (exit 3/7,
  classified nonzero-exit), spawn failure (execution not begun).
- `ace-llm-providers-cli/test/fast/models/capture_result_test.rb`: outcome
  invariants, bounded excerpts, evidence round-trip.
- `ace-llm/test/fast/models/execution_evidence_test.rb` +
  `test/fast/atoms/error_classifier_test.rb` + `test/fast/molecules/fallback_orchestrator_test.rb`:
  evidence-first classification (nonzero-exit-mentioning-timeout → EXECUTION_INCOMPLETE),
  chain abort without fallback replay, spawn-failure still falls back.

## SC3 — E2E runner/verifier consumption

`ace-test-runner-e2e`: pipeline failures carry `failure_phase` /
`failure_category` / `execution_evidence`; uncertain sessions marked
`uncertain_execution: true` and excluded from the suite auto-retry (still
counted as errors, listed for explicit reconciliation); verdict completeness
gated (missing selected TCs → ERROR, `incomplete_verdict_set`); pipeline ERROR
stays authoritative over retained metadata (single, package, and suite
reconciles). Tests: `pipeline_report_generator_test.rb`, `failure_finder_test.rb`,
`test_orchestrator_test.rb`, `run_suite_test.rb`.

## SC4 — Focused macOS CLI smoke (former quiet interval)

Run from `/tmp/ace-lq10-smoke`, worktree code, provider `codex:gpt-6-sol`,
`--timeout 600` (bounded; not raised), `--cli-args "skip-git-repo-check
sandbox=read-only"`, fallback ARMED. Fixture: codex runs `sleep 240 && echo
SLEEP-DONE-240` (240s silent interval > former 231s observation) and replies a
line containing the word "timeout".

Result: PASS — run 15:55:41Z→15:59:53Z (252s wall, 240s silent interval > former
231s observation, within the 600s deadline). Exactly one final response:
`SLEEP-COMPLETE timeout-free 240s` (the word "timeout" in successful output).
Zero fallback status lines with fallback armed. exit 0. HOME/USER unchanged; no
global settings or installed gems touched (codex `--sandbox read-only`, cwd
/tmp/ace-lq10-smoke). Notably, an earlier mis-probe (untrusted dir / dropped
`--cli-args`) surfaced as `nonzero_exit … Detail: Reading prompt from stdin…`
with no fallback replay — the new terminal diagnostic working as specified.


## SC5 — Package suites + monorepo suite + independent verdict

- `bin/ace-test ace-llm all` → 398 tests, 0 failures
- `bin/ace-test ace-llm-providers-cli all` → 396 tests, 0 failures
- `bin/ace-test ace-test-runner-e2e all` → 605 tests, 0 failures (3 skipped, pre-existing)
- `bin/ace-test-suite` → 50 packages passed, 10266 tests, 30126 assertions,
  0 failed, 24 skipped → ALL TESTS PASSED
- Independent verdict: `bin/ace-review --task 8ws.t.lq1.0` (result recorded below)

