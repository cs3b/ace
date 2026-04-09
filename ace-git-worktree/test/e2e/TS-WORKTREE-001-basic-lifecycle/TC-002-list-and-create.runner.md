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

## Constraints

- Using what you learned from Goal 1, invoke ace-git-worktree list and create commands.
- Use `.ace-wt/` as the intended worktree parent path; the sandbox setup pre-creates it.
- For the existing branch case, use the current positional branch create form and an explicit child path, for example `ace-git-worktree create feature/test-worktree --path .ace-wt/feature-test-worktree`.
- For the new-branch creation, target a child path under that parent such as `.ace-wt/feature-test-create`, not the parent directory itself.
- For the new branch case, use the current positional branch-name create form, for example `ace-git-worktree create feature-test-create --path .ace-wt/feature-test-create`.
- The sandbox has branches `feature/test-worktree` and `bugfix/test-fix` available.
- All artifacts must come from real tool execution, not fabricated.
