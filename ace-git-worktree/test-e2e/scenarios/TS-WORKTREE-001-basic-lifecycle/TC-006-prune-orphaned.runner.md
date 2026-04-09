# Goal 6 — Prune Orphaned Worktree

## Goal

Manually delete a worktree directory on the filesystem to create an orphaned worktree entry. Then run prune and verify the final system state is clean (no orphaned worktree entry in git metadata and no orphaned directory on disk).

## Workspace

Save all output to `results/tc/06/`. Capture:
- `results/tc/06/orphan-target-path.txt` — absolute path of the worktree directory selected as orphan target
- `results/tc/06/orphan-create.stdout`, `.stderr`, `.exit` — raw command evidence for orphan creation attempt (including directory deletion)
- `results/tc/06/prune-dry.stdout`, `.stderr`, `.exit` — prune --dry-run output (diagnostic only)
- `results/tc/06/prune.stdout`, `.stderr`, `.exit` — prune output
- `results/tc/06/list-after.stdout`, `.stderr`, `.exit` — `ace-git-worktree list` after prune
- `results/tc/06/git-worktree-porcelain-after.stdout`, `.stderr`, `.exit` — `git worktree list --porcelain` after prune
- `results/tc/06/fs-state-after.txt` — filesystem check confirming orphan target path does not exist after prune

## Constraints

- One worktree from Goal 2 remains (the one not removed in Goal 5). Manually delete its directory with `rm -rf` to create an orphan.
- Use command captures (stdout/stderr/exit) for the orphan-create step; do not use narrative-only evidence files.
- Invoke prune with `--dry-run` first, then without.
- Final-state verification is primary: after prune, prove there is no orphaned worktree in git metadata and no orphan directory on disk.
- All artifacts must come from real tool execution, not fabricated.
