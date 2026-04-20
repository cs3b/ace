---
id: 8regti
title: "Retro 8rd.t.bzp.k: ace-search public-surface E2E rewrite"
type: standard
tags: [assignment, ace-search, e2e]
created_at: "2026-04-15 11:12:47"
status: done
---

# Retro 8rd.t.bzp.k: ace-search public-surface E2E rewrite

## What Went Well
- Converted `TS-SEARCH-001` to six public-surface goals and removed implementation-coupled probes from file/count/json journeys.
- Added preset-driven and git-scoped scenarios while keeping the existing suite structure and runner/verifier contracts coherent.
- Verified quality gates end-to-end: `ace-lint` cleanup, `ace-test-e2e ace-search` pass (6/6), and `cd ace-search && ace-test all --profile 6` pass.
- Completed assignment lifecycle with scoped commits, task status updates, package release bump (`ace-search` `0.26.0`), and changelog updates.

## What Could Be Improved
- Task bundle references for `.ace-local/e2e-migration/ace-search/{review,plan}.md` and prior report paths were missing in this checkout, which forced inference from task spec plus current files.
- A path assumption regression (`test/e2e/...` inside sandbox) caused an intermediate E2E failure and required a follow-up fix to use workspace-root scope (`.`).
- Pre-commit fallback lint surfaced many markdown-style issues after initial implementation; applying lint-aware formatting earlier would reduce churn.

## Action Items
- Add/retain migration-plan artifacts in assignment bundles (or provide explicit fallback guidance) so planning is not stale-by-gap.
- Add a scenario-level preflight check for search-root path existence to fail fast with clearer diagnostics before mode-specific commands run.
- Incorporate markdown lint checks before first implementation commit in E2E rewrite tasks to avoid avoidable post-commit cleanup.
