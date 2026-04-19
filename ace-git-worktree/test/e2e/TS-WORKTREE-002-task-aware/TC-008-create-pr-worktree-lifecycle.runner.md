# Goal 8 — Create PR Worktree Lifecycle

## Goal

Create a PR worktree using public CLI commands when GitHub CLI access is available. If the sandbox lacks `gh` or `gh` is not authenticated, verify that the public command fails gracefully with actionable prerequisite evidence and leaves no PR worktree behind.

## Workspace

Save all output to `results/tc/08/`. Capture:
- `results/tc/08/gh-auth-status.stdout`, `.stderr`, `.exit` — GitHub CLI prerequisite status
- `results/tc/08/create-pr.stdout`, `.stderr`, `.exit` — create PR worktree output
- `results/tc/08/list-after-create.stdout`, `.stderr`, `.exit` — list after PR worktree creation
- `results/tc/08/switch-pr.stdout`, `.stderr`, `.exit` — switch output for the PR worktree, only when create succeeds
- `results/tc/08/remove-pr.stdout`, `.stderr`, `.exit` — remove PR worktree output, only when create succeeds
- `results/tc/08/list-after-remove.stdout`, `.stderr`, `.exit` — list after removal, only when create succeeds
- `results/tc/08/fs-check.txt` — filesystem check confirming either removed PR worktree path no longer exists after success, or no PR worktree was created after prerequisite failure

## Constraints

- Use explicit public commands:
  1. `gh auth status`
  2. `ace-git-worktree create --pr 26`
  3. `ace-git-worktree list`
  4. `ace-git-worktree switch <identifier-from-create-output>` only when create succeeds
  5. `ace-git-worktree remove <identifier-from-create-output>` only when create succeeds
  6. `ace-git-worktree list` after removal only when create succeeds
- Use the exact branch/worktree identifier emitted by the create command (for example `26`) for switch/remove; do not normalize to `pr-26` unless that exact identifier was printed.
- If `gh` is missing, unauthenticated, or PR `26` cannot be fetched in the sandbox, capture the create error, capture `ace-git-worktree list`, write `fs-check.txt`, and do not run switch/remove.
- A missing/unauthenticated/upstream-prerequisite branch is a valid outcome only when the error is explicit and no partial PR worktree remains.
- All artifacts must come from real tool execution, not fabricated.
