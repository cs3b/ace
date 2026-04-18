---
id: 8rdxgi
title: "Retrospective: 8rd.t.bzp.c ace-lint public-surface E2E rewrite"
type: standard
tags: [8rd.t.bzp.c, ace-lint, e2e, assignment]
created_at: "2026-04-14 22:18:21"
status: active
---

# Retrospective: 8rd.t.bzp.c ace-lint public-surface E2E rewrite

## What Went Well
- Delivered the `TS-LINT-001` migration to public-surface goals with explicit docs/help mapping and impact-first verifier checks.
- Split overloaded coverage into clearer contracts (`TC-005-batch-integrated-outcomes` plus new `TC-008-no-report-public-contract`), which reduced ambiguity in expected artifacts.
- Kept assignment momentum through all required stages (`work-on-task`, pre-commit fallback review, package-scoped test verification, release bump, retro).
- Verification remained green (`ace-test all --profile 6` in `ace-lint`) after scenario and docs changes.

## What Could Be Improved
- `ace-task plan 8rd.t.bzp.c` produced missing-context warnings and then stalled without usable output; fallback manual planning was necessary.
- Referenced context files under `.ace-local/e2e-migration/ace-lint/` were absent, increasing planning uncertainty and forcing direct spec/file inspection.
- Release workflow instructions expect broad auto-detection patterns that can over-select packages on long-lived branches; explicit package targeting was required to avoid accidental multi-package release churn.

## Action Items
- Add a follow-up tooling fix to harden `ace-task plan` against missing optional context files and stalled execution, with deterministic fallback path logging.
- Add a guard in task generation or task-load to validate referenced local context files exist before planning starts (or auto-mark them as optional with warnings).
- Consider adding a scoped-release helper for assignment subtrees so `release-minor` can explicitly target modified packages without relying on branch-wide diff heuristics.
