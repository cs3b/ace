# Goal 3 — Idempotent Re-Run Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Artifacts exist** — `results/tc/03/` contains stdout/exit and count evidence.
2. **Zero exit code** — re-run succeeded.
3. **No duplicate task state** — exactly 1 worktree for task `8pp.t.q7w` and exactly 1 task-specific tmux window for `q7w`.
4. **Baseline shell window allowed** — an additional non-task shell window in the same tmux session does not count as a duplicate.

## Verdict

- **PASS**: Re-run succeeded without creating duplicate task windows or duplicate worktrees.
- **FAIL**: Duplicate task windows/worktrees created or command failed.

Report: `PASS` or `FAIL` with evidence (counts, window names).
