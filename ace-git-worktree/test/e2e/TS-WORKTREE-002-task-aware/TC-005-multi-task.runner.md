# Goal 5 — Multi-Task Worktrees

## Goal

Create a second task worktree for task 8pp.t.r8x. Verify both task worktrees (8pp.t.q7w and 8pp.t.r8x) coexist in the listing. Test that search or filter by pattern can identify specific task worktrees.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/create-888.stdout`, `.stderr`, `.exit` — create worktree for task 8pp.t.r8x
- `results/tc/05/pwd-after-create.txt` — working directory after second task worktree creation
- `results/tc/05/list-all-tasks.stdout`, `.stderr`, `.exit` — `ace-git-worktree list --task-associated`
- `results/tc/05/list-full.stdout`, `.stderr`, `.exit` — `ace-git-worktree list --show-tasks`

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree create with task-aware flags for task 8pp.t.r8x.
- The sandbox has taskflow fixtures with task 8pp.t.r8x (8pp.t.r8x-second-task) already defined.
- Prevent create-time navigation drift before listing:
  - either create with `--no-auto-navigate`, or
  - explicitly return to the repo root before writing `list-all-tasks.*` and `list-full.*`.
- Always write `pwd-after-create.txt` before the list commands so cwd/state drift is explicit in the evidence.
- After creation, use the explicit current list filters above to confirm both task worktrees coexist.
- Even if the create step fails, you must still write the exact capture files `create-888.stdout`, `create-888.stderr`, and `create-888.exit`; do not omit them.
- All artifacts must come from real tool execution, not fabricated.
