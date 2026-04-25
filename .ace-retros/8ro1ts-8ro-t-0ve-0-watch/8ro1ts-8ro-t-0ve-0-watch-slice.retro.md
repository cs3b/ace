---
id: 8ro1ts
title: 8ro-t-0ve-0-watch-slice
type: standard
tags: [ace-assign, watch, assignment]
created_at: "2026-04-25 01:13:06"
status: active
---

# 8ro-t-0ve-0-watch-slice

## What Went Well
- The scoped watcher command surface, scope parsing, and direct fast tests were already in place on the branch, so task verification could focus on whether the shipped slice actually held up under package-level validation.
- The subtree flow still surfaced a real regression instead of rubber-stamping the earlier commit: package verification caught a teardown bug in `ace-assign/test/test_helper.rb` that did not show up in the narrower watcher-only tests.
- Re-running the direct watcher tests plus the full `ace-assign` package suite provided strong evidence that the slice is stable after the guard fix.

## What Could Be Improved
- Assignment child steps advanced underneath the driver multiple times, which caused reports to land on the wrong step numbers and made the subtree harder to audit.
- The initial work step report was used as a planning artifact because the subtree state changed between status checks; that is a process bug even though the underlying code was already shipped.
- The pre-commit review fallback only linted files and did not preserve a cleaner distinction between review evidence and later verification evidence.

## Key Learnings
- In forked assignment subtrees, the driver has to re-check status immediately before every `finish` call; otherwise queued child steps can auto-advance and consume the wrong report.
- Package-wide verification remains necessary even when the task-specific test surface passes. The watcher slice looked complete in direct tests, but `ace-test all --profile 6` exposed a regression in shared test infrastructure.
- Guarding teardown/setup assumptions in shared test helpers is low-cost and prevents broad false-negative package failures.

## Action Items
- Tighten `as-assign-drive` usage discipline so scoped drivers re-read active child state immediately before writing reports in long-running subtrees.
- Keep package-level verification in the subtree even when a task appears isolated to one command/test area.
- Preserve the `(@original_env || {})` guard in `ace-assign/test/test_helper.rb` and treat shared test helper edits as full-package verification triggers.
