# Goal 2 -- Work-On Happy Path Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Artifacts exist** -- results/tc/02/ contains preflight help output plus work-on/status captures.
2. **Help preflight captured** -- `ace-overseer --help` output exists and references at least two subcommands (work-on, status, prune).
3. **Zero exit code** -- work-on command succeeded.
4. **Worktree created** -- Worktree list shows an entry for task 8pp.t.q7w.
5. **Tmux window created** -- Tmux output shows a task-related window was created or reused.
6. **Assignment active (overseer oracle)** -- `overseer-status.json` shows task 8pp.t.q7w with active assignment state.
7. **Table status output captured** -- `overseer-status-table.stdout` exists and is non-empty.

## Verdict

- **PASS**: Help preflight and all three resources (worktree, tmux window, assignment) are evidenced.
- **FAIL**: Missing preflight artifacts, missing resources, or command failure.

Report: `PASS` or `FAIL` with evidence.
