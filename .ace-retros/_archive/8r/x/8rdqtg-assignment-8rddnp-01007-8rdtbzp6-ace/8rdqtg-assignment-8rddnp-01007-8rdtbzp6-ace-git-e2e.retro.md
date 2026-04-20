---
id: 8rdqtg
title: "Assignment 8rddnp@010.07 - 8rd.t.bzp.6 ace-git E2E rewrite"
type: standard
tags: [assignment, ace-git, e2e, migration]
created_at: "2026-04-14 17:52:44"
status: active
---

# Assignment 8rddnp@010.07 - 8rd.t.bzp.6 ace-git E2E rewrite

## What Went Well
- Delivered the scoped assignment end-to-end in one drive loop (`onboard -> task-load -> plan -> work -> review -> verify -> release -> retro`) without scheduler stalls.
- Reworked `TS-GIT-001` to scenario-owned setup and removed runner-level fallback/bootstrap behavior while preserving retained TC-005/TC-006 contracts.
- Added `TS-GIT-002-public-surface-smoke` to validate `ace-git --help` and range-routing behavior from documented CLI paths.
- Verified results with targeted E2E reruns (`TS-GIT-001`, `TS-GIT-002`) and package verification (`ace-test all --profile 6` in `ace-git`), all passing after fix iteration.
- Completed scoped release updates for `ace-git v0.22.0` with package/root changelog and lockfile updates committed cleanly.

## What Could Be Improved
- Task bundle freshness references (`.ace-local/e2e-migration/ace-git/{review,plan}.md`) were missing; planning had to proceed from task spec + live files, which reduced traceability.
- Initial `TS-GIT-002` setup used only one commit, causing `HEAD~1..HEAD` to fail; setup assumptions around git revision depth should be validated earlier.
- Fallback pre-commit review produced lint warnings after the main implementation commit, requiring a follow-up style commit that could have been folded into the first pass.

## Action Items
- Add a pre-plan guard in assignment/task-load flows to explicitly surface missing referenced bundle artifacts and suggest regeneration paths.
- Add a reusable E2E fixture check for range-based git tests to guarantee required commit depth before runner execution.
- Include `ace-lint` on touched markdown/yaml scenario files before the first implementation commit for E2E rewrite tasks.
