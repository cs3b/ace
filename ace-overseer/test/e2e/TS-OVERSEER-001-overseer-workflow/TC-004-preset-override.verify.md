# Goal 4 — Preset Override Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Artifacts exist** — results/tc/04/ contains stdout/exit and verification outputs.
2. **Zero exit code** — Command succeeded.
3. **Worktree created for task 8pp.t.r8x** — Worktree list shows entry for task 8pp.t.r8x.
4. **Custom preset used** — Assignment details reference the custom preset name.

## Verdict

- **PASS**: Task 8pp.t.r8x worktree created with custom preset assignment.
- **FAIL**: Command failed, wrong preset used, or worktree missing.

Report: `PASS` or `FAIL` with evidence.
