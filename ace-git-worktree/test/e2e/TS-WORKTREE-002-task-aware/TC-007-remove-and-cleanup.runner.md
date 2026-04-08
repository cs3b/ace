# Goal 7 — Remove and Cleanup

## Goal

Remove task `8pp.t.r8x` worktree by task ID. Then remove task `8pp.t.q7w` worktree with the `--delete-branch` flag. Capture clean-state evidence: main worktree intact, both task worktrees gone, branches deleted where specified.

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/remove-888.stdout`, `.stderr`, `.exit` — remove task `8pp.t.r8x` worktree by task ID
- `results/tc/07/remove-999.stdout`, `.stderr`, `.exit` — remove task `8pp.t.q7w` worktree with `--delete-branch`
- `results/tc/07/list-after.stdout`, `.stderr`, `.exit` — list worktrees after both removals
- `results/tc/07/branch-check.stdout` — git branch listing to verify branch deletion
- `results/tc/07/fs-check.txt` — filesystem check confirming worktree directories are gone

## Constraints

- Using what you learned from Goal 1, invoke `ace-git-worktree remove` with task-aware flags.
- This scenario expects dirty task worktrees to be removed, so use the current cleanup contract explicitly:
  - `8pp.t.r8x`: remove by task ID with `--force`
  - `8pp.t.q7w`: remove by task ID with `--force --delete-branch`
- After removal, verify clean state via list, git branch, and filesystem checks.
- `branch-check.stdout` must specifically show whether the `q7w` task branch still exists after `--delete-branch`.
- All artifacts must come from real tool execution, not fabricated.
