# Goal 2 — List and Create Worktrees

## Goal

List worktrees in the fresh repo, then create a worktree from an existing branch (`feature/test-worktree`) and create another worktree with a new branch (`--from main`). Capture list output before and after creation and let the verifier confirm the created directories from sandbox state.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/list-before.stdout`, `.stderr`, `.exit` — list output before creating any worktrees
- `results/tc/02/create-existing.stdout`, `.stderr`, `.exit` — create worktree from existing branch
- `results/tc/02/create-new.stdout`, `.stderr`, `.exit` — create worktree with new branch
- `results/tc/02/list-after.stdout`, `.stderr`, `.exit` — list output after both creations

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree list`
  2. `ace-git-worktree create feature/test-worktree`
  3. `ace-git-worktree create --from main bugfix/test-fix`
  4. `ace-git-worktree list`
- The sandbox has branches `feature/test-worktree` and `bugfix/test-fix` available.
- All artifacts must come from real tool execution, not fabricated.
- Perform the captures in this exact order:
  1. Run the initial list command and write the full `list-before` capture set before creating anything.
  2. Create the existing-branch worktree and save its capture set.
  3. Create the new-branch worktree and save its capture set.
  4. Run the final list command and save the `list-after` capture set.
  5. Stop after the final `list-after` capture; do not create helper directory-report artifacts.
- Do not skip `list-before`; the verifier expects the fresh-repo baseline evidence explicitly.
