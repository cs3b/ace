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
- `results/tc/05/task-001-worktree-path.txt` — resolved absolute path to task 001 worktree
- `results/tc/05/sandbox-root-path.txt` — absolute sandbox root path used for overseer prune commands
- Assignment completion evidence for task 001:
  - `results/tc/05/task-001-assign-status-before.stdout`, `.stderr`, `.exit`
  - `results/tc/05/task-001-phase-report.md` (report file passed to `ace-assign report`)
  - `results/tc/05/task-001-assign-report.stdout`, `.stderr`, `.exit`
  - `results/tc/05/task-001-assign-status-after.stdout`, `.stderr`, `.exit`
- Prune invocation guardrails:
  - `results/tc/05/pwd-before-dry-run.txt` — `pwd` immediately before dry-run
  - `results/tc/05/pwd-before-prune.txt` — `pwd` immediately before prune --yes
  - `results/tc/05/dry-run-command.txt` — exact prune dry-run command string
  - `results/tc/05/prune-command.txt` — exact prune command string
- `results/tc/05/dry-run.stdout`, `.stderr`, `.exit` — dry-run output
- `results/tc/05/prune.stdout`, `.stderr`, `.exit` — actual prune output
- Worktree list after prune:
  - `results/tc/05/worktree-list-after-prune.stdout`, `.stderr`, `.exit`
- Follow-up dry-run showing no more safe candidates
  - `results/tc/05/dry-run-final.stdout`, `.stderr`, `.exit`

## Constraints

- Mark task 001 as done.
- At goal start, set `SANDBOX_ROOT="$(pwd)"` and save it to `results/tc/05/sandbox-root-path.txt`.
- Resolve task 001 worktree path first (for example from `ace-git-worktree list`); save it to `results/tc/05/task-001-worktree-path.txt`.
- Complete task 001 assignment before prune checks:
  - Run `ace-assign status --format json` in task 001 worktree (before), for example via `(cd "$TASK001_WORKTREE" && ...)`.
  - Run `ace-assign report <report-file>` in task 001 worktree.
  - Re-check `ace-assign status --format json` (after), expecting assignment state `completed`.
  - Keep report and all captures under sandbox root `results/tc/05/` even while executing commands from inside the worktree.
- Task 002 should remain pending/active (so prune preserves it).
- Use normal worktree prune flow from `SANDBOX_ROOT` only:
  - `ace-overseer prune --dry-run`
  - `ace-overseer prune --yes`
- Do **not** use assignment prune mode/flags (for example `--assignment`).
- Do **not** use `--force`.
- Do **not** pass positional prune targets (for example `ace-overseer prune 001 ...`).
- If normal prune returns 0 candidates or prunes 0 worktrees, capture that outcome and continue; do not run alternate prune modes.
- All artifacts must come from real tool execution, not fabricated.
