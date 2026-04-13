---
id: 8q7hko
title: 0m6-unify-ace-assign-batch-fanout
type: standard
tags: []
created_at: "2026-03-08 11:42:58"
status: active
task_ref: 8q5.t.0m6
---

# 0m6-unify-ace-assign-batch-fanout

## What Went Well

- **Batch fork-run worked reliably**: 4 subtask fork-runs completed (010.01-010.04), with 3 succeeding on first attempt and 1 recovering after timeout. The fork isolation model proved effective for parallelizable work.
- **Already-done task handled gracefully**: Task 0m6.0 was already complete — the fork correctly detected this, confirmed tests (458 passing), and skipped release without producing spurious changes.
- **Test suite stayed green throughout**: Every fork verified package tests (459 tests) and the full monorepo suite (7436 tests, 32 packages) passed with zero failures at the verify-test-suite phase.
- **Commit reorganization was clean**: 14 incremental commits compressed into 4 logical groups using `ace-git-commit` scope detection — no manual file grouping needed.
- **Per-subtask releases prevented merge conflicts**: Each subtask released independently (v0.23.0, v0.24.0, v0.25.0), keeping changelogs clean and version bumps atomic.

## What Could Be Improved

- **Fork timeout on 010.03 (task 0m6.2)**: The fork timed out during work-on-task because it paused waiting for user input about unstaged changes from prior fork runs. Forks should not prompt interactively — they should either commit or continue autonomously.
- **Failed plan-task blocked subtree completion**: Provider failure on 010.01.03 (plan-task) left the subtree in 6/7 done state, preventing container auto-completion. Required manual phase file edit (`status: failed` → `status: done`) to unblock. The retry mechanism created a top-level phase (013) instead of a child, which was unhelpful.
- **Review provider unavailability**: Fit review (070) failed entirely due to provider issues (Broken pipe, empty reports). The circuit breaker pattern worked conceptually but required manual skip of the shine cycle.
- **Spurious retry phase**: `ace-assign retry 010.01.03` created a top-level phase 013 instead of a child of 010.01. This is likely a bug in retry scoping for nested phases.

## Key Learnings

- **Fork crash recovery needs better tooling**: When a fork times out mid-phase, the driver must manually commit partial work, write a report, and re-fork. A `fork-recover` command that automates commit + report + re-fork would save significant driver time.
- **Container auto-completion should tolerate non-critical failures**: A plan-task failure shouldn't block container completion when all subsequent phases (including work-on-task) succeeded. Consider a "soft failure" status that doesn't block parent completion.
- **Provider failures are the dominant fork failure mode**: None of the 4 subtask forks failed due to code bugs — all failures were provider-related (timeouts, broken pipes, empty responses). The recovery protocol should be streamlined for this common case.

## Action Items

- **Continue**: Per-subtask release pattern for batch assignments — keeps changes atomic and reduces merge risk
- **Continue**: Fork-run for subtask isolation — context separation works well for independent task implementations
- **Start**: Investigate `ace-assign retry` scoping for nested phases — retry should create a child phase, not a top-level sibling
- **Start**: Consider a `--tolerate-failures` flag on container completion that allows marking non-critical failed children as skipped
- **Stop**: Manually editing phase files to change status — this should be handled by a proper CLI command

