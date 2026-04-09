# Goal 3 — List and Filter by Task Association

## Goal

List worktrees with task-related filters: --show-tasks (display task info alongside worktrees), --task-associated (show only task-linked worktrees), and --no-task-associated (show only non-task worktrees). Capture each filter's output and verify the filtering works correctly.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/show-tasks.stdout`, `.stderr`, `.exit` — list with --show-tasks
- `results/tc/03/task-associated.stdout`, `.stderr`, `.exit` — list with --task-associated filter
- `results/tc/03/no-task-associated.stdout`, `.stderr`, `.exit` — list with --no-task-associated filter

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree list with the task filter flags.
- The task 8pp.t.q7w worktree from Goal 2 is the only task-associated worktree at this point.
- All artifacts must come from real tool execution, not fabricated.
