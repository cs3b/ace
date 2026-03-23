---
id: 8qmfmt
status: pending
title: Dynamic Task Subtree Insertion for ace-assign
tags: []
created_at: "2026-03-23 10:25:21"
---

# Dynamic Task Subtree Insertion for ace-assign

## What I Hope to Accomplish
Enable flexible assignment modification by allowing users to inject new task subtrees into active assignments. This improves adaptability when new requirements emerge or when a large task needs to be subdivided after the assignment has already started, avoiding the need to manually edit complex YAML files or recreate assignments from scratch.

## What "Complete" Looks Like
The `ace-assign` CLI provides a mechanism to append or insert a task subtree into an existing assignment. By default, the tool intelligently identifies the first 'free' or pending task and inserts the new subtree before it, ensuring the workflow remains logical while allowing for manual position overrides when specific ordering is required.

## Success Criteria
- Subtrees can be added to an active `job.yaml` via a dedicated CLI command.
- Default insertion logic correctly targets the position before the first non-started task.
- Supports an optional position parameter (index or anchor task) for manual placement.
- The modified assignment file remains schema-valid and preserves the state of existing tasks.
- Insertion logic handles nested task structures without corrupting the assignment hierarchy.
