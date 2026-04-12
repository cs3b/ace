---
id: 8qmaek
title: readme-refresh-ace-demo
type: standard
tags: []
created_at: "2026-03-23 06:56:12"
status: active
task_ref: 8qm.t.5nx.o
---

# readme-refresh-ace-demo

## What Went Well
- Executed the assignment subtree end-to-end without queue drift: onboarding, task load, planning, implementation, review handling, verification decision, release, and retro.
- Used sibling refreshed package READMEs as concrete style baselines, which reduced ambiguity from the minimal task spec.
- Kept implementation scoped to one package file (`ace-demo/README.md`) and validated with `ace-lint`.
- Completed release hygiene in the same pass (package version bump, package changelog, root changelog, lockfile refresh).

## What Could Be Improved
- Native `codex` pre-commit `/review` was not callable from this runtime; the step had to be skipped after an attempted command failure.
- `ace-task plan <ref>` had delayed/no output for a period; although it eventually returned, the workflow needed stall-guard handling.
- Task spec content for this leaf task was title-only, forcing behavior inference from neighboring artifacts rather than explicit acceptance criteria.

## Key Learnings
- For docs-only subtree tasks, release flow should explicitly document when `patch` is expected even under a `release-minor` step name.
- When step instructions require native client capabilities (like `/review`), assignment setup should ensure those commands are actually available in the execution harness.
- Minimal task specs increase planning overhead; adding brief success criteria in leaf task files would reduce interpretation variance.

## Action Items
- Add a reusable assignment note for native-review fallback behavior (attempt, capture raw error, skip with severity summary when unavailable).
- Add a short leaf-task authoring guideline: include at least one concrete acceptance criterion beyond title-only summaries.
- Consider adding a fast health check command in fork startup to verify native review command availability before pre-commit-review steps.
