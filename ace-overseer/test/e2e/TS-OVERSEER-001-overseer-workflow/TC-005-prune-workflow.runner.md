# Goal 5 — Prune Workflow

## Goal

Test the full prune lifecycle with the real prune safety contract:
(1) mark task 001 as done,
(2) complete task 001 assignment state,
(3) run prune --dry-run to identify safe candidates,
(4) run prune --yes to remove only the safe worktree,
(5) verify unsafe task 002 is preserved.

Verify dry-run is non-destructive and actual prune removes only safe targets.

## Workspace

Save all output to `results/tc/05/`. Capture:
- Task 001 status change to done
- Assignment completion evidence for task 001:
  - `results/tc/05/task-001-assign-status-before.stdout`, `.stderr`, `.exit`
  - `results/tc/05/task-001-phase-report.md` (report file passed to `ace-assign report`)
  - `results/tc/05/task-001-assign-report.stdout`, `.stderr`, `.exit`
  - `results/tc/05/task-001-assign-status-after.stdout`, `.stderr`, `.exit`
- `results/tc/05/dry-run.stdout`, `.stderr`, `.exit` — dry-run output
- `results/tc/05/prune.stdout`, `.stderr`, `.exit` — actual prune output
- Worktree list after prune:
  - `results/tc/05/worktree-list-after-prune.stdout`, `.stderr`, `.exit`
- Follow-up dry-run showing no more safe candidates
  - `results/tc/05/dry-run-final.stdout`, `.stderr`, `.exit`

## Constraints

- Mark task 001 as done.
- Complete task 001 assignment before prune checks:
  - Run `ace-assign status --format json` in task 001 worktree (before)
  - Run `ace-assign report <report-file>` in task 001 worktree
  - Re-check `ace-assign status --format json` (after), expecting assignment state `completed`
- Task 002 should remain pending/active (so prune preserves it).
- Use normal prune flow (`ace-overseer prune --dry-run` then `ace-overseer prune --yes`), not `--force`.
- All artifacts must come from real tool execution, not fabricated.
