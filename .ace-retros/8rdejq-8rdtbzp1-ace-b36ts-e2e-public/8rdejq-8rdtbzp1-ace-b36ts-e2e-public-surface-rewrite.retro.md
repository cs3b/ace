---
id: 8rdejq
title: 8rd.t.bzp.1 ace-b36ts e2e public-surface rewrite
type: standard
tags: [assignment, 8rd.t.bzp.1, ace-b36ts]
created_at: "2026-04-14 09:41:56"
status: active
---

# 8rd.t.bzp.1 ace-b36ts e2e public-surface rewrite

## What Went Well
- Rewrote the retained `TS-B36TS-001` contract to align with public-surface goal style and impact-first verification.
- Added missing coverage for decode roundtrip and split/json workflows with concrete runner and verifier prompts.
- Caught and corrected a real CLI flag-compatibility issue (`--split` with `--format`) through targeted `ace-test-e2e` rerun loops.
- Completed package-level `ace-test all --profile 6` verification with clean results before release.

## What Could Be Improved
- Task bundle referenced migration artifacts under `.ace-local/e2e-migration/...` that were missing at execution time, forcing fallback to task spec-only interpretation.
- Pre-commit native `/review` path could not be executed due missing scoped session metadata for the fork root, requiring lint-only fallback.

## Action Items
- Ensure migration-plan source files referenced by task bundles are generated/persisted before batch execution starts.
- Add explicit fork-session metadata creation checks for each scoped subtree to reduce review-path fallback frequency.
- Keep TC command examples synchronized with current CLI mutual-exclusion rules to prevent avoidable first-run failures.
