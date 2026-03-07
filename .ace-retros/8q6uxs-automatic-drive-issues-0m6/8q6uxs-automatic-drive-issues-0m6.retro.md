---
id: 8q6uxs
title: automatic-drive-issues-0m6
type: standard
tags: [ace-assign, drive, automation, provider-resilience]
created_at: "2026-03-07 20:37:33"
status: active
task_ref: 8q5.t.0m6.0
---

# Automatic Drive Issues — Assignment 8q6tiz (task 0m6.0)

## Context

Full automatic drive of a 14-phase assignment (with 3 fork subtrees for review cycles) using `/as-assign-drive`. The assignment covered: onboard, work-on-task (7 child phases via fork), mark-done, verify-test-suite, verify-e2e, release, update-docs, create-pr, and 3 review cycles (valid/fit/shine, each with 3 child phases via fork).

## What Went Well

- **Fork subtree delegation works**: Phases 020 (work-on-task, 7 children) and 090/100 (review-valid/fit, 3 children each) all completed successfully via `fork-run`.
- **Queue advancement is reliable**: Auto-completion of container phases and manual `ace-assign start` for queue gaps both worked correctly.
- **Test suite integration**: Full monorepo test suite (7421 tests) passed cleanly; no cross-package regressions.
- **Review cycles produced real value**: The fit review (100) found 2 medium findings (path formatting, regression coverage) that were applied and released.
- **Release automation**: Three version bumps (0.22.0, 0.22.1, 0.22.2) with changelogs handled correctly by fork agents.

## What Could Be Improved

### Issue 1: Fork crash on provider unavailability loops endlessly before failing

**Observed**: Review-shine fork (110) crashed with exit 144 after trying claude (inactive), codex (broken pipe), and gemini (hung >90s + kill -9). The fork agent tried multiple providers, each failing differently, consuming ~8 minutes before giving up.

**Impact**: Time wasted; the fork injected a retry phase (101) at the wrong level (top-level sibling instead of inside subtree 110), creating an orphaned phase that the driver then had to execute inline.

**Root cause**: No fast-fail on known-inactive providers. Fork agents re-discover provider failures instead of inheriting the driver's knowledge.

### Issue 2: Failed fork injects retry phase at wrong scope

**Observed**: When 110.01 failed, the fork agent injected phase 101 as a top-level sibling. This breaks the subtree model — 101 has no parent relationship to 110 and its instructions reference shine-cycle goals without proper context.

**Impact**: Driver picks up 101 as an orphaned inline phase. The subtree 110 remains in a mixed state (2 failed, 1 done). The assignment queue has structural confusion.

**Desired**: Retry phases should be injected as children of the failed subtree, not as top-level siblings. Or the fork should report failure and let the driver decide recovery strategy.

### Issue 3: Release phase runs even when review/apply failed

**Observed**: In subtree 110, phases 110.01 (review) and 110.02 (apply-feedback) both failed, but 110.03 (release) ran and bumped to v0.22.3. This release captures no actual changes — it's a version bump for a review cycle that produced nothing.

**Impact**: Empty version bump pollutes git history and version space. v0.22.3 has no semantic difference from v0.22.2.

**Desired**: Release phases should be conditional on prior phases producing actual changes. If review found nothing and apply was a no-op, release should skip or auto-complete without bumping.

### Issue 4: E2E tests fail on provider configuration, not code

**Observed**: Both ace-assign E2E scenarios (TS-ASSIGN-001, TS-ASSIGN-002) errored because `claude` provider is not in `llm.providers.active`. Zero assertions ran.

**Impact**: E2E verification phase provides no signal about code quality. The phase completes with a "config issue" report but doesn't actually test anything.

**Desired**: E2E tests should either use available providers or clearly document required provider configuration. The verify-e2e phase should distinguish "tests ran and passed" from "tests couldn't run due to infra".

### Issue 5: Duplicate onboard phase in assignment template

**Observed**: Phase 010 (onboard) runs at the driver level, then phase 020.01 (onboard-base) runs again inside the fork subtree. Both load project context via `ace-bundle project`.

**Impact**: ~30s of redundant work. The fork agent's onboard is useful for context isolation, but the driver's top-level onboard is wasted if the driver immediately delegates to a fork.

### Issue 6: Plan mode activation during active execution

**Observed**: Plan mode activated mid-edit during phase 101 execution (applying shine review findings inline). The edit to `create.rb` was written but then plan mode blocked further progress.

**Impact**: Execution stalled; user had to interrupt. The edit was partially applied but not committed.

**Root cause**: Unclear what triggered plan mode — possibly a UI interaction or keybinding. The drive workflow should be resilient to mode switches.

### Issue 7: Feedback synthesis fails across multiple providers

**Observed**: `ace-review-feedback create` failed with codex (`--sandbox` argument error), then claude (inactive). The review report existed but couldn't be synthesized into actionable feedback items.

**Impact**: Driver had to manually read the raw review report and apply findings inline instead of using the structured feedback pipeline. This worked but bypasses the verification/archival workflow.

## Key Learnings

1. **Provider resilience is the #1 bottleneck for automatic drive**. Every fork failure in this session was provider-related, not code-related. The system needs provider health checks before fork launch.

2. **Fork recovery strategy matters more than fork success**. The happy path works well. The recovery path (inject retry, re-fork, inline fallback) has structural bugs that create orphaned phases and empty releases.

3. **Sequential review cycles amplify provider failures**. Three back-to-back review forks (valid → fit → shine) mean a transient provider issue hits all three. Consider parallel review forks or circuit-breaker patterns.

4. **The driver-as-guard pattern works** when reports are available. Reading fork reports before advancing caught the empty shine cycle. But the guard can't prevent structural damage already done by the fork (wrong-scope retry injection).

## Action Items

### Stop

- Stop releasing when review/apply phases produced no changes
- Stop injecting retry phases as top-level siblings from fork agents

### Continue

- Continue the driver-as-guard pattern (reading all fork reports before advancing)
- Continue running full test suite at verify-test-suite phase

### Start

- Start adding provider health checks before fork-run launch
- Start making release phases conditional on actual code changes in the subtree
- Start constraining fork retry injection to within the fork's own subtree scope
- Start distinguishing "E2E infra failure" from "E2E test failure" in verify-e2e phase reporting
- Start considering a circuit-breaker for sequential review fork failures (if valid fails on providers, skip fit/shine rather than repeating the same failure)
