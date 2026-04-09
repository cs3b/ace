# Goal 2 — List and Create Worktrees

## Goal

List worktrees in the fresh repo, then create a worktree from an existing branch (`feature/test-worktree`) and create another worktree with a new branch based on the repo's main line at a child path under `.ace-wt/`. Capture list output before and after creation, plus directory listings of the created worktrees.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/list-before.stdout`, `.stderr`, `.exit` — list output before creating any worktrees
- `results/tc/02/create-existing.stdout`, `.stderr`, `.exit` — create worktree from existing branch
- `results/tc/02/create-new.stdout`, `.stderr`, `.exit` — create worktree with new branch at a child path under `.ace-wt/`
- `results/tc/02/list-after.stdout`, `.stderr`, `.exit` — list output after both creations
- `results/tc/02/dir-listing.txt` — directory listing showing created worktree directories exist
- `results/tc/02/target-existing.txt` — unique branch/path label chosen for the existing-branch create
- `results/tc/02/target-new.txt` — unique branch/path label chosen for the new-branch create

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree list and create commands.
- Use `.ace-wt/` as the intended worktree parent path; the sandbox setup pre-creates it.
- Do not assume the sandbox starts with only `main`. Choose unique target names for this run and write them to `target-existing.txt` and `target-new.txt`.
- For the existing branch case, create a unique child path under `.ace-wt/` while still using the real existing branch `feature/test-worktree`.
- For the new-branch creation, create a unique branch name and a unique child path under `.ace-wt/`; do not reuse a prior run's path.
- The sandbox has branches `feature/test-worktree` and `bugfix/test-fix` available.
- All artifacts must come from real tool execution, not fabricated.
