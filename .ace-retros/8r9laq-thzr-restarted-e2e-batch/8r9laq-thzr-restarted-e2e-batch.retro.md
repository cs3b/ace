---
id: 8r9laq
title: thzr-restarted-e2e-batch
type: standard
tags: [e2e, review, release]
created_at: "2026-04-10 14:11:56"
status: active
---

# thzr-restarted-e2e-batch

## What Went Well

- The restarted split landed cleanly at the product level: deterministic coverage moved into `ace-b36ts/test/e2e`, the real agent scenario lived under `test-e2e/scenarios`, and shared sandbox setup moved into `ace-support-test-helpers`.
- The valid and fit review cycles paid off. They caught one real routing regression in `ace-test-runner`, one packaging/runtime contract issue in `ace-test-runner-e2e`, and one coverage gap in `ace-b36ts` before the branch was finalized.
- The release loop was recoverable even after mistakes. Patch releases for the review-cycle fixes were added without losing the main branch intent, and the PR description/demo were updated to the final state after the history rewrite.
- The new demo workflow was useful once focused on the actual changed experience. A narrow tape showing the `test/e2e` and `test-e2e/scenarios` split plus `ace-test ace-b36ts e2e` was enough to make the PR easier to review.

## What Could Be Improved

- Scoped release commits remain too easy to contaminate with unrelated tracked files. The accidental inclusion of `ace-test-runner-e2e/.codex` shows that path-scoped release commands need a stronger preflight guard for ignored/editor artifacts.
- Reorganize-commits is unsafe in a dirty assignment workspace when metadata files are present. The first regroup captured `.ace-tasks` and `.ace-retros` scopes, which forced a second reset/rebuild pass.
- Review preset reliability is uneven. The fit cycle lost Gemini to model-capacity exhaustion, and the shine cycle used a misspelled role name (`review-geminie`), creating avoidable noise in the late review passes.
- The assignment workflow pushed before later metadata/demo commits existed, which meant extra manual pushes were needed after `record-demo` and `mark-tasks-done`.

## Key Learnings

- The useful part of the `fix/e2e` recovery was the runtime contract and hardening, not the exact folder structure. Keeping the user decision (`test/` as the home for deterministic and agent tests) while restoring the stricter runtime/reporting fixes was the right framing.
- Deterministic replacement tests need explicit CLI contract parity checks. Replacing goal-style runner cases with Minitest is not enough unless shell-level roundtrip and ordering guarantees are preserved intentionally.
- Review-cycle releases should stay patch-biased. The follow-up changes were all fixes or coverage recovery, and treating them as patch releases kept the release surface understandable.

### Review Cycle Analysis

- Review findings that led to code changes: 5 of 11 extracted items across the three review cycles.
- Review findings archived as invalid: 6 of 11, mostly because later cycles re-reported already-fixed issues or used the obsolete `test-e2e/...` assumption.
- Code-valid found the highest-value issues: explicit `all` target widening, dependency floor mismatch, and the smoke fixture path.
- Code-fit found a real runtime-diagnostics bug and one real coverage gap, but also repeated one already-fixed packaging issue.
- Code-shine did not add new code changes; all three findings were stale/invalid, and the cycle also exposed a preset/configuration issue (`review-geminie`).
- Provider quality differed by failure mode more than by review quality in this run: Codex produced actionable results throughout, while Gemini failed once for capacity (`429 MODEL_CAPACITY_EXHAUSTED`) and once because the preset referenced a nonexistent role.

## Action Items

- Stop: running branch-wide commit reorganization in a dirty workspace without first isolating assignment metadata from the regroup scope.
- Continue: using review cycles to drive patch releases for real follow-up fixes instead of folding those changes into the original release silently.
- Start: add a preflight guard to release/reorganize workflows that excludes `.codex`, `.ace-tasks`, and `.ace-retros` from auto-grouped commits unless explicitly requested.
- Start: fix the `code-shine` preset role typo and audit other review presets for broken role references before the next multi-cycle assignment.
- Start: consider a final post-closeout push hook in the assignment workflow so demo/task-archive/retro commits are not left local after the nominal push step.
