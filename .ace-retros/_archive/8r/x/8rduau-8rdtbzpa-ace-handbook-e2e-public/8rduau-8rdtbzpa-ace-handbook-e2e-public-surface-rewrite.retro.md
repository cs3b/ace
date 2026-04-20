---
id: 8rduau
title: 8rd.t.bzp.a ace-handbook e2e public-surface rewrite
type: standard
tags: [assignment, 8rd.t.bzp.a, ace-handbook, e2e]
created_at: "2026-04-14 20:12:03"
status: active
---

# 8rd.t.bzp.a ace-handbook e2e public-surface rewrite

## What Went Well
- Delivered the public-surface rewrite goals for `ace-handbook` by preserving `TS-HANDBOOK-001` and adding the missing sync/provider-error scenario `TS-HANDBOOK-002`.
- Tightened retained verifier contracts for table and JSON status checks to prioritize user-visible output and stronger JSON structure expectations.
- Kept task-scoped commit hygiene: implementation, task-state updates, and release updates were committed with scoped `ace-git-commit` paths.
- Verification succeeded at both scenario and package level:
  - `ace-test-e2e ace-handbook TS-HANDBOOK-001` passed (3/3)
  - `ace-test-e2e ace-handbook TS-HANDBOOK-002` passed (2/2)
  - `ace-test-e2e ace-handbook` passed (5/5 cases)
  - `cd ace-handbook && ace-test all --profile 6` passed (22 tests, 0 failures)
- Completed the release-minor step for `ace-handbook` with version bump to `0.27.0`, package changelog update, root changelog update, and lockfile refresh.

## What Could Be Improved
- Referenced migration context files were missing in this workspace (`.ace-local/e2e-migration/ace-handbook/{review,plan}.md`), which forced planning from task spec and existing suite only.
- `ace-task plan 8rd.t.bzp.a` path mode stalled (warnings only, no completion output), requiring fallback to existing plan artifacts.
- New E2E runner goal format initially over-specified extra artifacts; simplifying to the established single-command capture pattern resolved missing-artifact failures.
- Sandbox setup emitted repeated warnings when copying `mise.toml` from `$PROJECT_ROOT_PATH`; tests still passed, but setup assumptions should be hardened.

## Action Items
- [ ] Harden `ace-task plan` path mode timeout/recovery behavior so stalled sessions fail fast with a stable fallback path.
- [ ] Document E2E runner capture constraints (single-command artifact capture pattern) in shared scenario authoring guidance to prevent parser mismatch regressions.
- [ ] Fix `ace-test-e2e` sandbox setup copy step assumptions for package scenarios so missing `mise.toml` warnings are eliminated.
- [ ] Ensure e2e-migration context artifacts referenced by task specs are materialized in active worktrees before assignment execution begins.
