---
id: 8x1192
title: forge-neutral-review-lifecycle-recovery
type: standard
tags: [ace-review, forge-neutral, assignment-recovery]
created_at: "2026-10-02 00:50:05"
status: active
---

# Forge-neutral review lifecycle recovery

## What Went Well

- Reused the committed task worktree after two failed workers instead of repeating the migration. The STEP-04 scan showed no live GitHub-only correctness paths.
- Exact-head receipts for implementation, lint and profile-guided package verification kept the tested branch SHA explicit.
- Package tests caught a shared fixture omission before delivery: PR mutation guards require an open state, and both provider test fixtures lacked it. A two-file fix restored 80 GitHub and 93 Forgejo tests.
- Local release preparation updated four package versions, package changelogs, the root changelog and the worktree lockfile in one commit.

## What Could Be Improved

- The first worker watched its own fork launcher; the second hit a 1,800-second fork deadline mid-implementation. Recovery needed two rounds and left old uncertain attempts in the ledger.
- `BUNDLE_GEMFILE` pointed to the shared checkout inside the task worktree. The first `bundle install` reported success without updating the worktree lockfile. An explicit worktree Gemfile path was required.
- The `ace-review` campaign feature test took 235 seconds in the profile run, making repeated full package verification costly. Its subprocess-heavy path deserves performance analysis.
- The fallback pre-commit gate checked Markdown/YAML only. The later independent exact-head review remains the meaningful code review gate.

## Key Learnings

- In a scoped fork, the fork-run wrapper in the process list is the current worker's launcher. Assignment status and reports, not wrapper observation, determine progress.
- Keep assignment step transitions in the shared assignment root while running code, tests, commits and candidate-head attempt receipts in the task worktree. Set `CACHE_BASE` to the shared assignment store for those receipts.
- Check the lockfile versions after `bundle install` when shell environment pins `BUNDLE_GEMFILE` elsewhere.

## Action Items

- Measure and shorten `test_public_json_dry_run_restart_replay_head_drift` without weakening its integration assertions.
- Make worktree release preparation detect a `BUNDLE_GEMFILE` path outside the current worktree and fail before claiming success.
- Document fork launcher self-observation and task worktree receipt handling in assignment recovery guidance.
