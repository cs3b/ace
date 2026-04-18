# Goal 8 — Create PR Worktree Lifecycle

## Goal

Create a PR worktree using public CLI commands, confirm it appears in the active list, resolve it via switch, then remove it and confirm final cleanup state.

## Workspace

Save all output to `results/tc/08/`. Capture:
- `results/tc/08/create-pr.stdout`, `.stderr`, `.exit` — create PR worktree output
- `results/tc/08/list-after-create.stdout`, `.stderr`, `.exit` — list after PR worktree creation
- `results/tc/08/switch-pr.stdout`, `.stderr`, `.exit` — switch output for the PR worktree
- `results/tc/08/remove-pr.stdout`, `.stderr`, `.exit` — remove PR worktree output
- `results/tc/08/list-after-remove.stdout`, `.stderr`, `.exit` — list after removal
- `results/tc/08/fs-check.txt` — filesystem check confirming removed PR worktree path no longer exists

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree create --pr 26`
  2. `ace-git-worktree list`
  3. `ace-git-worktree switch <identifier-from-create-output>`
  4. `ace-git-worktree remove <identifier-from-create-output>`
  5. `ace-git-worktree list`
- Use the exact branch/worktree identifier emitted by the create command (for example `26`) for switch/remove; do not normalize to `pr-26` unless that exact identifier was printed.
- If PR `26` cannot be fetched in the sandbox, fail this goal with concrete command/error captures rather than fabricating artifacts.
- All artifacts must come from real tool execution, not fabricated.
