---
id: 8qm0nn
title: selfimprove-fork-commit-and-sibling-context
type: self-improvement
tags: [process-fix, ace-assign, workflow]
created_at: "2026-03-23 00:26:17"
status: active
---

# Self-Improve: Fork Commit Gaps, Archive Commits, and Sibling Context

## Root Cause Analysis

Three recurring process gaps identified from 77 retros and the 8qlwdo batch assignment:

1. **Fork-run agents leave uncommitted changes**: drive.wf.md subtree guard reviewed reports but never checked `git status`. 81 files left uncommitted in assignment 8qlwdo.
2. **Task archive moves not committed**: `ace-task update --move-to archive` relocates files but mark-task-done step didn't commit the moves.
3. **Sequential batch tasks lack sibling context**: Engine tasks never saw spike task specs/reports, creating parallel implementations instead of refactoring.

## Process Changes Applied

### Fix 1: Fork subtree guard + clean tree requirement
- `drive.wf.md`: Added step 2 (check `git status --short`, commit orphaned changes) to subtree guard
- `task/work.wf.md`: Added clean-tree verification to Done section

### Fix 2: Commit after task archive
- `mark-task-done.step.yml`: Added step 4 to commit `.ace-tasks/` after archive
- `work-on-task.yml` preset: Added commit instruction after archive loop
- `fix-bug.yml` preset: Added commit instruction after archive
- E2E fixture synced

### Fix 3: Prior sibling context loading
- `work-on-task.yml` child-template: Instructions to load dependency task specs and sibling reports before planning
- `task-load.step.yml`: Added instructions to load dependency task specs
- `task/work.wf.md`: Added "Prior implementation awareness" principle

## Expected Impact

- Fork subtrees can no longer silently leave uncommitted work
- Task archive moves always committed (no dirty repo after mark-tasks-done)
- Sequential batch tasks (spike→engine) will load prior sibling context, preventing code duplication

## Source Retros

- 8qlzgt (batch-yaml-demo-migration) — primary incident
- 8qlwu2, 8qlx73, 8qlxo2, 8qlxwc — per-task retros from the batch
- 8qklfi, 8qlk2n — parent/child task lifecycle gaps
- 8qeij5 — git status untracked files

