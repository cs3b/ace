---
id: 8qklfi
title: self-improve-mark-parent-task-done
type: standard
tags: [self-improvement, ace-assign, workflow]
created_at: "2026-03-21 14:17:14"
status: active
---

# Self-Improvement: Add mark-parent-task-done step to work-on-tasks preset

## What Went Well

- Root cause was clear: `work-on-tasks.yml` child-template marks subtasks done but no top-level step marks the parent task
- Fix was minimal and surgical: one new step at number 155, consistent with existing patterns in `work-on-task.yml`, `fix-bug.yml`, and `quick-implement.yml`
- All 478 ace-assign tests passed with zero regressions
- YAML validation confirmed clean parse

## What Could Be Improved

- The gap should have been caught during the original `work-on-tasks.yml` design — the single-task preset (`work-on-task.yml`) already had `mark-task-done`, so the batch preset should have had the equivalent from the start
- The parent task `t.h5e` sat in `in-progress` status after all 27 subtasks completed, requiring manual intervention to fix

## Key Learnings

- When creating batch/multi-task presets from single-task presets, audit each step for its batch equivalent — lifecycle steps like marking done are easy to overlook
- The expansion `child-template` handles per-item work but top-level lifecycle (parent status, umbrella cleanup) must be explicit in the preset's own steps

## Action Items

### Continue Doing

- Mirroring step patterns across related presets (single vs batch variants)
- Running full test suite after preset modifications

### Start Doing

- When adding new presets, cross-reference existing presets for lifecycle steps that need batch equivalents
