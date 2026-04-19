# Goal 4 -- Preset Override Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Use runner observations to identify the exact created worktree path when needed.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Artifacts exist** -- results/tc/04/ contains `work-on.*` and supporting verification outputs.
2. **Capture ordering is coherent** -- worktree and status captures must not be older than `work-on.exit`; if they are older, classify as runner ordering error.
3. **Zero exit code** -- Command succeeded.
4. **Exact worktree path created** -- the sandbox now contains a worktree for task `8pp.t.r8x`, and runner observations or `work-on.stdout` identify the created path.
5. **Task association evidence** -- public `ace-git-worktree list` output must show task `r8x`; `ace-overseer status --format json` should show the r8x assignment when available.
6. **Custom preset used** -- Assignment details reference the custom preset name.

## Verdict

- **PASS**: Task 8pp.t.r8x worktree path exists and the custom preset assignment was used.
- **FAIL**: Command failed, wrong preset used, the created worktree is missing, or task evidence is absent.

Report: `PASS` or `FAIL` with evidence.
