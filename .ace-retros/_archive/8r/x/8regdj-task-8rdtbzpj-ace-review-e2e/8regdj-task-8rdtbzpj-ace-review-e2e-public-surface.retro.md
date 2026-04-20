---
id: 8regdj
title: Task 8rd.t.bzp.j - ace-review e2e public-surface migration
type: standard
tags: [8rd.t.bzp.j, ace-review, e2e, migration]
created_at: "2026-04-15 10:55:03"
status: active
---

# Task 8rd.t.bzp.j - ace-review e2e public-surface migration

## What Went Well
- Rewrote retained `TS-REVIEW-001` goals toward public-surface execution paths and added explicit docs-path onboarding
  coverage (`TC-003`) without expanding scenario sprawl.
- Tightened verifier contracts to remove PASS-equivalent provider-blocker behavior, aligning suite outcomes with task
  success criteria.
- Verification stayed fast and deterministic for package checks (`ace-test all --profile 6` in `ace-review`: 994
  tests, 0 failures), enabling confident release progression.
- Release updates completed cleanly with scoped commits: `ace-review` bumped to `v0.53.0` plus coordinated root
  changelog/lockfile updates.

## What Could Be Improved
- Task bundle referenced migration artifacts (`.ace-local/e2e-migration/ace-review/{plan,review}.md`) that were missing
  locally, which increased planning uncertainty and required stale-gap handling.
- `ace-task plan <ref>` stalled in path mode during execution; fallback to in-session plan/report worked, but this
  should be hardened to avoid repeated manual recovery.
- Release workflow text references post-publish propagation proof; this subtree release phase does not execute publish,
  so classification had to be marked pending.

## Action Items
- Add or regenerate missing migration context files during assignment creation so plan/work steps can consume canonical
  package migration inputs directly.
- Investigate and fix intermittent `ace-task plan` stall behavior (path mode) for assignment-driven execution.
- Clarify release workflow contract boundaries between local version/changelog release steps and post-publish
  propagation checks.
