# Goal 5 — Multi-Task Worktrees

## Goal

Create a second task worktree for task 8pp.t.r8x. Verify both task worktrees (8pp.t.q7w and 8pp.t.r8x) coexist in the listing. Test that search or filter by pattern can identify specific task worktrees.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/create-888.stdout`, `.stderr`, `.exit` — create worktree for task 8pp.t.r8x
- `results/tc/05/list-all-tasks.stdout`, `.stderr`, `.exit` — `ace-git-worktree list --task-associated`
- `results/tc/05/list-full.stdout`, `.stderr`, `.exit` — `ace-git-worktree list --show-tasks`

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree create with task-aware flags for task 8pp.t.r8x.
- The sandbox has taskflow fixtures with task 8pp.t.r8x (8pp.t.r8x-second-task) already defined.
- After creation, use the explicit current list filters above to confirm both task worktrees coexist.
- All artifacts must come from real tool execution, not fabricated.
