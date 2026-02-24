# Goal 3 — Idempotent Re-Run Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Artifacts exist** — results/tc/03/ contains stdout/exit and count evidence.
2. **Zero exit code** — Re-run succeeded.
3. **No duplicates** — Exactly 1 worktree for task 001, exactly 1 tmux window.

## Verdict

- **PASS**: Re-run succeeded without creating duplicates.
- **FAIL**: Duplicates created or command failed.

Report: `PASS` or `FAIL` with evidence (counts).
