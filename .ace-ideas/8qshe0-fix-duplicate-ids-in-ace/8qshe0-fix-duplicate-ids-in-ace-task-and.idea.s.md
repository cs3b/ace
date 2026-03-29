---
id: 8qshe0
status: pending
title: Fix Duplicate IDs in ace-task and ace-idea Doctor
tags: []
created_at: "2026-03-29 11:35:34"
---

# Fix Duplicate IDs in ace-task and ace-idea Doctor

## What I Hope to Accomplish
Ensure the integrity of task and idea repositories by automatically detecting and resolving ID collisions. This prevents data corruption, navigation errors, and ambiguity when referencing specific tasks or ideas within the ACE ecosystem.

## What "Complete" Looks Like
The `doctor` command in both `ace-task` and `ace-idea` includes a uniqueness validation step. When duplicates are detected, the tool automatically reassigns new, unique IDs to the conflicting items based on the next available valid sequence, ensuring every task and idea has a distinct identity.

## Success Criteria
- `ace-task doctor` detects and reports duplicate IDs in the task repository.
- `ace-idea doctor` detects and reports duplicate IDs in the idea repository.
- Duplicate items are automatically renamed/moved to use the next available unique ID.
- Content integrity of the tasks and ideas is maintained during the ID reassignment.
- The tool provides a clear log of which items were updated and their new IDs.
