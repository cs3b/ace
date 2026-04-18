---
id: 8reetb
title: 8rd.t.bzp.g ace-overseer public-surface e2e rewrite
type: standard
tags: [ace-overseer, e2e, migration, assignment]
created_at: "2026-04-15 09:52:34"
status: active
---

# 8rd.t.bzp.g ace-overseer public-surface e2e rewrite

## What Went Well
- Reframed `TS-OVERSEER-001` to public-surface oracles while preserving core workflow-value coverage.
- Added `TS-OVERSEER-002` with two missing high-value journeys (`status --watch` refresh behavior and multi-task bundle work-on).
- Caught and fixed E2E filename contract mismatch (`TC-<number>-...`) early using `ace-test-e2e --dry-run`, preventing downstream execution failures.
- Kept delivery quality gates explicit: scoped lint pass, scenario dry-run validation, package test verification, and clean release commits.

## What Could Be Improved
- Task bundle references to `.ace-local/e2e-migration/ace-overseer/{review,plan}.md` and prior assignment report paths were stale/missing; this should be validated before planning starts.
- Release-step guidance in assignment context implied `release-minor`, but actual change class was test/docs-oriented; explicit bump intent should be encoded per task to reduce ambiguity.

## Action Items
- Add a pre-plan guard in E2E migration assignments to verify referenced migration artifacts exist before requiring strict “follow plan” compliance.
- Add a small authoring lint/check for standalone E2E file naming to enforce `TC-<number>-...` patterns when creating new scenarios.
- Consider extending `ace-overseer` usage docs with one short watch-mode example command including bounded execution guidance.
