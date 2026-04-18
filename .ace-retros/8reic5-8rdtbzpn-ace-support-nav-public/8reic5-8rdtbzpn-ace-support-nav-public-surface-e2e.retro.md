---
id: 8reic5
title: "8rd.t.bzp.n: ace-support-nav public-surface E2E rewrite"
type: standard
tags: [ace-support-nav, e2e, migration]
created_at: "2026-04-15 12:13:31"
status: active
---

# 8rd.t.bzp.n: ace-support-nav public-surface E2E rewrite

## What Went Well
- Re-scoped `TS-NAV-001` from extension-priority internals to user-visible goals (discover, resolve, list, create, error) without breaking package-level test health.
- Added new create-flow coverage (`TC-006`) and aligned README journey examples so docs and E2E now validate the same public path.
- Verification discipline caught an early brittle verifier issue and resolved it quickly with a semantic check update.
- All targeted validation passed after the fix: `ace-test-e2e ace-support-nav` and `cd ace-support-nav && ace-test all --profile 6`.

## What Could Be Improved
- Task metadata referenced migration files under `.ace-local/e2e-migration/...` that were missing in this checkout, forcing planning from partial context.
- Pre-commit-review fallback produced many non-blocking warnings; warning budgets or tighter markdown lint defaults would reduce noise.
- Provider/session metadata for subtree `010.24` was not present, so review routing had to fall back to generic defaults.

## Action Items
- Add a preflight check in task-load flow to validate referenced context files exist before planning starts.
- Consider replacing line-count-based verifier heuristics with semantic assertions by default in goal-style suites.
- Add explicit assignment session metadata for all forked subtree roots to improve deterministic review-mode selection.
