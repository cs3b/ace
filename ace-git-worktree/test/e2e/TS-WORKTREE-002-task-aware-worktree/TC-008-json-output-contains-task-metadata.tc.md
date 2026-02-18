---
tc-id: TC-008
title: JSON Output Contains Task Metadata
---

## Objective

Verify JSON format includes task-related fields.

## Steps

1. Get JSON output with task info
   ```bash
   ace-git-worktree list --show-tasks --format json
   ```

2. Parse for task fields
   ```bash
   ace-git-worktree list --show-tasks --format json | python3 -c "
   import sys, json
   data = json.load(sys.stdin)
   for wt in data:
       if wt.get('task_id'):
           print(f\"Task: {wt['task_id']}, Branch: {wt['branch']}\")
   "
   ```

## Expected

- JSON contains task field for task-associated worktrees
- Task field contains task ID
- Non-task worktrees have null/missing task field
