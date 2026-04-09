# Goal 5 — Multi-Task Worktrees Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Creation artifacts exist** — results/tc/05/ contains stdout/exit for create-888.
2. **Creation succeeds** — create-888.exit is 0.
3. **Both tasks listed** — `list-all-tasks.stdout` contains both task-associated worktrees (`q7w` and `r8x`).
4. **Full list complete** — `list-full.stdout` shows at least 3 worktrees (main + task `q7w` + task `r8x`) with task metadata visible.

## Verdict

- **PASS**: Second task worktree created, both tasks coexist in listing, full list shows all worktrees.
- **FAIL**: Creation fails, one task missing from listing, or worktree count incorrect.

Report: `PASS` or `FAIL` with evidence (exit code, list output showing both tasks).
