---
id: 8rdqg1
title: Task 8rd.t.bzp.5 public-surface E2E rewrite
type: standard
tags: [ace-docs, e2e, migration, assignment]
created_at: "2026-04-14 17:37:50"
status: active
---

# Task 8rd.t.bzp.5 public-surface E2E rewrite

## What Went Well
- Converted `ace-docs` E2E coverage to public-surface, goal-style verification without regressing the retained TS-DOCS-001 journeys.
- Added TS-DOCS-002 for analysis workflows and validated both scenarios in real `ace-test-e2e` runs.
- Kept implementation disciplined with package-level tests (`ace-test ace-docs`, `ace-test all --profile 6`) and clean scoped commits.

## What Could Be Improved
- Task reference files under `.ace-local/e2e-migration/ace-docs/` were missing in this checkout, which increased planning ambiguity.
- Initial TS-DOCS-002 verifier logic assumed stricter tool output contracts than current command behavior, causing one rerun cycle.
- Pre-commit-review fallback relied on lint only because no fork session provider metadata and no native `/review` path were available in this execution environment.

## Action Items
- Add a small preflight check in task-load/planning flows to flag missing `.ace-local/e2e-migration/*` references earlier.
- Consider normalizing `ace-docs analyze` / `analyze-consistency` exit+message contracts so no-change and no-doc paths are explicitly structured.
- Preserve the TS-DOCS-002 verifier acceptance paths for success/no-change/empty-scope outcomes until command contracts are tightened.
