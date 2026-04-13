# Goal 2 -- Work-On Happy Path Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Artifacts exist** -- results/tc/02/ contains stdout/exit and verification outputs.
2. **Zero exit code** -- work-on command succeeded.
3. **Worktree created** -- Worktree list shows an entry for task 8pp.t.q7w.
4. **Tmux window created** -- Tmux output shows a window was created or exists.
5. **Assignment active (overseer oracle)** -- `overseer-status.json` shows task 8pp.t.q7w with active assignment state.
6. **Table status output captured** -- `overseer-status-table.stdout` exists and is non-empty. The JSON oracle remains authoritative for assignment state because table mode can be stale in the same shell session.

## Verdict

- **PASS**: All three resources (worktree, tmux window, assignment) created successfully.
- **FAIL**: Any resource missing or command failed.

Report: `PASS` or `FAIL` with evidence.
