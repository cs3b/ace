---
id: 8qukqq
title: 8qu-t-jdt-1-framework-removal-cleanup
type: standard
tags: []
created_at: "2026-03-31 13:49:43"
status: active
---

# 8qu-t-jdt-1-framework-removal-cleanup

## What Went Well
- Forked `plan-task` and `work-on-task` substeps delivered complete reports with clear file-level scope and verification evidence.
- Task implementation cleanly removed legacy `ace-framework` ownership from `ace-support-core` and migrated docs to `ace-config` without regressions.
- Verification stayed package-scoped (`ace-support-core`) and passed quickly with profile output.
- Release flow remained scoped to task outputs by using path-scoped commits and explicit release targeting.

## What Could Be Improved
- Long-running fork sessions provided little live output, which made it harder to distinguish healthy execution from stalls.
- Pre-commit review fallback (`ace-lint`) surfaced known task-spec warnings (em-dash/formatting) that were non-blocking but added noise.
- Release-minor wording and dependency-following rules can imply wider cascade risk; clearer subtree release policy would reduce ambiguity.

## Key Learnings
- For assignment subtree driving, status polling plus report-file timestamp checks is a reliable way to confirm completion when fork-run output is silent.
- Scoped `ace-git-commit` usage is essential in dirty assignment worktrees to avoid accidental inclusion of task metadata updates.
- When branch diff is broad, explicit package selection in release steps prevents unintended cross-package version churn.

## Action Items
- Add a lightweight fork-run progress heartbeat in assignment tooling (or document a standard status polling cadence).
- Introduce a review-step noise filter guidance for known non-blocking markdown typography warnings in task spec files.
- Document release-step preference rules for scoped assignment subtrees (when to apply patch vs minor) to reduce operator hesitation.
