---
id: 8qru35
title: t-hgk-package-review-workflow
type: standard
tags: [ace-review, assignment, release]
created_at: "2026-03-28 20:03:31"
status: active
---

# t-hgk-package-review-workflow

## What Went Well

- Assignment subtree execution stayed linear and traceable: each child step was completed and reported with explicit artifacts.
- The workflow rewrite was validated in-process with both protocol loading (`ace-bundle wfi://review/package`) and lint enforcement before step closure.
- Scoped commits kept implementation, release metadata, and retro artifacts isolated without touching unrelated workspace changes.

## What Could Be Improved

- `plan-task` output contract required manual assembly in this environment; a direct command-path for structured plan generation would reduce friction.
- Pre-commit fallback lint targeted the task spec status file and surfaced many style warnings unrelated to release blocking; review scope filtering could be tighter.
- Release commit workflow split into two commits due to scope-based commit config behavior; coordinated-release intent would be clearer with single-commit enforcement.

## Key Learnings

- Expanding a workflow file from placeholder to full protocol is best handled with a single-pass rewrite followed by lint-guided normalization.
- For release steps inside assignment subtrees, package detection must include `git diff origin/main...HEAD` or already-committed implementation changes are missed.
- Running `ace-lint` immediately after structural edits catches frontmatter schema expectations (`name`, `description`, `allowed-tools`) early and avoids late-cycle rework.

## Action Items

- Add a lightweight helper that emits `wfi://task/plan` artifacts directly to a report file for assignment integration.
- Improve pre-commit-review fallback to ignore assignment task metadata files by default unless explicitly requested.
- Document scope-based multi-commit behavior in release workflow notes so commit expectations are explicit during coordinated releases.
