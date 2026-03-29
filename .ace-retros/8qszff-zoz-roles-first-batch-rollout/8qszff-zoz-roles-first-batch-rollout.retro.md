---
id: 8qszff
title: zoz-roles-first-batch-rollout
type: standard
tags: [8qr.t.zoz, roles, batch, process]
created_at: "2026-03-29 23:37:08"
status: active
---

# zoz-roles-first-batch-rollout

## What Went Well

- **Two-phase task decomposition worked cleanly**: zoz.0 (capability) then zoz.1 (migration) with explicit dependency gave the fork agents clear boundaries
- **Canonical role catalog from the spec eliminated naming decisions** at implementation time — the fork agents could proceed without ambiguity
- **3-cycle review (valid/fit/shine) caught real bugs**: non-Hash config guard, docs config path mismatch, and missing gem defaults for role catalog — all fixed before merge
- **Full test suite remained green throughout**: 7,578 tests across 32 packages, zero regressions after migrating 13 packages
- **Commit reorganization reduced 43 commits to 17** clean scope-grouped commits without data loss

## What Could Be Improved

- **Fork timeout during migration release step**: codex executor hit 1800s limit on the large multi-package release. Required inline recovery to mark the step done
- **Fork timeout during E2E verification**: codex executor hit 1800s limit again on the E2E review step. Pattern: large-scope fork steps with multiple LLM calls exceed the default timeout
- **Fork timeout during valid review cycle**: the entire review workflow (run review + verify feedback + apply fixes) couldn't complete within one fork session
- **Per-package patch bumps vs minor**: fork agents chose patch for all migration packages; the release-minor step expected minor bumps for feature work. Config-only migrations fall in a gray area
- **Review findings across cycles were repetitive**: the same "consumers don't resolve role: before routing" finding appeared in all 3 cycles (valid, fit, shine) — 5 items total saying the same thing

## Key Learnings

### Review Cycle Analysis

- **Valid cycle**: 8 items — 2 fixed (non-Hash guard, docs config path), 1 invalid, 5 skipped. Most valuable cycle — caught actual bugs
- **Fit cycle**: 7 items — 1 fixed (ship role catalog in gem defaults), 2 invalid (already fixed), 4 skipped (duplicates). Found one important gap
- **Shine cycle**: 9 items — 0 fixed, all skipped. Pure polish, no actionable issues. Diminishing returns from the 3rd cycle
- **Cross-cycle pattern**: the E2E runner role routing issue appeared in all 3 cycles — indicates a systematic gap that warrants a follow-up task rather than in-PR resolution
- **False positive rate**: low overall; most findings were valid but out-of-scope design decisions rather than incorrect claims

### Process Insights

- Large multi-package migrations benefit from the fork agent per-package commit pattern, but the release step should be a top-level step (not inside the fork) to avoid timeout pressure
- The inline recovery pattern (completing fork work yourself after timeout) is effective but adds driver context window pressure

## Action Items

- **Increase fork timeout** for assignment steps that involve multi-package releases or full review cycles
- **Split release into top-level step** for batch assignments with >5 packages to avoid fork timeout
- **Create follow-up task** for role-aware provider routing in ace-test-runner-e2e and ace-review context sizing
- **Consider 2-cycle reviews** (valid + fit) instead of 3 for config-migration PRs — the shine cycle added no value here

