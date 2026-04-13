---
id: 8qlnrz
title: 8q4-t-uns-7-readme-refresh
type: standard
tags: [docs, readme, assignment]
created_at: "2026-03-22 15:51:06"
status: active
task_ref: 8q4.t.uns.7
---

# 8q4-t-uns-7-readme-refresh

## What Went Well
- The assignment subtree flow stayed deterministic: onboarding, task loading, planning, implementation, review, verification, release, and retro all completed without scope drift.
- Scoped commits kept unrelated working-tree changes isolated while still producing complete task history.
- The README refresh maintained technical depth while fixing outdated testing guidance and adding the required ACE footer.
- Release coordination worked cleanly: package version bump, package changelog entry, root changelog entry, and lockfile refresh were completed in one pass.

## What Could Be Improved
- Native pre-commit review had avoidable friction:
  - First invocation used unsupported `--commit` + prompt combination.
  - Default review model hit usage limits and required manual fallback to another model.
- Release workflow auto-detection depends on uncommitted diffs; after incremental commits, explicit package targeting was needed.
- The task spec instruction suggested archiving on done, while in-task workflow guidance only required status updates; this creates ambiguity for closure behavior in fork subtrees.

## Key Learnings
- For Codex native review, prefer a known-available model override early when quota pressure is likely.
- For assignment sub-steps that require release after implementation commits, pass explicit package targets instead of relying on diff auto-detection.
- Keep docs refreshes aligned with repository command policy (`ace-*` via `mise exec --`) to avoid regression to legacy `bundle exec` examples.

## Action Items
- `continue`: Keep using path-scoped `ace-git-commit` to avoid touching unrelated background changes.
- `start`: Add a small preflight check in pre-commit-review steps to validate native review invocation syntax before first attempt.
- `start`: Document a preferred fallback model sequence for native Codex reviews when default model quota is exhausted.
- `investigate`: Clarify whether task status transitions in `work-on-task` should always include `--move-to archive` in this assignment preset.
