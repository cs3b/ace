---
id: 8r6x75
title: ace-assign-ace-review-test-optimization
type: standard
tags: [as-test-optimize, ace-assign, ace-review]
created_at: "2026-04-07 22:07:57"
status: active
---

# ace-assign-ace-review-test-optimization

## What Went Well

- Reduced `ace-review` runtime substantially with focused optimizations, then re-verified with `ace-test ace-review`:
  - 994 tests, 2530 assertions, 0 failures, 0 errors, 4 skipped
  - total time: 1.33s
- Reduced `ace-assign` runtime substantially after `assignment_executor` and `skill_assign_source_resolver` cache and fixture injection work:
  - 536 tests, 1738 assertions, 0 failures, 0 errors
  - total time: 2.23s
- Applied low-risk cache boundaries in production paths that are read-heavy and run repeatedly:
  - `ace-assign/lib/ace/assign/organisms/assignment_executor.rb`
  - `ace-assign/lib/ace/assign/molecules/skill_assign_source_resolver.rb`
- Removed test setup overhead and brittle timing from `ace-review` feedback command tests by switching to shared temp dirs and deterministic mtime control in:
  - `ace-review/test/commands/feedback/*_test.rb`
- Added cached prompt/path resolution in:
  - `ace-review/lib/ace/review/molecules/feedback_synthesizer.rb`

## What Could Be Improved

- Add an explicit, automated performance budget check for these package test suites in CI (for example, fail if `ace-review` > 5s or `ace-assign` > 5s) to catch future regressions early.
- Document cache invalidation conditions for new resolver/executor cache keys in a short developer note, so future refactors don't silently bypass invalidation or over-caching.
- Make performance metrics part of release notes for touched gems so reviewers can validate the speedup impact before merge.

## Key Learnings

- Repeated file parsing of YAML, frontmatter, and catalogs is the dominant regression source in command-heavy and assignment-heavy flows.
- Sharing temp directories at test-class scope (`AceReviewTest` shared helper pattern) is low risk and gives large gains when tests repeatedly do small filesystem setup/teardown.
- Caching prompt and catalog resolution at method/class scope lowers command overhead without changing functional behavior, especially when many commands invoke the same paths.

## Action Items

- Continue for next pass:
  - Apply equivalent cache-signature strategy to other file-backed lookup hotspots in `ace-task` and `ace-test-runner`.
  - Add a focused `as-test-verify-performance` check that runs both commands and fails on threshold.
  - Expand fixture-based dependency-injected fast executors to remaining command classes with heavy integration dependencies.
- Stop:
  - Using `sleep`-based test timing control for ordering-sensitive filesystem assertions.
- Start:
  - Capturing before/after timing snapshots for each optimization commit so future retros can quantify gains and validate ROI quickly.
