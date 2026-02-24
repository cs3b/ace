# Goal 5 — Prune Workflow

## Goal

Test the full prune lifecycle: (1) mark task 001 as done, (2) run prune --dry-run to identify safe candidates, (3) run prune --yes to remove the safe worktree, (4) verify the unsafe worktree (task 002) is preserved. Verify dry-run makes no changes and actual prune removes only safe targets.

## Workspace

Save all output to `results/tc/05/`. Capture:
- Task 001 status change to done
- `results/tc/05/dry-run.stdout`, `.stderr`, `.exit` — dry-run output
- `results/tc/05/prune.stdout`, `.stderr`, `.exit` — actual prune output
- Worktree list after prune showing task 001 removed, task 002 preserved
- Follow-up dry-run showing no more safe candidates

## Constraints

- Mark task 001 as done (so prune considers it safe).
- Task 002 should remain pending/active (so prune preserves it).
- All artifacts must come from real tool execution, not fabricated.
