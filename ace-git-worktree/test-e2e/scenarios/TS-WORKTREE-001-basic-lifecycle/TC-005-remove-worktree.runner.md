# Goal 5 — Remove Worktree

## Goal

Remove one of the clean worktrees created in Goal 2. Verify it is gone from both the worktree list and the filesystem.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/remove.stdout`, `.stderr`, `.exit` — remove command output
- `results/tc/05/list-after.stdout`, `.stderr`, `.exit` — list worktrees after removal
- `results/tc/05/fs-check.txt` — filesystem check confirming the worktree directory is deleted

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree remove on one of the worktrees from Goal 2.
- Prefer removing a clean worktree that was not modified by later goals. If the
  tool reports local changes, capture that real output and rerun with the
  documented force option so the final state is still verified.
- After removal, run list and check the filesystem to confirm the worktree is gone.
- All artifacts must come from real tool execution, not fabricated.
