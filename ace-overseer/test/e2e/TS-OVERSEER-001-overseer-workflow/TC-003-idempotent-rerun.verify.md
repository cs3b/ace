# Goal 3 -- Idempotent Re-Run Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):

- Confirm sandbox/project state impact first.
- Confirm explicit artifacts under `results/tc/{NN}/`.
- Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

Checks:
1. **Artifacts exist** -- results/tc/03/ contains rerun command output, worktree evidence, and overseer status JSON.
2. **Zero exit code** -- Re-run command succeeded.
3. **Single task worktree remains** -- Worktree evidence shows exactly one entry for task 8pp.t.q7w.
4. **Single task status record remains** -- `ace-overseer status --format json` shows one active/reused record for 8pp.t.q7w (no duplicate orchestration entries).

## Verdict

- **PASS**: Re-run succeeded and public state indicates resource reuse without duplicates.
- **FAIL**: Command failed or duplicate task resources are visible in public-state artifacts.

Report: `PASS` or `FAIL` with evidence.
