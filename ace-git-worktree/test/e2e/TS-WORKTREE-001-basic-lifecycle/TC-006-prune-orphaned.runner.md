# Goal 6 — Prune Orphaned Worktree

## Goal

Manually delete a worktree directory on the filesystem to create an orphaned worktree entry. Then test prune --dry-run (should identify the orphan without cleaning it) and prune (should clean up the orphan). Verify the orphan is detected and then removed.

## Workspace

Save all output to `results/tc/06/`. Capture:
- `results/tc/06/orphan-create.txt` — evidence of manually deleting the worktree directory
- `results/tc/06/prune-dry.stdout`, `.stderr`, `.exit` — prune --dry-run output (should identify orphan)
- `results/tc/06/prune.stdout`, `.stderr`, `.exit` — prune output (should clean up orphan)
- `results/tc/06/list-after.stdout`, `.stderr`, `.exit` — list worktrees after prune

## Constraints

- One worktree from Goal 2 should remain (the one not removed in Goal 5). Manually delete its directory with `rm -rf` to create an orphan.
- Using what you learned from Goal 1, invoke prune with --dry-run first, then without.
- All artifacts must come from real tool execution, not fabricated.
