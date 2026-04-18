# Goal 2 — List and Create Worktrees Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/02/ contains stdout/exit for list-before, create-existing, create-new, and list-after.
2. **List before shows main only** — list-before.stdout shows the main worktree and no others.
3. **Both creations succeed** — create-existing.exit and create-new.exit are both 0.
4. **List after is the post-create state capture for this goal** — list-after.stdout exists, is non-empty, and reflects the immediate state after both create commands.
5. **Created worktrees are evidenced in goal-local artifacts** — the create outputs or list-after output mention the created worktrees (`feature/test-worktree` and `bugfix/test-fix` or their sandbox paths). Do not fail based on end-of-scenario sandbox state after later goals intentionally remove/prune worktrees.

## Verdict

- **PASS**: List starts with main only, both creations succeed, and the goal-local
  post-create artifacts show both created worktrees.
- **FAIL**: Creation fails or the immediate post-create artifacts do not show the created worktrees.

Report: `PASS` or `FAIL` with evidence (exit codes, list output before/after, directory listing).
