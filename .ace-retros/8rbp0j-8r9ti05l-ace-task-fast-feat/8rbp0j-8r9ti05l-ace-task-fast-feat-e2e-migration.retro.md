---
id: 8rbp0j
title: 8r9.t.i05.l ace-task fast-feat-e2e migration
type: standard
tags: [assignment, task, testing, migration]
created_at: "2026-04-12 16:40:36"
status: active
---

# 8r9.t.i05.l ace-task fast-feat-e2e migration

## What Went Well
- Completed the full subtree lifecycle in one pass (`onboard -> task-load -> plan -> work -> pre-commit-review -> verify -> release -> retro`) without reopening failed steps.
- Deterministic `ace-task` tests migrated cleanly into `test/fast` with pure rename moves and no assertion regressions.
- Final verification was green for both deterministic and E2E surfaces:
  - `ace-test ace-task`
  - `ace-test ace-task all --profile 6`
  - `ace-test-e2e ace-task` (4/4 after setup fix)
- Release closure succeeded with clean workspace and coordinated package/root changelog updates (`ace-task v0.34.0`).

## What Could Be Improved
- `ace-test-e2e ace-task` initially failed because scenario setup used `$PROJECT_ROOT_PATH/mise.toml`, which was absent in the sandbox root on rerun paths.
- TC-004 doctor health check assumed a fresh sandbox and did not clear the prior injected broken fixture, causing a false negative on repeated runs.

## Action Items
- Keep `scenario.yml` setup commands resilient using `${ACE_E2E_SOURCE_ROOT:-$PROJECT_ROOT_PATH}` when copying repo files into sandbox.
- In E2E TCs that inject intentionally broken fixtures, add explicit cleanup/reset steps before baseline/healthy assertions.
- Continue keeping `e2e-decision-record.md` aligned with lane moves (`test/fast`/`test/feat`) whenever deterministic coverage is relocated.
