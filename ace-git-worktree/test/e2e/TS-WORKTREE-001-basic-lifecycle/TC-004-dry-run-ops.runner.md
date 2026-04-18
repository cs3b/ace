# Goal 4 — Dry-Run Operations

## Goal

Test create --dry-run (shows what would be created without actually creating) and remove --dry-run (shows what would be removed without actually removing). Verify that no actual changes occur in either case.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/create-dry.stdout`, `.stderr`, `.exit` — create --dry-run output
- `results/tc/04/create-dry-check.txt` — check that the planned directory does NOT exist after dry-run
- `results/tc/04/remove-dry.stdout`, `.stderr`, `.exit` — remove --dry-run on an existing worktree
- `results/tc/04/remove-dry-target.txt` — the branch or worktree identifier targeted by remove --dry-run
- `results/tc/04/remove-dry-check.txt` — check that the worktree still EXISTS after dry-run remove
- `results/tc/04/list-after.stdout`, `.exit` — list worktrees to confirm nothing changed

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree create --from main dryrun/preview-branch --dry-run`
  2. `ace-git-worktree remove feature/test-worktree --dry-run`
  3. `ace-git-worktree list`
- For create --dry-run: use a branch name not already associated with an existing worktree in this scenario.
- For remove --dry-run: target one of the worktrees created in Goal 2.
- Persist the exact dry-run remove target in `remove-dry-target.txt` so the verifier can compare it against the final list output.
- All artifacts must come from real tool execution, not fabricated.
