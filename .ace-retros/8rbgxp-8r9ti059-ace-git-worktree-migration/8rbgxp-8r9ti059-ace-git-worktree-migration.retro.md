---
id: 8rbgxp
title: 8r9.t.i05.9 ace-git-worktree migration
type: standard
tags: [testing, migration, fast, feat, e2e]
created_at: "2026-04-12 11:17:28"
status: active
---

# 8r9.t.i05.9 ace-git-worktree migration

## What Went Well
- Completed the full migration surface for `ace-git-worktree` from legacy deterministic layout to `test/fast` + `test/feat`, with retained workflow scenarios under `test/e2e`.
- Caught and fixed post-move path regressions quickly (`test_helper` depth, direct `lib` requires, CLI executable path in command tests).
- Updated scenario metadata and verifier expectations to match current runtime behavior while preserving meaningful E2E assertions.
- Verification completed with green package checks:
  - `ace-test ace-git-worktree`
  - `ace-test ace-git-worktree feat`
  - `ace-test ace-git-worktree all --profile 6`
  - `ace-test-e2e ace-git-worktree` (final pass report: `.ace-local/test-e2e/8rbgq2v-final-report.md`)
- Release and follower alignment completed in the same subtree:
  - `ace-git-worktree` -> `0.20.0`
  - `ace-overseer` -> `0.13.12` (dependency line update to `~> 0.20`)

## What Could Be Improved
- First-pass E2E runs were noisy and inconsistent before converging; runner/verifier variability slowed down closeout confidence.
- Test-file relocation introduced multiple depth-sensitive path assumptions; these would be safer to detect up front with a focused migration preflight.
- Release workflow expectation of one coordinated commit conflicted with multi-scope `ace-git-commit` behavior, which produced three commits.

## Action Items
- Add a migration preflight check for moved test files:
  - validate `require_relative` depth to `test_helper`
  - validate any direct `lib` path requires
  - validate CLI executable path assumptions in command tests
- Add deterministic checks around E2E artifact contract stability (required files per TC) before concluding behavior-level failures.
- Document multi-scope `ace-git-commit` split behavior in release guidance so release-step expectations match tool output.
