---
id: 8rb1nb
title: 8r9.t.i05.4 ace-demo fast/feat/e2e migration
type: standard
tags: [testing, migration, e2e, ace-demo]
created_at: "2026-04-12 01:05:54"
status: active
---

# 8r9.t.i05.4 ace-demo fast/feat/e2e migration

## What Went Well
- Completed the migration of deterministic `ace-demo` tests into `test/fast` while keeping `test/e2e` scenario assets intact.
- Caught and fixed relocation regressions quickly (`test_helper` require depth and smoke tape path root) with a tight red/green cycle.
- Verified both deterministic and scenario contracts successfully: `ace-test ace-demo`, `ace-test ace-demo all`, and `ace-test-e2e ace-demo` (`TS-DEMO-001` passed 4/4).
- Released package metadata cleanly as `ace-demo v0.24.2` with aligned package and root changelog updates.

## What Could Be Improved
- `ace-task plan 8r9.t.i05.4` stalled in this environment and had to be terminated; fallback manual planning worked but added overhead.
- `pre-commit-review` fallback lint surfaced repeated README em-dash style warnings; style cleanup was deferred because it was non-blocking.
- `release-minor` produced split-scope commits from repo commit policy, which adds bookkeeping overhead when a single coordinated commit is preferred.

## Action Items
- Add a task-work checklist item for test-path migrations: update all `require_relative` helper paths immediately after directory moves.
- Add guidance to switch from `ace-task plan --content` to path-mode plan retrieval after a short timeout in assignment execution.
- Decide whether README typography lint warnings (em-dash) should be auto-fixed during pre-commit fallback or explicitly ignored as accepted style.
