# Goal 5 — Remove Worktree

## Goal

Remove one of the worktrees created in Goal 2. Verify the removal command succeeds and final state is clean using git metadata plus filesystem evidence.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/remove.stdout`, `.stderr`, `.exit` — remove command output
- `results/tc/05/list-after.stdout`, `.stderr`, `.exit` — list worktrees after removal (diagnostic evidence)
- `results/tc/05/git-worktree-porcelain-after.stdout`, `.stderr`, `.exit` — `git worktree list --porcelain` after removal
- `results/tc/05/fs-check.txt` — filesystem check confirming the removed worktree directory is deleted, written as:
  - `path=<absolute-path>`
  - `exists=no`

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree remove feature/test-worktree`
  2. `ace-git-worktree list`
- Remove the `feature/test-worktree` worktree specifically so the verifier can validate one exact target.
- Use the exact worktree path reported by the remove command when writing `fs-check.txt`.
- After removal, run list for diagnostics, capture `git worktree list --porcelain`, and check the filesystem to confirm that exact worktree directory is gone.
- All artifacts must come from real tool execution, not fabricated.
