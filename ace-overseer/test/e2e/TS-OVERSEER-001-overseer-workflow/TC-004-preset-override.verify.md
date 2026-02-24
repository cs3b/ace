# Goal 4 — Preset Override Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Artifacts exist** — results/tc/04/ contains stdout/exit and verification outputs.
2. **Zero exit code** — Command succeeded.
3. **Worktree created for task 002** — Worktree list shows entry for task 002.
4. **Custom preset used** — Assignment details reference the custom preset name.

## Verdict

- **PASS**: Task 002 worktree created with custom preset assignment.
- **FAIL**: Command failed, wrong preset used, or worktree missing.

Report: `PASS` or `FAIL` with evidence.
