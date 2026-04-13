# Goal 3 -- Idempotent Re-Run Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Artifacts exist** -- results/tc/03/ contains stdout/exit and count evidence.
2. **Zero exit code** -- Re-run succeeded.
3. **No duplicates** -- Exactly 1 worktree for task 8pp.t.q7w, and exactly 1 tmux window whose name contains `t.q7w` (ignore unrelated windows in the same session).

## Verdict

- **PASS**: Re-run succeeded without creating duplicates.
- **FAIL**: Duplicates created or command failed.

Report: `PASS` or `FAIL` with evidence (counts).
