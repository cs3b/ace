# Goal 7 — Remove and Cleanup

## Goal

Remove task 8pp.t.r8x worktree by task ID. Then remove task 8pp.t.q7w worktree with the --delete-branch flag (which should also delete the associated branch). Verify clean state: main worktree intact, both task worktrees gone, branches deleted where specified. Also test the current-branch fallback behavior if applicable.

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/remove-888.stdout`, `.stderr`, `.exit` — remove task 8pp.t.r8x worktree by task ID
- `results/tc/07/remove-999.stdout`, `.stderr`, `.exit` — remove task 8pp.t.q7w worktree with --delete-branch
- `results/tc/07/list-after.stdout`, `.stderr`, `.exit` — list worktrees after both removals
- `results/tc/07/branch-check.stdout` — git branch listing to verify branch deletion
- `results/tc/07/fs-check.txt` — filesystem check confirming worktree directories are gone

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree remove with task-aware flags.
- For task 8pp.t.r8x: remove by task ID without deleting the branch.
- For task 8pp.t.q7w: remove by task ID with --delete-branch to also delete the associated branch.
- After removal, verify clean state via list, git branch, and filesystem checks.
- All artifacts must come from real tool execution, not fabricated.
