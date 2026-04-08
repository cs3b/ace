# Goal 2 — Create Task Worktree

## Goal

Create a worktree for task 8pp.t.q7w using the task-aware creation mechanism. Capture creation output, verify the branch name is task-derived, and confirm the worktree appears when listing task-associated worktrees.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/create-task.stdout`, `.stderr`, `.exit` — create worktree for task 8pp.t.q7w
- `results/tc/02/branch-check.stdout` — git branch or worktree info showing the branch name is derived from the task
- `results/tc/02/list-task.stdout`, `.stderr`, `.exit` — list showing the task-associated worktree

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree create with task-aware flags for task 8pp.t.q7w.
- The sandbox has taskflow fixtures with task 8pp.t.q7w (8pp.t.q7w-test-feature) already defined.
- All artifacts must come from real tool execution, not fabricated.
