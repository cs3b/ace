# Goal 3 — List and Filter by Task Association

## Goal

List worktrees with task-related filters: `--show-tasks`, `--task-associated`, and `--no-task-associated`. Verify these flags produce useful user-facing separation between task-linked and non-task worktrees.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/show-tasks.stdout`, `.stderr`, `.exit` — list with --show-tasks
- `results/tc/03/task-associated.stdout`, `.stderr`, `.exit` — list with --task-associated filter
- `results/tc/03/no-task-associated.stdout`, `.stderr`, `.exit` — list with --no-task-associated filter

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree list --show-tasks`
  2. `ace-git-worktree list --task-associated`
  3. `ace-git-worktree list --no-task-associated`
- The task 8pp.t.q7w worktree from Goal 2 is the only task-associated worktree at this point.
- All artifacts must come from real tool execution, not fabricated.
