# Goal 4 — Dry-Run Operations

## Goal

Test create `--dry-run` (shows what would be created without actually creating) and remove `--dry-run` (shows what would be removed without actually removing). Verify that no actual changes occur in either case.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/create-dry.stdout`, `.stderr`, `.exit` — create `--dry-run` output
- `results/tc/04/create-dry-check.txt` — check that the planned directory does NOT exist after dry-run
- `results/tc/04/remove-dry.stdout`, `.stderr`, `.exit` — remove `--dry-run` on an existing worktree
- `results/tc/04/remove-dry-check.txt` — check that the worktree still EXISTS after dry-run remove
- `results/tc/04/list-after.stdout`, `.stderr`, `.exit` — list worktrees to confirm nothing changed

## Constraints

- Using what you learned from Goal 1, invoke create and remove with `--dry-run`.
- For create `--dry-run`: use the current valid create syntax with a branch not yet checked out as a worktree, for example `ace-git-worktree create --branch bugfix/test-fix --dry-run`.
- For remove `--dry-run`: target one of the worktrees created in Goal 2.
- After the remove dry-run, explicitly test the same target path with a filesystem check and write `remove-dry-check.txt`.
- `create-dry-check.txt` must prove the specific planned child worktree path is absent after dry-run, not just that the parent `.ace-wt` exists.
- `remove-dry-check.txt` must identify the specific targeted worktree path and prove it is still present after the dry-run remove.
- All artifacts must come from real tool execution, not fabricated.
