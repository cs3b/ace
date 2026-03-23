---
id: 8qmg19
title: selfimprove-drive-fork-hardening
type: self-improvement
tags: [process-fix]
created_at: "2026-03-23 10:41:24"
status: active
---

# Selfimprove: Drive Fork Hardening

Sourced from: batch retro 8qmcae, 26 per-package retros, 4 review sessions, and assignment 8qm5rt reports.

## Root Causes Addressed

| Issue | Root Cause | Category |
|-------|-----------|----------|
| Dirty tree blocks fork | No pre-fork clean-tree check in drive.wf.md | Missing validation |
| Release no-ops in forks | Detection only checks working-tree state, not recent commits | Assumed context |
| Pre-commit review always skips | Instructions say "run `/review`" — agents execute it as bash | Ambiguous instructions |
| Uncommitted task files | Generated child step instructions lack clean-tree reminder | Missing validation |
| E2E timeout on docs | No docs-only skip criteria in generated instructions | Scope narrowing |

## Fixes Applied

1. **drive.wf.md**: Added "Pre-Fork Clean Tree Guard" section before fork-run delegation
2. **publish.wf.md**: Added `git diff origin/main...HEAD --name-only` to release package detection
3. **assignment_executor.rb**: Updated `child_action_instructions` for `work-on-task` (clean tree), `release` (commit scanning), `verify-e2e` (docs-only skip); updated `pre_commit_review_action_instructions` to clarify `/review` is an agent slash command and add `ace-lint` fallback
4. **pre-commit-review.step.yml**: Updated description and step names for clarity
5. **verify-e2e.step.yml**: Added docs-only skip criterion

## Expected Impact

- Fork agents won't stall on unrelated dirty files (prevented shine review skip)
- Release steps detect already-committed changes (~5 no-op releases eliminated)
- Pre-commit review actually runs in fork context or falls back to lint (23 subtrees had zero quality gate)
- Fork agents commit all files including task specs before completing
- Docs-only batches skip E2E cleanly instead of timing out

