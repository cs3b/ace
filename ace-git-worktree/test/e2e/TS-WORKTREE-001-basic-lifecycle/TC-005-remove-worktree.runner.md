# Goal 5 — Remove Worktree

## Goal

Remove one of the worktrees created in Goal 2. Verify the removal command succeeds and the worktree directory is deleted on disk.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/remove.stdout`, `.stderr`, `.exit` — remove command output
- `results/tc/05/list-after.stdout`, `.stderr`, `.exit` — list worktrees after removal (diagnostic evidence)
- `results/tc/05/fs-check.txt` — filesystem check confirming the worktree directory is deleted

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree remove on one of the worktrees from Goal 2.
- After removal, run list for diagnostics and check the filesystem to confirm the worktree directory is gone.
- All artifacts must come from real tool execution, not fabricated.
