---
id: 8qlnha
title: utility-tools-docs-overhaul-batch
type: standard
tags: [docs, batch]
created_at: "2026-03-22 15:39:12"
status: active
---

# Utility Tools Documentation Overhaul Batch

Batch of 4 documentation tasks for ace-demo, ace-prompt-prep, ace-sim, ace-b36ts.
Assignment: 8qllb7, PR #255, branch: unp-documentation-overhaul-utility-tools.

## What Went Well

- **Fork delegation worked smoothly** — all 4 task subtrees (010.01–010.04) completed via fork-run without driver intervention, producing 8 commits each (onboard through retro).
- **Review cycle pipeline** — 3 review cycles (valid, fit, shine) caught real issues: 7 valid findings in cycle 1 (duplicate changelog entries, handbook link paths, demo GIF asset reuse, dry-run docs mismatch), 1 in cycle 2 (prompt-prep CLI help reference), 1 in cycle 3 (create syntax ordering). All applied and released as patch bumps.
- **Commit reorganization** — 27 fork-generated commits cleanly reorganized into 8 logical scope-grouped commits via `ace-git-commit`. The tool's scope detection worked correctly for all 8 scopes.
- **Auto-archive propagation** — marking one subtask done caused the parent task to auto-archive since all siblings were terminal. Clean lifecycle management.

## What Could Be Improved

- **Provider exhaustion mid-run** — Codex Spark quota ran out during the first fork-run attempt for verify-e2e (step 015). Required manual config change to switch to `codex:codex@yolo` and restart. The assignment had to retry the step 3 times before it advanced.
- **Retry step proliferation** — the retry mechanism created steps 021, 022, 023 (all verify-e2e) when only one was needed. The first retry (021) resolved the issue, but the queue already had extra retries queued from the failed fork recovery flow.
- **E2E test false positive** — `find` initially reported 1 scenario per package, but the packages actually have no `test/e2e/` directories. The count came from unrelated glob matches. Wasted time investigating before confirming no E2E tests exist.
- **Fork reports lack detail on what was actually changed** — the subtree completion report (`010.0x-work-on-8q4-t-unp-x.r.md`) just says "Auto-completed: all child steps finished" without summarizing what the fork actually produced. The work-on-task report (010.0x.04) has the plan but not the outcome.

## Key Learnings

### Review Cycle Analysis

- **Valid cycle** (review-8qlm59): 11 findings total, 7 applied (medium+), 4 low-priority skipped. Caught real issues: duplicate changelog entries, handbook link paths pointing to wrong locations, ace-sim demo GIF being identical to ace-demo's, dry-run docs mismatch.
- **Fit cycle** (review-8qlmkc): 13 findings total, 1 fix applied (prompt-prep CLI help reference), rest resolved as invalid/skipped. Higher false-positive rate — many findings were about documentation conventions that were intentional design choices.
- **Shine cycle** (review-8qlmyp): 1 fix applied (create syntax ordering in ace-demo), rest skipped as polish suggestions below threshold.
- **Cross-cycle pattern**: Valid cycle catches substantive errors; fit cycle has diminishing returns for docs-only PRs; shine cycle finds minor polish. For documentation-focused work, valid + one polish pass may be sufficient.

## Action Items

- **Continue**: Fork delegation for batch tasks — parallelizable and context-isolated.
- **Continue**: 3-cycle review pipeline — even for docs, it catches real issues (especially valid cycle).
- **Start**: Add provider fallback configuration so quota exhaustion auto-switches providers instead of requiring manual intervention.
- **Start**: Include an outcome summary in fork completion reports, not just "all steps finished."
- **Stop**: Creating multiple retry steps for the same failed step — one retry should be sufficient before escalating.
