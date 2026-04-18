# Goal 5 -- Prune Workflow

## Goal

Validate the normal prune safety lifecycle with minimal public commands: mark task `8pp.t.q7w` done via the public update command, preview candidates, run prune, and confirm prune does not remove active or incomplete worktrees while still preserving task `8pp.t.r8x`.

## Workspace

Save all output to `results/tc/05/`.

## Steps

1. Run `ace-task update 8pp.t.q7w --set status=done` and capture output (`task-done.*`).
2. Run `ace-overseer prune --dry-run` and capture output (`dry-run.*`).
3. Run `ace-overseer prune --yes` and capture output (`prune.*`).
4. Run `ace-git-worktree list` and capture output (`worktree-list-after-prune.*`).
5. Run a final `ace-overseer prune --dry-run` and capture output (`dry-run-final.*`).

## Constraints

- Use only normal prune flow (`--dry-run` then `--yes`).
- Do **not** use assignment prune mode/flags, `--force`, or positional prune targets.
- Do not create helper context-tracking files under `results/`.
- If normal prune returns 0 candidates or prunes 0 worktrees, capture that outcome and continue.
- All artifacts must come from real tool execution, not fabricated.
- Mention the resolved q7w worktree path in final runner observations, especially if prune correctly keeps it because the assignment is still active.
