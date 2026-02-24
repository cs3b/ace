# Goal 2 — Work-On Happy Path Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Artifacts exist** — results/tc/02/ contains stdout/exit and verification outputs.
2. **Zero exit code** — work-on command succeeded.
3. **Worktree created** — Worktree list shows an entry for task 001.
4. **Tmux window created** — Tmux output shows a window was created or exists.
5. **Assignment active (overseer oracle)** — `overseer-status.json` shows task 001 with active assignment state.

## Verdict

- **PASS**: All three resources (worktree, tmux window, assignment) created successfully.
- **FAIL**: Any resource missing or command failed.

Report: `PASS` or `FAIL` with evidence.
