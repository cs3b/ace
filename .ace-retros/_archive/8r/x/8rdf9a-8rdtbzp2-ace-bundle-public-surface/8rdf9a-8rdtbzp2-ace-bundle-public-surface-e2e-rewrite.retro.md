---
id: 8rdf9a
title: 8rd.t.bzp.2 ace-bundle public-surface e2e rewrite
type: standard
tags: [8rd.t.bzp.2, ace-bundle, e2e]
created_at: "2026-04-14 10:10:19"
status: active
---

# 8rd.t.bzp.2 ace-bundle public-surface e2e rewrite

## What Went Well
- Consolidated overlapping E2E coverage by folding former TC-003 file-pattern checks into Goal 2 without losing observable assertions.
- Reframed Goal 4 and Goal 5 around public CLI behavior, reducing coupling to internal threshold/API terminology while keeping meaningful regression coverage.
- Verification stayed green after rewrite and release:
  - `ace-test-e2e ace-bundle` passed (`TS-BUNDLE-001`, 4/4 cases).
  - `ace-test ace-bundle` and `cd ace-bundle && ace-test all --profile 6` passed.
- Release handoff was completed in the same subtree with clean package + root changelog updates and version bump to `ace-bundle v0.43.0`.

## What Could Be Improved
- Task bundle declared `.ace-local/e2e-migration/ace-bundle/review.md` and `plan.md` but those files were missing in the workspace; planning had to proceed from task spec + current suite state.
- Pre-commit review fallback produced many style warnings (em dash and spacing); run markdown cleanup earlier in the edit loop to reduce non-functional noise before release.

## Action Items
- Ensure migration review/plan artifacts are materialized in-repo (or bundled reliably) before planning subtasks start.
- Add a lightweight markdown-style normalization pass to E2E scenario/rule files before pre-commit review.
- Keep future E2E rewrites anchored to docs/help discoverability and user-visible outputs first, with helper artifacts only as secondary evidence.
