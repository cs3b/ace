# Goal 2 — List and Create Worktrees

## Goal

List worktrees in the fresh repo, then create a worktree from an existing branch (`feature/test-worktree`) and create another worktree with a new branch (`--from main`). Capture list output before and after creation, plus directory listings of the created worktrees.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/list-before.stdout`, `.stderr`, `.exit` — list output before creating any worktrees
- `results/tc/02/create-existing.stdout`, `.stderr`, `.exit` — create worktree from existing branch
- `results/tc/02/create-new.stdout`, `.stderr`, `.exit` — create worktree with new branch
- `results/tc/02/list-after.stdout`, `.stderr`, `.exit` — list output after both creations
- `results/tc/02/dir-listing.txt` — directory listing showing created worktree directories exist

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree list and create commands.
- The sandbox has branches `feature/test-worktree` and `bugfix/test-fix` available.
- All artifacts must come from real tool execution, not fabricated.
